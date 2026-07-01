#include "audioapp/devices/processors/PhaseModSynthProcessor.hpp"
#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/PhaseModSynthAlgorithm.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

// -----------------------------------------------------------------------
// Internal helpers (moved from PhaseModSynth.cpp)
// -----------------------------------------------------------------------

namespace {

static inline float safe_clamp(float v, float lo, float hi) noexcept {
    if (!std::isfinite(v)) return lo;
    return std::clamp(v, lo, hi);
}

static float beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return static_cast<float>(playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0);
}

static bool isNoteAudibleInBlock(const PhaseModSynthMidiNoteRegion& note,
                                 double blockStartBeat,
                                 int numFrames,
                                 double sampleRate,
                                 int bpm,
                                 float releaseSec) noexcept {
    if (bpm <= 0 || sampleRate <= 0.0) return false;
    const double blockEndBeat = blockStartBeat + static_cast<double>(numFrames) *
        (static_cast<double>(bpm) / 60.0) / sampleRate;
    const double releaseBeats = static_cast<double>(releaseSec) * static_cast<double>(bpm) / 60.0;
    return audioapp::blockMayContainLoopedClipNotes(
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

static bool isNoteAudible(const PhaseModSynthMidiNoteRegion& note,
                          double beat,
                          int bpm,
                          float releaseSec,
                          double& elapsedSecondsOut,
                          double& noteDurationSecOut,
                          bool& inReleaseOut) noexcept {
    if (bpm <= 0) {
        return false;
    }

    const double loopedBeat = audioapp::beatWithinClipContent(
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
    const double releaseBeats =
        static_cast<double>(releaseSec) * static_cast<double>(bpm) / 60.0;

    if (loopedBeat < noteStart) {
        return false;
    }

    const double elapsedBeats = loopedBeat - noteStart;
    elapsedSecondsOut = elapsedBeats * 60.0 / static_cast<double>(bpm);
    noteDurationSecOut = note.noteDurationBeats * 60.0 / static_cast<double>(bpm);
    inReleaseOut = loopedBeat >= noteEnd;

    if (loopedBeat < noteEnd) {
        return true;
    }
    return loopedBeat < noteEnd + releaseBeats;
}

} // anonymous namespace

// mixPhaseModMidiNotesBlock is at audioapp namespace scope (NOT in anonymous
// namespace) because it is called from tests/phase_mod_synth_test.cpp in a
// different translation unit.

void mixPhaseModMidiNotesBlock(float* monoOut,
                               int numFrames,
                               double sampleRate,
                               int bpm,
                               double playheadStartBeat,
                               const PhaseModSynthMidiNoteRegion* notes,
                               int noteCount,
                               const PhaseModSynthParams& params,
                               PhaseModSynthRuntime& runtime,
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
                               const InstrumentModulationContext* instMod) noexcept {
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
    for (int ni = 0; ni < noteCount && allocatedVoices < kPhaseModMaxVoices; ++ni) {
        if (!isNoteAudibleInBlock(notes[ni], blockStartBeat, numFrames, sampleRate, bpm, ampReleaseSec)) {
            continue;
        }

        int vi = -1;
        // 1. Exact match by pitch and startBeat
        for (int v = 0; v < kPhaseModMaxVoices; ++v) {
            if (runtime.voices[v].active != 0 &&
                runtime.voices[v].pitch == notes[ni].pitch &&
                runtime.voices[v].startBeat == notes[ni].noteStartBeat &&
                runtime.voices[v].clipStartBeat == notes[ni].clipStartBeat) {
                vi = v;
                break;
            }
        }
        // 2. Free slot
        if (vi < 0) {
            for (int v = 0; v < kPhaseModMaxVoices; ++v) {
                if (runtime.voices[v].active == 0) { vi = v; break; }
            }
        }
        // 3. Steal
        if (vi < 0) {
            vi = runtime.stealIndex;
            runtime.stealIndex = (runtime.stealIndex + 1) % kPhaseModMaxVoices;
        }

        auto& voice = runtime.voices[vi];
        if (voice.pitch != notes[ni].pitch || voice.startBeat != notes[ni].noteStartBeat ||
            voice.clipStartBeat != notes[ni].clipStartBeat) {
            std::memset(&voice, 0, sizeof(voice));
            voice.active = 1;
            voice.pitch = notes[ni].pitch;
            voice.startBeat = notes[ni].noteStartBeat;
            voice.clipStartBeat = notes[ni].clipStartBeat;
            voice.velocity = notes[ni].velocity;
            voice.targetHz = midiNoteToHz(notes[ni].pitch);
            voice.currentHz = voice.targetHz;
        } else {
            voice.active = 1;
        }
        ++allocatedVoices;
    }

    bool anyVoiceActive = false;
    for (int v = 0; v < kPhaseModMaxVoices; ++v) {
        if (runtime.voices[v].active != 0) {
            anyVoiceActive = true;
            break;
        }
    }
    if (!anyVoiceActive) return;

    // --- Per-frame rendering ---
    for (int frame = 0; frame < numFrames; ++frame) {
        const float beat = beatAtFrame(blockStartBeat, frame, sampleRate, bpm);

        PhaseModSynthParams frameParams = params;
        if (useAutomation) {
            DeviceVariantParams variant = frameParams;
            applyDspAutomationAtBeat(variant, DeviceNodeKind::PhaseModSynth,
                                     *automationDeviceIndex, beat,
                                     automationClips, automationClipCount);
            if (const auto* automated = std::get_if<PhaseModSynthParams>(&variant)) {
                frameParams = *automated;
            }
        }

        // Graph modulation: global edges at frame rate; per-note edges per voice.
        if (useModulation && instMod != nullptr) {
            DeviceVariantParams variant = frameParams;
            applyGlobalDspModulationAtFrame(variant,
                                            DeviceNodeKind::PhaseModSynth,
                                            instMod->deviceIndex,
                                            frame,
                                            lfoStride,
                                            *instMod);
            if (const auto* automated = std::get_if<PhaseModSynthParams>(&variant)) {
                frameParams = *automated;
            }
        } else if (useModulation) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const ModulationEdgePlayback& edge = modEdges[e];
                if (edge.deviceIndex != *modulationDeviceIndex) continue;
                if (edge.lfoId >= static_cast<uint16_t>(lfoCount)) continue;
                const uint16_t pid = edge.localParamId;
                if (pid == kEncodedCommonGain || pid == kEncodedCommonPan) continue;
                const float lfoOut = lfoValues[static_cast<size_t>(edge.lfoId) *
                                   static_cast<size_t>(lfoStride) +
                                   static_cast<size_t>(frame)];
                const float modAmount = edge.amount * lfoOut;
                DeviceChainAutomationModulation::applyModulation(frameParams, modAmount, pid);
            }
        }

        float mix = 0.0f;
        int renderedCount = 0;

        // Mono mode
        int activeMonoPitch = -1;
        if (frameParams.synthMono >= 0.5f) {
            for (int ni = noteCount - 1; ni >= 0; --ni) {
                double elapsedSec = 0.0, noteDurSec = 0.0;
                bool inRelease = false;
                if (isNoteAudible(notes[ni], beat, bpm, ampReleaseSec,
                                  elapsedSec, noteDurSec, inRelease)) {
                    activeMonoPitch = notes[ni].pitch;
                    break;
                }
            }
        }

        for (int v = 0; v < kPhaseModMaxVoices; ++v) {
            auto& voice = runtime.voices[v];
            if (voice.active == 0) continue;

            if (frameParams.synthMono >= 0.5f && voice.pitch != activeMonoPitch) {
                if (activeMonoPitch >= 0) voice.active = 0;
                continue;
            }

            int ni = -1;
            for (int n = 0; n < noteCount; ++n) {
                if (notes[n].pitch == voice.pitch && notes[n].noteStartBeat == voice.startBeat &&
                    notes[n].clipStartBeat == voice.clipStartBeat) {
                    ni = n;
                    break;
                }
            }
            if (ni < 0) continue;

            const auto& note = notes[ni];
            double elapsedSec = 0.0, noteDurSec = 0.0;
            bool inRelease = false;
            if (!isNoteAudible(note, beat, bpm, ampReleaseSec,
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

            PhaseModSynthParams voiceParams = frameParams;
            float panelGain = perFramePanelGain != nullptr ? perFramePanelGain[frame] : 1.0f;
            float voiceLfoOut = 0.0f;
            if (instMod != nullptr) {
                const NoteModKey key =
                    noteModKeyFromRegion(note.pitch, note.clipStartBeat, note.noteStartBeat);
                const ModulationEvalContext evalCtx = instMod->evalContextForFrame(frame);
                DeviceVariantParams variant = voiceParams;
                applyPerNoteDspModulation(variant,
                                          DeviceNodeKind::PhaseModSynth,
                                          instMod->deviceIndex,
                                          elapsedSec,
                                          key,
                                          evalCtx,
                                          *instMod);
                if (const auto* modulated = std::get_if<PhaseModSynthParams>(&variant)) {
                    voiceParams = *modulated;
                }
                panelGain = applyPerNoteCommonGain(panelGain,
                                                   instMod->deviceIndex,
                                                   elapsedSec,
                                                   key,
                                                   evalCtx,
                                                   *instMod);
            }

            mix += phaseModVoiceSample(voice, voiceParams,
                                       ampGain * velGain,
                                       filterGain,
                                       sampleRate, glideCoeff, voiceLfoOut) *
                   voiceParams.gain * panelGain * kInstrumentOutputGain * voiceParams.masterVol;

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

void PhaseModSynthProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (ctx.suppressInstruments || ctx.noteCount <= 0) {
        return;
    }

    const int regionCount = ctx.noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : ctx.noteCount;
    for (int i = 0; i < regionCount; ++i) {
        const MidiPlaybackNote& note = ctx.notes[i];
        ctx.scratch.phaseModRegions[i] = PhaseModSynthMidiNoteRegion{
            note.pitch, note.pitch,
            note.clipStartBeat, note.clipLengthBeats,
            note.noteStartBeat, note.noteDurationBeats, note.velocity,
            note.loopContent, note.contentLengthBeats
        };
    }

    std::memset(ctx.scratch.scratch, 0, static_cast<size_t>(block.numSamples) * sizeof(float));

    auto& runtime = runtime_;
    const uint16_t di = static_cast<uint16_t>(ctx.deviceIndex);
    const bool hasAuto = nodeHasDspAutomation(di, ctx.automationClips, ctx.automationClipCount);
    const bool hasMod = ctx.lfoValues != nullptr && ctx.lfoCount > 0 &&
                        ctx.modEdges != nullptr && ctx.modEdgeCount > 0;
    const InstrumentModulationContext* instModPtr = nullptr;
    InstrumentModulationContext instMod;
    if (hasMod && ctx.modulators != nullptr) {
        instMod = ctx.instrumentModulation();
        instModPtr = &instMod;
    }
    const bool bakePanelGain = instModPtr != nullptr &&
        deviceHasPerNoteModEdges(di, ctx.modEdges, ctx.modEdgeCount, ctx.modulators, ctx.lfoCount);

    mixPhaseModMidiNotesBlock(ctx.scratch.scratch, block.numSamples, ctx.sampleRate, ctx.bpm, ctx.playheadBeat,
        ctx.scratch.phaseModRegions, regionCount,
        std::get<PhaseModSynthParams>(*ctx.modulatedParams), runtime,
        hasAuto ? ctx.automationClips : nullptr, hasAuto ? ctx.automationClipCount : 0,
        hasAuto ? &di : nullptr,
        hasMod ? ctx.lfoValues : nullptr, hasMod ? ctx.lfoCount : 0, hasMod ? block.numSamples : 0,
        hasMod ? ctx.modEdges : nullptr, hasMod ? ctx.modEdgeCount : 0,
        hasMod ? &di : nullptr,
        ctx.scratch.perFrameGain,
        instModPtr);

    StereoOutputPanel::applyFromScratch(ctx.scratch.scratch, block, block.numSamples,
                                         bakePanelGain ? nullptr : ctx.scratch.perFrameGain,
                                         ctx.scratch.perFramePan);
}

} // namespace audioapp
