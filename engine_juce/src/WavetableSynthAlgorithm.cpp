#include "audioapp/WavetableSynthAlgorithm.hpp"
#include "audioapp/WavetableOscSimd.hpp"
#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"
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
    if (bpm <= 0) {
        return false;
    }
    const double loopedBeat = beatWithinClipContent(
        beat,
        note.clipStartBeat,
        note.clipLengthBeats,
        note.contentLengthBeats,
        note.loopContent);
    if (loopedBeat < 0.0) {
        return false;
    }
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
    const double releaseBeats = static_cast<double>(releaseSec) * static_cast<double>(bpm) / 60.0;
    return blockMayContainLoopedClipNotes(
        blockStartBeat,
        blockEndBeat,
        note.clipStartBeat,
        note.clipLengthBeats,
        note.contentLengthBeats,
        note.loopContent,
        note.noteStartBeat,
        note.noteDurationBeats,
        releaseBeats);
}

static WavetableSynthParamsPlayback heldWavetableParamsAtFrame(
    const WavetableSynthParamsPlayback& base,
    int heldFrame,
    double blockStartBeat,
    double sampleRate,
    int bpm,
    bool useAutomation,
    const AutomationClipPlayback* automationClips,
    int automationClipCount,
    const uint16_t* automationDeviceIndex,
    bool useModulation,
    const float* lfoValues,
    int lfoCount,
    int lfoStride,
    const ModulationEdgePlayback* modEdges,
    int modEdgeCount,
    const uint16_t* modulationDeviceIndex,
    const InstrumentModulationContext* instMod) noexcept {
    WavetableSynthParamsPlayback held = wavetableRealtimeParams(base);
    const double beat = beatAtFrame(blockStartBeat, heldFrame, sampleRate, bpm);
    if (useAutomation) {
        DeviceVariantParams variant = held;
        applyDspAutomationAtBeat(variant,
                                 DeviceNodeKind::WavetableSynth,
                                 *automationDeviceIndex,
                                 beat,
                                 automationClips,
                                 automationClipCount);
        if (const auto* automated = std::get_if<WavetableSynthParamsPlayback>(&variant)) {
            held = *automated;
        }
    }
    if (useModulation && instMod != nullptr) {
        DeviceVariantParams variant = held;
        applyGlobalDspModulationAtFrame(variant,
                                        DeviceNodeKind::WavetableSynth,
                                        instMod->deviceIndex,
                                        heldFrame,
                                        lfoStride,
                                        *instMod);
        if (const auto* modulated = std::get_if<WavetableSynthParamsPlayback>(&variant)) {
            held = *modulated;
        }
    } else if (useModulation) {
        for (int e = 0; e < modEdgeCount; ++e) {
            const ModulationEdgePlayback& edge = modEdges[e];
            if (edge.deviceIndex != *modulationDeviceIndex) continue;
            if (edge.lfoId >= static_cast<uint16_t>(lfoCount)) continue;
            const uint16_t pid = edge.localParamId;
            if (pid == kEncodedCommonGain ||
                pid == kEncodedCommonPan ||
                pid == kEncodedCommonBypass) {
                continue;
            }
            const float lfoOut = lfoValues[static_cast<size_t>(edge.lfoId) *
                                              static_cast<size_t>(lfoStride) +
                                              static_cast<size_t>(heldFrame)];
            const float modAmount = edge.amount * lfoOut;
            DeviceChainAutomationModulation::applyModulation(held, modAmount, pid);
        }
    }
    return held;
}

static int resolveVoiceNoteIndex(const WavetableVoiceRuntime& voice,
                                 const WavetableMidiNoteRegion* notes,
                                 int noteCount) noexcept {
    const int ni = voice.noteKey;
    if (ni >= 0 && ni < noteCount &&
        notes[ni].pitch == voice.pitch &&
        notes[ni].noteStartBeat == voice.startBeat &&
        notes[ni].clipStartBeat == voice.clipStartBeat) {
        return ni;
    }
    for (int n = 0; n < noteCount; ++n) {
        if (notes[n].pitch == voice.pitch && notes[n].noteStartBeat == voice.startBeat &&
            notes[n].clipStartBeat == voice.clipStartBeat) {
            return n;
        }
    }
    return -1;
}

} // anonymous namespace

namespace {

void precomputeWavetableUnisonRatios(float* ratioPerUnit,
                                     int unisonCount,
                                     float spreadCents) noexcept {
    if (ratioPerUnit == nullptr || unisonCount <= 0) {
        return;
    }
    for (int u = 0; u < unisonCount; ++u) {
        const float spread = unisonCount > 1
            ? (static_cast<float>(u) / static_cast<float>(unisonCount - 1) - 0.5f) * 2.0f
            : 0.0f;
        const float cents = spread * spreadCents;
        ratioPerUnit[u] = std::pow(2.0f, cents / 1200.0f);
    }
}

} // namespace

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

float wavetableVoiceSample(const WavetableSynthParamsPlayback& params,
                           const float* table,
                           int frameCount,
                           int frameLength,
                           WavetableVoiceRuntime& voice,
                           float wtPosition,
                           float sampleRate,
                           float ampGain,
                           float filterGain,
                           BiquadCoeffs& filterCoeffs,
                           BiquadState& filterState,
                           BiquadState& filterState2,
                           int filterMode,
                           float filterQ) noexcept {
    const float rootHz = wavetablePitchHz(voice.pitch,
                                          params.wtOctave,
                                          params.wtSemitone,
                                          params.wtFine);
    voice.targetHz = rootHz;
    voice.currentHz = rootHz;

    const int unisonCount = wavetableUnisonCount(params.wtUnison);
    const float spreadCents = params.wtDetune * 50.0f;
    if (unisonCount != voice.cachedUnisonCount ||
        std::abs(spreadCents - voice.cachedUnisonSpreadCents) > 0.01f) {
        precomputeWavetableUnisonRatios(voice.unisonHzRatio, unisonCount, spreadCents);
        voice.cachedUnisonCount = unisonCount;
        voice.cachedUnisonSpreadCents = spreadCents;
    }

    const float invSampleRate = 1.0f / sampleRate;
    float oscAvg = 0.0f;
    if (!renderWavetableUnisonBankSimd(table,
                                       frameCount,
                                       frameLength,
                                       wtPosition,
                                       rootHz,
                                       voice.unisonHzRatio,
                                       unisonCount,
                                       invSampleRate,
                                       voice.phases,
                                       oscAvg)) {
        float oscSum = 0.0f;
        for (int u = 0; u < unisonCount; ++u) {
            const float hz = rootHz * voice.unisonHzRatio[u];
            const float phaseInc = hz * invSampleRate;
            voice.phases[u] += phaseInc;
            if (voice.phases[u] >= 1.0f) {
                voice.phases[u] -= std::floor(voice.phases[u]);
            }
            oscSum += wavetableInterpolatedSample(
                table, frameCount, frameLength, wtPosition, voice.phases[u]);
        }
        oscAvg = oscSum / static_cast<float>(unisonCount);
    }
    float output = oscAvg * ampGain;

    if (filterMode >= 0 && filterMode <= 3) {
        const float cutoffHz = normalizedCutoffToHz(params.filterCutoff + filterGain * params.filterEnvAmount);
        const float cookQ = normalizedQToValue(filterQ);
        if (std::abs(cutoffHz - filterState.lastCutoffHz) > 0.5f ||
            filterCoeffs.b0 == 0.0f) {
            cookSamplerBiquad(filterCoeffs, filterMode, sampleRate, cutoffHz, cookQ);
        }
        output = processBiquadSample(output, filterCoeffs, filterState);
        if (filterMode == 0) {
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
                                const WavetableSynthParamsPlayback& params,
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
                                const uint16_t* modulationDeviceIndex,
                                const float* perFramePanelGain,
                                const InstrumentModulationContext* instMod,
                                int voiceLimit,
                                bool retriggerReplacesVoice,
                                const CommonControlBlock* commonControls) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0 ||
        wavetablePcm == nullptr || wavetableFrameCount <= 0 || wavetableFrameLength <= 0) {
        return;
    }

    const int maxVoices = safe_clamp(voiceLimit, 1, kWavetableMaxVoices);
    if (retriggerReplacesVoice && maxVoices == 1) {
        for (int v = 1; v < kWavetableMaxVoices; ++v) runtime.voices[v].active = 0;
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
    const double blockEndBeat = blockStartBeat + static_cast<double>(numFrames) *
        (static_cast<double>(bpm) / 60.0) / sampleRate;

    // Phase 1: Voice allocation
    int allocatedVoices = 0;
    for (int ni = retriggerReplacesVoice && maxVoices == 1 ? noteCount - 1 : 0;
         ni >= 0 && ni < noteCount && allocatedVoices < maxVoices;
         ni += retriggerReplacesVoice && maxVoices == 1 ? -1 : 1) {
        if (!isNoteAudibleInBlock(notes[ni], blockStartBeat, numFrames, sampleRate, bpm, ampReleaseSec)) {
            continue;
        }
        int vi = -1;
        for (int v = 0; v < maxVoices; ++v) {
            if (runtime.voices[v].active != 0 &&
                runtime.voices[v].pitch == notes[ni].pitch &&
                runtime.voices[v].startBeat == notes[ni].noteStartBeat &&
                runtime.voices[v].clipStartBeat == notes[ni].clipStartBeat) {
                vi = v;
                break;
            }
        }
        if (vi < 0) {
            for (int v = 0; v < maxVoices; ++v) {
                if (runtime.voices[v].active == 0) { vi = v; break; }
            }
        }
        if (vi < 0) {
            vi = runtime.stealIndex;
            runtime.stealIndex = (runtime.stealIndex + 1) % maxVoices;
        }

        auto& voice = runtime.voices[vi];
        const bool noteOnsetInBlock = midiNoteOnsetInBlock(
            blockStartBeat,
            blockEndBeat,
            notes[ni].clipStartBeat,
            notes[ni].clipLengthBeats,
            notes[ni].contentLengthBeats,
            notes[ni].loopContent,
            notes[ni].noteStartBeat);
        if (voice.pitch != notes[ni].pitch || voice.startBeat != notes[ni].noteStartBeat ||
            voice.clipStartBeat != notes[ni].clipStartBeat || noteOnsetInBlock) {
            std::memset(&voice, 0, sizeof(voice));
            voice.active = 1;
            voice.pitch = notes[ni].pitch;
            voice.startBeat = notes[ni].noteStartBeat;
            voice.clipStartBeat = notes[ni].clipStartBeat;
            voice.noteKey = ni;
            voice.velocity = notes[ni].velocity;
            voice.targetHz = wavetablePitchHz(notes[ni].pitch,
                                              params.wtOctave,
                                              params.wtSemitone,
                                              params.wtFine);
            voice.currentHz = voice.targetHz;
            std::memset(voice.phases, 0, sizeof(voice.phases));
        } else {
            voice.active = 1;
        }
        ++allocatedVoices;
    }

    bool anyVoiceActive = false;
    for (int v = 0; v < maxVoices; ++v) {
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

    const bool needsHeldParams = useAutomation || useModulation;

    auto renderFrame = [&](int frame, const WavetableSynthParamsPlayback& heldParams) {
        const double beat = beatAtFrame(blockStartBeat, frame, sampleRate, bpm);

        const float targetWtPosition = safe_clamp(heldParams.wtPosition, 0.0f, 1.0f);
        runtime.smoothedWtPosition +=
            (targetWtPosition - runtime.smoothedWtPosition) * wtSmoothingCoeff;
        const float frameWtPos = runtime.smoothedWtPosition *
            static_cast<float>(std::max(wavetableFrameCount - 1, 1));

        float mix = 0.0f;
        int renderedCount = 0;

        for (int v = 0; v < maxVoices; ++v) {
            auto& voice = runtime.voices[v];
            if (voice.active == 0) continue;

            int ni = resolveVoiceNoteIndex(voice, notes, noteCount);
            if (ni < 0) continue;
            if (ni != voice.noteKey) {
                voice.noteKey = ni;
            }

            const auto& note = notes[ni];
            double elapsedSec = 0.0;
            double noteDurSec = 0.0;
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

            WavetableSynthParamsPlayback voiceParams = wavetableRealtimeParams(heldParams);
            float panelGain = commonControls != nullptr
                ? commonControls->gainAt(frame)
                : (perFramePanelGain != nullptr ? perFramePanelGain[frame] : 1.0f);
            if (instMod != nullptr) {
                const NoteModKey key =
                    noteModKeyFromRegion(note.pitch, note.clipStartBeat, note.noteStartBeat);
                const ModulationEvalContext evalCtx = instMod->evalContextForFrame(frame);
                DeviceVariantParams variant = voiceParams;
                applyPerNoteDspModulation(variant,
                                          DeviceNodeKind::WavetableSynth,
                                          instMod->deviceIndex,
                                          elapsedSec,
                                          noteDurSec,
                                          key,
                                          evalCtx,
                                          *instMod);
                if (const auto* modulated = std::get_if<WavetableSynthParamsPlayback>(&variant)) {
                    voiceParams = *modulated;
                }
                panelGain = applyPerNoteCommonGain(panelGain,
                                                   instMod->deviceIndex,
                                                   elapsedSec,
                                                   noteDurSec,
                                                   key,
                                                   evalCtx,
                                                   *instMod);
            }

            mix += wavetableVoiceSample(voiceParams,
                                        wavetablePcm,
                                        wavetableFrameCount,
                                        wavetableFrameLength,
                                        voice,
                                        frameWtPos,
                                        static_cast<float>(sampleRate),
                                        ampGain * vel,
                                        filterGain,
                                        voice.cachedFilterCoeffs,
                                        voice.filterState,
                                        voice.filterState2,
                                        voiceParams.filterMode,
                                        voiceParams.filterResonance) *
                   voiceParams.gain * panelGain * kInstrumentOutputGain;

            if (inRelease && elapsedSec >= noteDurSec + static_cast<double>(ampReleaseSec)) {
                voice.active = 0;
            }
            ++renderedCount;
        }

        if (renderedCount > 0) {
            mix *= 1.0f / std::sqrt(static_cast<float>(renderedCount));
        }
        monoOut[frame] += mix;
    };

    if (!needsHeldParams) {
        for (int frame = 0; frame < numFrames; ++frame) {
            renderFrame(frame, wavetableRealtimeParams(params));
        }
        return;
    }

    for (int sub = 0; sub < numFrames; sub += kWavetableControlSubBlockFrames) {
        const WavetableSynthParamsPlayback heldParams = heldWavetableParamsAtFrame(
            params,
            sub,
            blockStartBeat,
            sampleRate,
            bpm,
            useAutomation,
            automationClips,
            automationClipCount,
            automationDeviceIndex,
            useModulation,
            lfoValues,
            lfoCount,
            lfoStride,
            modEdges,
            modEdgeCount,
            modulationDeviceIndex,
            instMod);

        const int subLen = std::min(kWavetableControlSubBlockFrames, numFrames - sub);
        for (int frame = sub; frame < sub + subLen; ++frame) {
            renderFrame(frame, heldParams);
        }
    }
}

} // namespace audioapp
