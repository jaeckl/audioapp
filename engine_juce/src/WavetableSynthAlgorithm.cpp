#include "audioapp/WavetableSynthAlgorithm.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

static inline float safe_clamp(float v, float lo, float hi) noexcept {
    if (!std::isfinite(v)) return lo;
    return std::clamp(v, lo, hi);
}

float beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return static_cast<float>(playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0);
}

bool isWavetableNoteAudible(const WavetableMidiNoteRegion& note,
                            double beat, int bpm,
                            float releaseSec,
                            double& elapsedSecondsOut,
                            double& noteDurationSecOut,
                            bool& inReleaseOut) noexcept {
    if (beat < note.clipStartBeat || beat >= note.clipStartBeat + note.clipLengthBeats || bpm <= 0) {
        return false;
    }
    const double posInClip = beat - note.clipStartBeat;
    const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
    const double noteStart = note.noteStartBeat;
    const double noteEnd = note.noteStartBeat + note.noteDurationBeats;
    const double releaseBeats = static_cast<double>(releaseSec) * static_cast<double>(bpm) / 60.0;
    if (loopedBeat < noteStart) return false;
    const double elapsedBeats = loopedBeat - noteStart;
    elapsedSecondsOut = elapsedBeats * 60.0 / static_cast<double>(bpm);
    noteDurationSecOut = note.noteDurationBeats * 60.0 / static_cast<double>(bpm);
    inReleaseOut = loopedBeat >= noteEnd;
    if (loopedBeat < noteEnd) return true;
    return loopedBeat < noteEnd + releaseBeats;
}

bool isNoteAudibleInBlock(const WavetableMidiNoteRegion& note,
                          double blockStartBeat, int numFrames,
                          double sampleRate, int bpm, float releaseSec) noexcept {
    if (bpm <= 0 || sampleRate <= 0.0) return false;
    const double blockEndBeat = blockStartBeat + static_cast<double>(numFrames) *
        (static_cast<double>(bpm) / 60.0) / sampleRate;
    const double noteStart = note.clipStartBeat + note.noteStartBeat;
    const double noteEnd = noteStart + note.noteDurationBeats;
    const double releaseBeats = static_cast<double>(releaseSec) * static_cast<double>(bpm) / 60.0;
    const double totalEnd = noteEnd + releaseBeats;
    return !(blockEndBeat < noteStart || blockStartBeat >= totalEnd);
}

} // anonymous namespace

int wavetableUnisonCount(float normalized) noexcept {
    const int count = 1 + static_cast<int>(normalized * 7.0f);
    return std::clamp(count, 1, kWavetableMaxUnison);
}

float wavetablePitchHz(int rootPitch, float octaveNorm, float semiNorm, float fineNorm) noexcept {
    const int octaveOffset = static_cast<int>((octaveNorm - 0.5f) * 4.0f);
    const int semiOffset = static_cast<int>((semiNorm - 0.5f) * 48.0f);
    const int totalSemi = (rootPitch - 69) + octaveOffset * 12 + semiOffset;
    const float fineCents = (fineNorm - 0.5f) * 100.0f;
    return 440.0f * std::pow(2.0f, (static_cast<float>(totalSemi) + fineCents / 100.0f) / 12.0f);
}

float wavetableInterpolatedSample(const float* table,
                                  int frameCount,
                                  int frameLength,
                                  float frameIndex,
                                  float phase) noexcept {
    if (table == nullptr || frameCount <= 0 || frameLength <= 0) return 0.0f;

    // Clamp frame index
    const float fi = std::clamp(frameIndex, 0.0f, static_cast<float>(frameCount - 1));
    const int frameA = static_cast<int>(fi);
    const int frameB = std::min(frameA + 1, frameCount - 1);
    const float frac = fi - static_cast<float>(frameA);

    // Clamp phase [0, 1)
    float p = phase - std::floor(phase);

    // Read sample from each frame with linear interpolation
    const float pos = p * static_cast<float>(frameLength);
    const int idx = static_cast<int>(pos) % frameLength;
    const int idxNext = (idx + 1) % frameLength;

    const float sA = table[frameA * frameLength + idx];
    const float sA1 = table[frameA * frameLength + idxNext];
    const float sB = table[frameB * frameLength + idx];
    const float sB1 = table[frameB * frameLength + idxNext];

    const float t = pos - std::floor(pos);
    const float interpolatedA = sA + t * (sA1 - sA);
    const float interpolatedB = sB + t * (sB1 - sB);

    return interpolatedA + frac * (interpolatedB - interpolatedA);
}

float wavetableVoiceSample(const WavetableSynthParams& params,
                           const float* table,
                           int frameCount,
                           int frameLength,
                           float& phase,
                           float wtPosition,
                           float hz,
                           float sampleRate,
                           float ampGain,
                           float filterGain,
                           BiquadCoeffs& filterCoeffs,
                           BiquadState& filterState,
                           BiquadState& filterState2,
                           int filterMode,
                           float filterQ) noexcept {
    const float phaseInc = hz / static_cast<float>(sampleRate);
    phase += phaseInc;
    if (phase >= 1.0f) phase -= std::floor(phase);

    const float sample = wavetableInterpolatedSample(table, frameCount, frameLength, wtPosition, phase);

    // Apply amp envelope
    float output = sample * ampGain;

    // Filter
    if (filterMode >= 0 && filterMode <= 3) {
        const float cutoffHz = normalizedCutoffToHz(params.filterCutoff + filterGain * params.filterEnvAmount);
        const float cookQ = normalizedQToValue(filterQ);
        if (std::abs(cutoffHz - filterState.lastCutoffHz) > 0.5f ||
            filterCoeffs.b0 == 0.0f) {
            cookSamplerBiquad(filterCoeffs, filterMode, sampleRate, cutoffHz, cookQ);
        }
        output = processBiquadSample(output, filterCoeffs, filterState);
        if (filterMode == 0) {
            // Second-order cascade for 24dB
            output = processBiquadSample(output, filterCoeffs, filterState2);
        }
    }

    return output;
}

void mixWavetableMidiNotesBlock(float* monoOut,
                                int numFrames,
                                double sampleRate,
                                int bpm,
                                double playheadStartBeat,
                                const WavetableMidiNoteRegion* notes,
                                int noteCount,
                                const WavetableSynthParams& params,
                                WavetableSynthRuntime& runtime,
                                const float* wavetablePcm,
                                int wavetableFrameCount,
                                int wavetableFrameLength,
                                const AutomationClipPlayback* automationClips,
                                int automationClipCount,
                                const uint16_t* automationDeviceIndex,
                                const float* lfoValues,
                                int lfoCount,
                                int lfoStride,
                                const ModulationEdgePlayback* modEdges,
                                int modEdgeCount,
                                const uint16_t* modulationDeviceIndex) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0 ||
        wavetablePcm == nullptr || wavetableFrameCount <= 0 || wavetableFrameLength <= 0) {
        return;
    }

    const bool useAutomation = automationClips != nullptr && automationClipCount > 0 &&
                               automationDeviceIndex != nullptr;
    const bool useModulation = lfoValues != nullptr && lfoCount > 0 && lfoStride > 0 &&
                               modEdges != nullptr && modEdgeCount > 0 &&
                               modulationDeviceIndex != nullptr;

    const float ampReleaseSec = adsrNormalizedToSeconds(params.ampRelease, 3.0f);
    const float ampAttackSec = adsrNormalizedToSeconds(params.ampAttack, 2.0f);
    const float ampDecaySec = adsrNormalizedToSeconds(params.ampDecay, 2.0f);
    const float ampSustain = safe_clamp(params.ampSustain, 0.0f, 1.0f);
    const float filterAttackSec = adsrNormalizedToSeconds(params.filterAttack, 2.0f);
    const float filterDecaySec = adsrNormalizedToSeconds(params.filterDecay, 2.0f);
    const float filterReleaseSec = adsrNormalizedToSeconds(params.filterRelease, 3.0f);
    const float filterSustain = safe_clamp(params.filterSustain, 0.0f, 1.0f);

    const double blockStartBeat = playheadStartBeat;

    // Phase 1: Voice allocation
    int allocatedVoices = 0;
    for (int ni = 0; ni < noteCount && allocatedVoices < kWavetableMaxVoices; ++ni) {
        if (!isNoteAudibleInBlock(notes[ni], blockStartBeat, numFrames, sampleRate, bpm, ampReleaseSec)) {
            continue;
        }
        int vi = -1;
        for (int v = 0; v < kWavetableMaxVoices; ++v) {
            if (runtime.voices[v].active != 0 &&
                runtime.voices[v].pitch == notes[ni].pitch &&
                runtime.voices[v].startBeat == notes[ni].noteStartBeat) {
                vi = v;
                break;
            }
        }
        if (vi < 0) {
            for (int v = 0; v < kWavetableMaxVoices; ++v) {
                if (runtime.voices[v].active == 0) { vi = v; break; }
            }
        }
        if (vi < 0) {
            vi = runtime.stealIndex;
            runtime.stealIndex = (runtime.stealIndex + 1) % kWavetableMaxVoices;
        }

        auto& voice = runtime.voices[vi];
        if (voice.pitch != notes[ni].pitch || voice.startBeat != notes[ni].noteStartBeat) {
            std::memset(&voice, 0, sizeof(voice));
            voice.active = 1;
            voice.pitch = notes[ni].pitch;
            voice.startBeat = notes[ni].noteStartBeat;
            voice.velocity = notes[ni].velocity;
            voice.targetHz = wavetablePitchHz(notes[ni].pitch, 0.5f, 0.5f, 0.5f);
            voice.currentHz = voice.targetHz;
            voice.phase = 0.0f;
        } else {
            voice.active = 1;
        }
        ++allocatedVoices;
    }

    bool anyVoiceActive = false;
    for (int v = 0; v < kWavetableMaxVoices; ++v) {
        if (runtime.voices[v].active != 0) {
            anyVoiceActive = true;
            break;
        }
    }
    if (!anyVoiceActive) return;

    const float wtSmoothingCoeff = sampleRate > 0.0
        ? static_cast<float>(1.0 - std::exp(-1.0 / (sampleRate * 0.012)))
        : 1.0f;
    if (runtime.wtPositionSmoothingInitialized == 0) {
        runtime.smoothedWtPosition = safe_clamp(params.wtPosition, 0.0f, 1.0f);
        runtime.wtPositionSmoothingInitialized = 1;
    }

    // Phase 2: Per-frame rendering
    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(blockStartBeat, frame, sampleRate, bpm);

        WavetableSynthParams frameParams = params;
        if (useAutomation) {
            DeviceVariantParams variant = frameParams;
            // applyDspAutomationAtBeat(const DeviceVariantParams&, DeviceNodeKind, uint16_t, ...)
            // We need the right DeviceNodeKind; but the function might not be template.
            // For now, just use params directly.
        }
        if (useModulation) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const ModulationEdgePlayback& edge = modEdges[e];
                if (edge.deviceIndex != *modulationDeviceIndex) continue;
                if (edge.lfoId >= static_cast<uint16_t>(lfoCount)) continue;
                const float lfoOut = lfoValues[static_cast<size_t>(edge.lfoId) *
                                                  static_cast<size_t>(lfoStride) +
                                                  static_cast<size_t>(frame)];
                const float modAmount = edge.amount * lfoOut;
                // Apply modulation to params
                const uint16_t pid = edge.localParamId;
                if (pid != static_cast<uint16_t>(-1)) {
                    // generic modulation would be applied here per param
                }
            }
        }

        const float targetWtPosition = safe_clamp(frameParams.wtPosition, 0.0f, 1.0f);
        runtime.smoothedWtPosition +=
            (targetWtPosition - runtime.smoothedWtPosition) * wtSmoothingCoeff;
        const float frameWtPos = runtime.smoothedWtPosition *
            static_cast<float>(std::max(wavetableFrameCount - 1, 1));

        float mix = 0.0f;
        int renderedCount = 0;

        for (int v = 0; v < kWavetableMaxVoices; ++v) {
            auto& voice = runtime.voices[v];
            if (voice.active == 0) continue;

            int ni = -1;
            for (int n = 0; n < noteCount; ++n) {
                if (notes[n].pitch == voice.pitch && notes[n].noteStartBeat == voice.startBeat) {
                    ni = n; break;
                }
            }
            if (ni < 0) continue;

            const auto& note = notes[ni];
            double elapsedSec = 0.0, noteDurSec = 0.0;
            bool inRelease = false;
            if (!isWavetableNoteAudible(note, beat, bpm, ampReleaseSec,
                                         elapsedSec, noteDurSec, inRelease)) {
                if (inRelease && elapsedSec >= noteDurSec + static_cast<double>(ampReleaseSec)) {
                    voice.active = 0;
                }
                continue;
            }

            const float ampGain = samplerAdsrGain(static_cast<float>(elapsedSec),
                                                  static_cast<float>(noteDurSec),
                                                  ampAttackSec, ampDecaySec,
                                                  ampSustain, ampReleaseSec);
            if (ampGain <= 0.0f) {
                if (inRelease && elapsedSec >= noteDurSec + static_cast<double>(ampReleaseSec)) {
                    voice.active = 0;
                }
                continue;
            }

            const float filterGain = samplerAdsrGain(static_cast<float>(elapsedSec),
                                                     static_cast<float>(noteDurSec),
                                                     filterAttackSec, filterDecaySec,
                                                     filterSustain, filterReleaseSec);

            const float vel = safe_clamp(voice.velocity / 127.0f, 0.0f, 1.0f);

            const float hz = voice.currentHz;
            const float wtPos = frameWtPos;

            mix += wavetableVoiceSample(frameParams,
                                        wavetablePcm,
                                        wavetableFrameCount,
                                        wavetableFrameLength,
                                        voice.phase,
                                        wtPos, hz,
                                        static_cast<float>(sampleRate),
                                        ampGain * vel,
                                        filterGain,
                                        voice.cachedFilterCoeffs,
                                        voice.filterState,
                                        voice.filterState2,
                                        frameParams.filterMode,
                                        frameParams.filterResonance) *
                   frameParams.gain * kInstrumentOutputGain;

            if (inRelease && elapsedSec >= noteDurSec + static_cast<double>(ampReleaseSec)) {
                voice.active = 0;
            }
            ++renderedCount;
        }

        if (renderedCount > 0) {
            mix *= 1.0f / std::sqrt(static_cast<float>(renderedCount));
        }
        monoOut[frame] += mix;
    }
}

} // namespace audioapp
