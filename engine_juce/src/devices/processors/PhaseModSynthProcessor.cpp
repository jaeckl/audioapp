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

static PhaseModSynthParams heldPhaseModParamsAtFrame(
    const PhaseModSynthParams& base,
    int heldFrame,
    double blockStartBeat,
    double sampleRate,
    int bpm,
    bool useAutomation,
    const AutomationClipPlayback* automationClips,
    int automationClipCount,
    const uint16_t* automationDeviceIndex,
    uint64_t automationTargetNodeId,
    bool useModulation,
    const float* lfoValues,
    int lfoCount,
    int lfoStride,
    const ModulationEdgePlayback* modEdges,
    int modEdgeCount,
    const uint16_t* modulationDeviceIndex,
    uint64_t modulationTargetNodeId,
    const InstrumentModulationContext* instMod) noexcept {
    PhaseModSynthParams held = base;
    const double beat = beatAtFrame(blockStartBeat, heldFrame, sampleRate, bpm);
    if (useAutomation) {
        DeviceVariantParams variant = held;
        applyDspAutomationAtBeat(variant,
                                 DeviceNodeKind::PhaseModSynth,
                                 automationTargetNodeId,
                                 *automationDeviceIndex,
                                 beat,
                                 automationClips,
                                 automationClipCount);
        if (const auto* automated = std::get_if<PhaseModSynthParams>(&variant)) {
            held = *automated;
        }
    }
    if (useModulation && instMod != nullptr) {
        DeviceVariantParams variant = held;
        applyGlobalDspModulationAtFrame(variant,
                                        DeviceNodeKind::PhaseModSynth,
                                        instMod->deviceIndex,
                                        heldFrame,
                                        lfoStride,
                                        *instMod);
        if (const auto* modulated = std::get_if<PhaseModSynthParams>(&variant)) {
            held = *modulated;
        }
    } else if (useModulation) {
        for (int e = 0; e < modEdgeCount; ++e) {
            const ModulationEdgePlayback& edge = modEdges[e];
            if (!playbackTargetMatches(edge.targetNodeId, edge.deviceIndex,
                                       modulationTargetNodeId,
                                       *modulationDeviceIndex)) continue;
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
            DeviceChainAutomationModulation::applyModulation(held, edge.amount * lfoOut, pid);
        }
    }
    return held;
}

static int resolveVoiceNoteIndex(const PhaseModSynthVoiceRuntime& voice,
                                 const PhaseModSynthMidiNoteRegion* notes,
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
                               const InstrumentModulationContext* instMod,
                               int voiceLimit,
                               bool retriggerReplacesVoice,
                               const CommonControlBlock* commonControls,
                               uint64_t automationTargetNodeId = 0,
                               uint64_t modulationTargetNodeId = 0) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }

    const int maxVoices = safe_clamp(voiceLimit, 1, kPhaseModMaxVoices);
    if (retriggerReplacesVoice && maxVoices == 1) {
        for (int v = 1; v < kPhaseModMaxVoices; ++v) runtime.voices[v].active = 0;
    }
    const bool useAutomation = automationClips != nullptr && automationClipCount > 0 &&
                               automationDeviceIndex != nullptr;
    const bool useModulation = lfoValues != nullptr && lfoCount > 0 && lfoStride > 0 &&
                               modEdges != nullptr && modEdgeCount > 0 &&
                               modulationDeviceIndex != nullptr;

    const double blockStartBeat = playheadStartBeat;
    const double blockEndBeat = blockStartBeat + static_cast<double>(numFrames) *
        (static_cast<double>(bpm) / 60.0) / sampleRate;

    const float ampReleaseSecAlloc = adsrNormalizedToSeconds(params.ampRelease, 3.0f);

    int allocatedVoices = 0;
    for (int ni = retriggerReplacesVoice && maxVoices == 1 ? noteCount - 1 : 0;
         ni >= 0 && ni < noteCount && allocatedVoices < maxVoices;
         ni += retriggerReplacesVoice && maxVoices == 1 ? -1 : 1) {
        if (!isNoteAudibleInBlock(notes[ni], blockStartBeat, numFrames, sampleRate, bpm,
                                  ampReleaseSecAlloc)) {
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
        const float glideMsAlloc = params.glideMs * 2000.0f;
        if (voice.pitch != notes[ni].pitch || voice.startBeat != notes[ni].noteStartBeat ||
            voice.clipStartBeat != notes[ni].clipStartBeat || noteOnsetInBlock) {
            const bool glideFromPreviousVoice = glideMsAlloc > 0.0f && voice.active != 0;
            const float previousHz = voice.currentHz;
            std::memset(&voice, 0, sizeof(voice));
            voice.active = 1;
            voice.pitch = notes[ni].pitch;
            voice.startBeat = notes[ni].noteStartBeat;
            voice.clipStartBeat = notes[ni].clipStartBeat;
            voice.noteKey = ni;
            voice.velocity = notes[ni].velocity;
            voice.targetHz = midiNoteToHz(notes[ni].pitch);
            voice.currentHz = glideFromPreviousVoice ? previousHz : voice.targetHz;
        } else {
            voice.active = 1;
            voice.noteKey = ni;
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

    const bool needsHeldParams = useAutomation || useModulation;

    auto renderFrame = [&](int frame, const PhaseModSynthParams& heldParams) {
        const float beat = beatAtFrame(blockStartBeat, frame, sampleRate, bpm);

        const float ampReleaseSec = adsrNormalizedToSeconds(heldParams.ampRelease, 3.0f);
        const float ampAttackSec = adsrNormalizedToSeconds(heldParams.ampAttack, 2.0f);
        const float ampDecaySec = adsrNormalizedToSeconds(heldParams.ampDecay, 2.0f);
        const float ampSustain = safe_clamp(heldParams.ampSustain, 0.0f, 1.0f);
        const float filterAttackSec = adsrNormalizedToSeconds(heldParams.filterAttack, 2.0f);
        const float filterDecaySec = adsrNormalizedToSeconds(heldParams.filterDecay, 2.0f);
        const float filterSustain = safe_clamp(heldParams.filterSustain, 0.0f, 1.0f);
        const float glideMs = heldParams.glideMs * 2000.0f;
        const float glideCoeff =
            glideMs > 0.0f
                ? 1.0f - std::exp(-1.0f / (static_cast<float>(sampleRate) * glideMs * 0.001f))
                : 1.0f;

        float mix = 0.0f;
        int renderedCount = 0;

        int activeMonoPitch = -1;
        if (heldParams.synthMono >= 0.5f) {
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

        for (int v = 0; v < maxVoices; ++v) {
            auto& voice = runtime.voices[v];
            if (voice.active == 0) continue;

            if (heldParams.synthMono >= 0.5f && voice.pitch != activeMonoPitch) {
                if (activeMonoPitch >= 0) voice.active = 0;
                continue;
            }

            int ni = resolveVoiceNoteIndex(voice, notes, noteCount);
            if (ni < 0) continue;
            if (ni != voice.noteKey) {
                voice.noteKey = ni;
            }

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

            const float filterGain = samplerAdsrGain(
                static_cast<float>(elapsedSec),
                static_cast<float>(noteDurSec),
                filterAttackSec,
                filterDecaySec,
                filterSustain,
                adsrNormalizedToSeconds(heldParams.filterRelease, 3.0f));
            const float vel = safe_clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
            const float velGain = 1.0f - heldParams.velocitySensitivity * (1.0f - vel);

            PhaseModSynthParams voiceParams = heldParams;
            float panelGain = commonControls != nullptr
                ? commonControls->gainAt(frame)
                : (perFramePanelGain != nullptr ? perFramePanelGain[frame] : 1.0f);
            if (instMod != nullptr) {
                const NoteModKey key =
                    noteModKeyFromRegion(note.pitch, note.clipStartBeat, note.noteStartBeat);
                const ModulationEvalContext evalCtx = instMod->evalContextForFrame(frame);
                DeviceVariantParams variant = voiceParams;
                applyPerNoteDspModulation(variant,
                                          DeviceNodeKind::PhaseModSynth,
                                          instMod->deviceIndex,
                                          elapsedSec,
                                          noteDurSec,
                                          key,
                                          evalCtx,
                                          *instMod);
                if (const auto* modulated = std::get_if<PhaseModSynthParams>(&variant)) {
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

            mix += phaseModVoiceSample(voice, voiceParams,
                                       ampGain * velGain,
                                       filterGain,
                                       sampleRate, glideCoeff, 0.0f) *
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
    };

    if (!needsHeldParams) {
        for (int frame = 0; frame < numFrames; ++frame) {
            renderFrame(frame, params);
        }
        return;
    }

    for (int sub = 0; sub < numFrames; sub += kPhaseModControlSubBlockFrames) {
        const PhaseModSynthParams heldParams = heldPhaseModParamsAtFrame(
            params,
            sub,
            blockStartBeat,
            sampleRate,
            bpm,
            useAutomation,
            automationClips,
            automationClipCount,
            automationDeviceIndex,
            nodeId,
            useModulation,
            lfoValues,
            lfoCount,
            lfoStride,
            modEdges,
            modEdgeCount,
            modulationDeviceIndex,
            nodeId,
            instMod);

        const int subLen = std::min(kPhaseModControlSubBlockFrames, numFrames - sub);
        for (int frame = sub; frame < sub + subLen; ++frame) {
            renderFrame(frame, heldParams);
        }
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
            note.pitch, i,
            note.clipStartBeat, note.clipLengthBeats,
            note.noteStartBeat, note.noteDurationBeats, note.velocity,
            note.loopContent, note.contentLengthBeats
        };
    }

    std::memset(ctx.scratch.scratch, 0, static_cast<size_t>(block.numSamples) * sizeof(float));

    auto& runtime = runtime_;
    const uint16_t di = static_cast<uint16_t>(ctx.deviceIndex);
    const uint64_t nodeId =
        ctx.processorNodeId != 0 ? ctx.processorNodeId : stableProcessorNodeId;
    const bool hasAuto =
        nodeHasDspAutomation(nodeId, di, ctx.automationClips, ctx.automationClipCount);
    const bool hasMod = ctx.lfoValues != nullptr && ctx.lfoCount > 0 &&
                        ctx.modEdges != nullptr && ctx.modEdgeCount > 0;
    const InstrumentModulationContext* instModPtr = nullptr;
    InstrumentModulationContext instMod;
    if (hasMod && ctx.modulators != nullptr) {
        instMod = ctx.instrumentModulation();
        instModPtr = &instMod;
    }
    const bool bakePanelGain = instModPtr != nullptr &&
        deviceHasPerNoteModEdges(nodeId, di, ctx.modEdges, ctx.modEdgeCount,
                                 ctx.modulators, ctx.lfoCount);

    mixPhaseModMidiNotesBlock(ctx.scratch.scratch, block.numSamples, ctx.sampleRate, ctx.bpm, ctx.playheadBeat,
        ctx.scratch.phaseModRegions, regionCount,
        std::get<PhaseModSynthParams>(*ctx.modulatedParams), runtime,
        hasAuto ? ctx.automationClips : nullptr, hasAuto ? ctx.automationClipCount : 0,
        hasAuto ? &di : nullptr,
        hasMod ? ctx.lfoValues : nullptr, hasMod ? ctx.lfoCount : 0, hasMod ? block.numSamples : 0,
        hasMod ? ctx.modEdges : nullptr, hasMod ? ctx.modEdgeCount : 0,
        hasMod ? &di : nullptr,
        nullptr,
        instModPtr,
        ctx.voicePolicy.maxVoices > 0 ? ctx.voicePolicy.maxVoices : kPhaseModMaxVoices,
        ctx.voicePolicy.retriggerReplacesVoice,
        bakePanelGain ? &ctx.commonControls : nullptr,
        nodeId,
        nodeId);

    StereoOutputPanel::applyFromScratch(ctx.scratch.scratch, block, block.numSamples,
                                        ctx.commonControls, !bakePanelGain);
}

} // namespace audioapp
