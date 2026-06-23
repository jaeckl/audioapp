#include "audioapp/devices/processors/SubtractiveSynthProcessor.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {
namespace {

// --- Helper functions for mixSubtractiveMidiNotesBlock ---

static inline float safe_clamp(float v, float lo, float hi) noexcept {
    if (!std::isfinite(v)) return lo;
    return std::clamp(v, lo, hi);
}

float beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return static_cast<float>(playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0);
}

bool isSubtractiveNoteAudible(const SubtractiveMidiNoteRegion& note,
                              double beat,
                              int bpm,
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
    const double releaseBeats =
        static_cast<double>(releaseSec) * static_cast<double>(bpm) / 60.0;

    if (loopedBeat < noteStart) {
        return false;
    }

    const double elapsedBeats = loopedBeat - noteStart;
    elapsedSecondsOut = static_cast<float>(elapsedBeats * 60.0 / static_cast<double>(bpm));
    noteDurationSecOut = static_cast<float>(note.noteDurationBeats * 60.0 / static_cast<double>(bpm));
    inReleaseOut = loopedBeat >= noteEnd;

    if (loopedBeat < noteEnd) {
        return true;
    }
    return loopedBeat < noteEnd + releaseBeats;
}

bool isNoteAudibleInBlock(const SubtractiveMidiNoteRegion& note,
                          double blockStartBeat,
                          int numFrames,
                          double sampleRate,
                          int bpm,
                          float releaseSec) noexcept {
    if (bpm <= 0 || sampleRate <= 0.0) return false;
    const double blockEndBeat = blockStartBeat + static_cast<double>(numFrames) *
        (static_cast<double>(bpm) / 60.0) / sampleRate;

    const double noteStart = note.clipStartBeat + note.noteStartBeat;
    const double noteEnd = noteStart + note.noteDurationBeats;
    const double releaseBeats = static_cast<double>(releaseSec) * static_cast<double>(bpm) / 60.0;
    const double totalEnd = noteEnd + releaseBeats;

    return !(blockEndBeat < noteStart || blockStartBeat >= totalEnd);
}

/// Per-frame LFO modulation for the subtractive synth's DSP params.
static void applySubtractiveModulation(SubtractiveSynthParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<SubtractiveParam>(unpackParamId(localParamId))) {
    case SubtractiveParam::FilterCutoff:      p.filterCutoff = safe_clamp(p.filterCutoff + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterQ:           p.filterQ = safe_clamp(p.filterQ + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterMode:        p.filterMode = safe_clamp(static_cast<int>(std::lround(static_cast<float>(p.filterMode) + modAmount * 5.0f)), 0, 5); break;
    case SubtractiveParam::AmpAttack:         p.ampAttack = safe_clamp(p.ampAttack + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::AmpDecay:          p.ampDecay = safe_clamp(p.ampDecay + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::AmpSustain:        p.ampSustain = safe_clamp(p.ampSustain + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::AmpRelease:        p.ampRelease = safe_clamp(p.ampRelease + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc1Shape:         p.osc1Shape = safe_clamp(p.osc1Shape + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Shape:         p.osc2Shape = safe_clamp(p.osc2Shape + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc1Octave:        p.osc1Octave = safe_clamp(p.osc1Octave + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc1Semi:          p.osc1Semi = safe_clamp(p.osc1Semi + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc1Detune:        p.osc1Detune = safe_clamp(p.osc1Detune + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Octave:        p.osc2Octave = safe_clamp(p.osc2Octave + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Semi:          p.osc2Semi = safe_clamp(p.osc2Semi + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Detune:        p.osc2Detune = safe_clamp(p.osc2Detune + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::OscMix:            p.oscMix = safe_clamp(p.oscMix + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::OscMixMode:        p.oscMixMode = safe_clamp(static_cast<int>(std::lround(static_cast<float>(p.oscMixMode) + modAmount * 4.0f)), 0, 4); break;
    case SubtractiveParam::Osc1Sync:          p.osc1Sync = safe_clamp(p.osc1Sync + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Sync:          p.osc2Sync = safe_clamp(p.osc2Sync + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::NoiseLevel:        p.noiseLevel = safe_clamp(p.noiseLevel + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::UnisonVoices:      p.unisonVoices = safe_clamp(p.unisonVoices + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::UnisonDetune:      p.unisonDetune = safe_clamp(p.unisonDetune + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterEnvAmount:   p.filterEnvAmount = safe_clamp(p.filterEnvAmount + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterAttack:      p.filterAttack = safe_clamp(p.filterAttack + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterDecay:       p.filterDecay = safe_clamp(p.filterDecay + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterSustain:     p.filterSustain = safe_clamp(p.filterSustain + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterRelease:     p.filterRelease = safe_clamp(p.filterRelease + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::GlideMs:           p.glideMs = safe_clamp(p.glideMs + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::VelocitySensitivity: p.velocitySensitivity = safe_clamp(p.velocitySensitivity + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::PreHpCutoff:       p.preHpCutoff = safe_clamp(p.preHpCutoff + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::PreHpRes:          p.preHpRes = safe_clamp(p.preHpRes + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::PreDrive:          p.preDrive = safe_clamp(p.preDrive + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::MixFeedback:       p.mixFeedback = safe_clamp(p.mixFeedback + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::GlobalPitch:       p.globalPitch = safe_clamp(p.globalPitch + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterKeyTrack:    p.filterKeyTrack = safe_clamp(p.filterKeyTrack + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterDrive:       p.filterDrive = safe_clamp(p.filterDrive + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterShaper:      p.filterShaper = safe_clamp(p.filterShaper + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterFm:          p.filterFm = safe_clamp(p.filterFm + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterShaperMode:  p.filterShaperMode = safe_clamp(static_cast<int>(std::lround(static_cast<float>(p.filterShaperMode) + modAmount * 3.0f)), 0, 3); break;
    case SubtractiveParam::SynthLegato:       p.synthLegato = safe_clamp(p.synthLegato + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::SynthMono:         p.synthMono = safe_clamp(p.synthMono + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

} // anonymous namespace

// mixSubtractiveMidiNotesBlock is at audioapp namespace scope so it remains
// linkable from other translation units (e.g. EngineHost_commands.cpp).

void mixSubtractiveMidiNotesBlock(float* monoOut,
                                  int numFrames,
                                  double sampleRate,
                                  int bpm,
                                  double playheadStartBeat,
                                  const SubtractiveMidiNoteRegion* notes,
                                  int noteCount,
                                  const SubtractiveSynthParams& params,
                                  SubtractiveSynthRuntime& runtime,
                                  const AutomationClipPlayback* automationClips,
                                  int automationClipCount,
                                  const uint16_t* automationDeviceIndex,
                                  const float* lfoValues,
                                  int lfoCount,
                                  int lfoStride,
                                  const ModulationEdgePlayback* modEdges,
                                  int modEdgeCount,
                                  const uint16_t* modulationDeviceIndex) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
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
    const float glideMs = params.glideMs * 2000.0f;
    const float glideCoeff =
        glideMs > 0.0f ? 1.0f - std::exp(-1.0f / (static_cast<float>(sampleRate) * glideMs * 0.001f))
                       : 1.0f;

    const double blockStartBeat = playheadStartBeat;

    // --- Phase 1: Voice allocation ---
    int allocatedVoices = 0;
    for (int ni = 0; ni < noteCount && allocatedVoices < kSubtractiveMaxVoices; ++ni) {
        if (!isNoteAudibleInBlock(notes[ni], blockStartBeat, numFrames, sampleRate, bpm, ampReleaseSec)) {
            continue;
        }
        int vi = -1;
        for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
            if (runtime.voices[v].active != 0 &&
                runtime.voices[v].pitch == notes[ni].pitch &&
                runtime.voices[v].startBeat == notes[ni].noteStartBeat) {
                vi = v;
                break;
            }
        }
        if (vi < 0) {
            for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
                if (runtime.voices[v].active == 0) { vi = v; break; }
            }
        }
        if (vi < 0) {
            vi = runtime.stealIndex;
            runtime.stealIndex = (runtime.stealIndex + 1) % kSubtractiveMaxVoices;
        }

        auto& voice = runtime.voices[vi];
        if (voice.pitch != notes[ni].pitch || voice.startBeat != notes[ni].noteStartBeat) {
            std::memset(&voice, 0, sizeof(voice));
            voice.active = 1;
            voice.pitch = notes[ni].pitch;
            voice.startBeat = notes[ni].noteStartBeat;
            voice.velocity = notes[ni].velocity;
            voice.targetHz = subtractiveOscPitchHz(notes[ni].pitch, 0.5f, 0.0f, 0.5f);
            voice.currentHz = voice.targetHz;
            voice.noiseSeed = 0.1f + static_cast<float>(notes[ni].pitch) * 0.013f;
        } else {
            voice.active = 1;
        }
        ++allocatedVoices;
    }

    bool anyVoiceActive = false;
    for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
        if (runtime.voices[v].active != 0) {
            anyVoiceActive = true;
            break;
        }
    }
    if (!anyVoiceActive) return;

    // --- Phase 2: Per-frame rendering ---
    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(blockStartBeat, frame, sampleRate, bpm);

        SubtractiveSynthParams frameParams = params;
        if (useAutomation) {
            DeviceVariantParams variant = frameParams;
            applyDspAutomationAtBeat(variant,
                                     DeviceNodeKind::SubtractiveSynth,
                                     *automationDeviceIndex,
                                     beat,
                                     automationClips,
                                     automationClipCount);
            if (const auto* automated = std::get_if<SubtractiveSynthParams>(&variant)) {
                frameParams = *automated;
            }
        }
        if (useModulation) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const ModulationEdgePlayback& edge = modEdges[e];
                if (edge.deviceIndex != *modulationDeviceIndex) continue;
                if (edge.lfoId >= static_cast<uint16_t>(lfoCount)) continue;
                const uint16_t pid = edge.localParamId;
                if (pid == kEncodedCommonGain ||
                    pid == kEncodedCommonPan) {
                    continue;
                }
                const float lfoOut = lfoValues[static_cast<size_t>(edge.lfoId) *
                                                  static_cast<size_t>(lfoStride) +
                                                  static_cast<size_t>(frame)];
                const float modAmount = edge.amount * lfoOut;
                applySubtractiveModulation(frameParams, modAmount, pid);
            }
        }

        float mix = 0.0f;
        int renderedCount = 0;

        int activeMonoPitch = -1;
        if (frameParams.synthMono >= 0.5f) {
            for (int ni = noteCount - 1; ni >= 0; --ni) {
                double elapsedSec = 0.0, noteDurSec = 0.0;
                bool inRelease = false;
                if (isSubtractiveNoteAudible(notes[ni], beat, bpm, ampReleaseSec,
                                              elapsedSec, noteDurSec, inRelease)) {
                    activeMonoPitch = notes[ni].pitch;
                    break;
                }
            }
        }

        for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
            auto& voice = runtime.voices[v];
            if (voice.active == 0) continue;

            if (frameParams.synthMono >= 0.5f && voice.pitch != activeMonoPitch) {
                if (activeMonoPitch >= 0) {
                    voice.active = 0;
                }
                continue;
            }

            int ni = -1;
            for (int n = 0; n < noteCount; ++n) {
                if (notes[n].pitch == voice.pitch && notes[n].noteStartBeat == voice.startBeat) { ni = n; break; }
            }
            if (ni < 0) continue;

            const auto& note = notes[ni];
            double elapsedSec = 0.0, noteDurSec = 0.0;
            bool inRelease = false;
            if (!isSubtractiveNoteAudible(note, beat, bpm, ampReleaseSec,
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
            const float velGain = 1.0f - frameParams.velocitySensitivity * (1.0f - vel);

            mix += subtractiveVoiceSample(voice, frameParams,
                                           ampGain * velGain,
                                           filterGain,
                                           sampleRate, glideCoeff) *
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

void SubtractiveSynthProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (ctx.suppressInstruments || ctx.noteCount <= 0) {
        return;
    }

    const int regionCount = ctx.noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : ctx.noteCount;
    for (int i = 0; i < regionCount; ++i) {
        const MidiPlaybackNote& note = ctx.notes[i];
        ctx.scratch.subtractiveRegions[i] = SubtractiveMidiNoteRegion{
            note.pitch, note.pitch,
            note.clipStartBeat, note.clipLengthBeats,
            note.noteStartBeat, note.noteDurationBeats, note.velocity
        };
    }

    std::memset(ctx.scratch.scratch, 0, static_cast<size_t>(block.numSamples) * sizeof(float));

    auto& runtime = runtime_;
    const uint16_t di = static_cast<uint16_t>(ctx.deviceIndex);
    const bool hasAuto = nodeHasDspAutomation(di, ctx.automationClips, ctx.automationClipCount);
    const bool hasMod = ctx.lfoValues != nullptr && ctx.lfoCount > 0 &&
                        ctx.modEdges != nullptr && ctx.modEdgeCount > 0 &&
                        DeviceChainAutomationModulation::nodeHasDspModulation(di, ctx.modEdges, ctx.modEdgeCount);

    mixSubtractiveMidiNotesBlock(ctx.scratch.scratch, block.numSamples, ctx.sampleRate, ctx.bpm, ctx.playheadBeat,
        ctx.scratch.subtractiveRegions, regionCount,
        std::get<SubtractiveSynthParams>(*ctx.modulatedParams), runtime,
        hasAuto ? ctx.automationClips : nullptr, hasAuto ? ctx.automationClipCount : 0,
        hasAuto ? &di : nullptr,
        hasMod ? ctx.lfoValues : nullptr, hasMod ? ctx.lfoCount : 0, hasMod ? block.numSamples : 0,
        hasMod ? ctx.modEdges : nullptr, hasMod ? ctx.modEdgeCount : 0,
        hasMod ? &di : nullptr);

    StereoOutputPanel::applyFromScratch(ctx.scratch.scratch, block, block.numSamples,
                                         ctx.scratch.perFrameGain, ctx.scratch.perFramePan);
}

void BassSynthProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (ctx.suppressInstruments || ctx.noteCount <= 0) {
        return;
    }

    const int regionCount = ctx.noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : ctx.noteCount;
    for (int i = 0; i < regionCount; ++i) {
        const MidiPlaybackNote& note = ctx.notes[i];
        ctx.scratch.subtractiveRegions[i] = SubtractiveMidiNoteRegion{
            note.pitch, note.pitch,
            note.clipStartBeat, note.clipLengthBeats,
            note.noteStartBeat, note.noteDurationBeats, note.velocity
        };
    }

    std::memset(ctx.scratch.scratch, 0, static_cast<size_t>(block.numSamples) * sizeof(float));

    auto& runtime = runtime_;
    const uint16_t di = static_cast<uint16_t>(ctx.deviceIndex);
    const bool hasAuto = nodeHasDspAutomation(di, ctx.automationClips, ctx.automationClipCount);
    const bool hasMod = ctx.lfoValues != nullptr && ctx.lfoCount > 0 &&
                        ctx.modEdges != nullptr && ctx.modEdgeCount > 0 &&
                        DeviceChainAutomationModulation::nodeHasDspModulation(di, ctx.modEdges, ctx.modEdgeCount);

    mixSubtractiveMidiNotesBlock(ctx.scratch.scratch, block.numSamples, ctx.sampleRate, ctx.bpm, ctx.playheadBeat,
        ctx.scratch.subtractiveRegions, regionCount,
        std::get<SubtractiveSynthParams>(*ctx.modulatedParams), runtime,
        hasAuto ? ctx.automationClips : nullptr, hasAuto ? ctx.automationClipCount : 0,
        hasAuto ? &di : nullptr,
        hasMod ? ctx.lfoValues : nullptr, hasMod ? ctx.lfoCount : 0, hasMod ? block.numSamples : 0,
        hasMod ? ctx.modEdges : nullptr, hasMod ? ctx.modEdgeCount : 0,
        hasMod ? &di : nullptr);

    StereoOutputPanel::applyFromScratch(ctx.scratch.scratch, block, block.numSamples,
                                         ctx.scratch.perFrameGain, ctx.scratch.perFramePan);
}

} // namespace audioapp