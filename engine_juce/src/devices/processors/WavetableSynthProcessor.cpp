#include "audioapp/devices/processors/WavetableSynthProcessor.hpp"
#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/WavetableSynthAlgorithm.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/AutomationPlayback.hpp"
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

} // anonymous namespace

void WavetableSynthProcessor::initParams(const DeviceVariantParams& params) noexcept {
    DeviceProcessor::initParams(params);
    if (const auto* wt = std::get_if<WavetableSynthParamsPlayback>(&params)) {
        realtimeWtPosition_.store(safe_clamp(wt->wtPosition, 0.0f, 1.0f), std::memory_order_release);
        realtimeWtPositionValid_.store(true, std::memory_order_release);
        runtime_.wavetableIndex = wt->wavetableIndex;
    }
}

bool WavetableSynthProcessor::setRealtimeParameter(std::string_view parameterId, float value) noexcept {
    if (parameterId == "wtPosition") {
        realtimeWtPosition_.store(safe_clamp(value, 0.0f, 1.0f), std::memory_order_release);
        realtimeWtPositionValid_.store(true, std::memory_order_release);
        return true;
    }
    return false;
}

void WavetableSynthProcessor::resetPlaybackState() noexcept {
    const int bankIdx = runtime_.wavetableIndex;
    const float smoothedWt = runtime_.smoothedWtPosition;
    const uint8_t wtInit = runtime_.wtPositionSmoothingInitialized;
    runtime_ = WavetableSynthRuntime{};
    runtime_.wavetableIndex = bankIdx;
    runtime_.smoothedWtPosition = smoothedWt;
    runtime_.wtPositionSmoothingInitialized = wtInit;
}

namespace {

bool isWtPositionParam(uint16_t paramId) noexcept {
    if (paramId == static_cast<uint16_t>(WavetableParam::WtPosition)) return true;
    return unpackParamKind(paramId) == ParamKind::WavetableSynth &&
           unpackParamId(paramId) == static_cast<uint16_t>(WavetableParam::WtPosition);
}

bool blockHasWtPositionAutomation(uint64_t processorNodeId,
                                  uint16_t processorIndex,
                                  const AutomationClipPlayback* clips,
                                  int clipCount) noexcept {
    if (clips == nullptr || clipCount <= 0) return false;
    for (int i = 0; i < clipCount; ++i) {
        if (!playbackTargetMatches(clips[i].targetNodeId, clips[i].deviceIndex,
                                   processorNodeId, processorIndex) ||
            !isWtPositionParam(clips[i].localParamId)) {
            continue;
        }
        return true;
    }
    return false;
}

bool blockHasWtPositionModulation(uint64_t processorNodeId,
                                  uint16_t processorIndex,
                                  const ModulationEdgePlayback* edges,
                                  int edgeCount) noexcept {
    if (edges == nullptr || edgeCount <= 0) return false;
    for (int i = 0; i < edgeCount; ++i) {
        if (!playbackTargetMatches(edges[i].targetNodeId, edges[i].deviceIndex,
                                   processorNodeId, processorIndex) ||
            !isWtPositionParam(edges[i].localParamId)) {
            continue;
        }
        return true;
    }
    return false;
}

} // anonymous namespace

void WavetableSynthProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (ctx.suppressInstruments || ctx.noteCount <= 0 || ctx.modulatedParams == nullptr) {
        return;
    }

    // Resolve wavetable PCM data from bank
    int pcmFrameCount = 0;
    int pcmFrameLength = 0;
    const float* pcmData = nullptr;
    auto params = wavetableRealtimeParams(
        std::get<WavetableSynthParamsPlayback>(*ctx.modulatedParams));
    const uint16_t di = static_cast<uint16_t>(ctx.deviceIndex);
    const uint64_t nodeId =
        ctx.processorNodeId != 0 ? ctx.processorNodeId : stableProcessorNodeId;
    if (realtimeWtPositionValid_.load(std::memory_order_acquire) &&
        !blockHasWtPositionAutomation(nodeId, di, ctx.automationClips, ctx.automationClipCount) &&
        !blockHasWtPositionModulation(nodeId, di, ctx.modEdges, ctx.modEdgeCount)) {
        params.wtPosition = realtimeWtPosition_.load(std::memory_order_acquire);
    }
    if (ctx.wavetableBank != nullptr) {
        int bankIdx = runtime_.wavetableIndex;
        if (bankIdx < 0) bankIdx = params.wavetableIndex;
        if (bankIdx < 0) bankIdx = 0;
        runtime_.wavetableIndex = bankIdx;
        const auto* entry = ctx.wavetableBank->get(bankIdx);
        if (entry != nullptr && !entry->pcm.empty()) {
            pcmData = entry->pcm.data();
            pcmFrameCount = entry->frameCount;
            pcmFrameLength = entry->frameLength;
        }
    }
    if (pcmData == nullptr) {
        return;
    }

    const int regionCount = ctx.noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : ctx.noteCount;
    for (int i = 0; i < regionCount; ++i) {
        const MidiPlaybackNote& note = ctx.notes[i];
        ctx.scratch.wavetableRegions[i] = WavetableMidiNoteRegion{
            note.pitch, i,
            note.clipStartBeat, note.clipLengthBeats,
            note.noteStartBeat, note.noteDurationBeats, note.velocity,
            note.loopContent, note.contentLengthBeats
        };
    }

    std::memset(ctx.scratch.scratch, 0, static_cast<size_t>(block.numSamples) * sizeof(float));

    auto& runtime = runtime_;
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

    mixWavetableMidiNotesBlock(ctx.scratch.scratch, block.numSamples, ctx.sampleRate, ctx.bpm, ctx.playheadBeat,
        ctx.scratch.wavetableRegions, regionCount,
        params, runtime,
        pcmData, pcmFrameCount, pcmFrameLength,
        hasAuto ? ctx.automationClips : nullptr, hasAuto ? ctx.automationClipCount : 0,
        hasAuto ? &di : nullptr,
        hasMod ? ctx.lfoValues : nullptr, hasMod ? ctx.lfoCount : 0, hasMod ? block.numSamples : 0,
        hasMod ? ctx.modEdges : nullptr, hasMod ? ctx.modEdgeCount : 0,
        hasMod ? &di : nullptr,
        nullptr,
        instModPtr,
        ctx.voicePolicy.maxVoices > 0 ? ctx.voicePolicy.maxVoices : kWavetableMaxVoices,
        ctx.voicePolicy.retriggerReplacesVoice,
        bakePanelGain ? &ctx.commonControls : nullptr,
        nodeId);

    const float spread = safe_clamp(params.wtStereoSpread, 0.0f, 1.0f);
    if (spread > 1.0e-4f) {
        constexpr float kPiOver2 = 1.57079632679f;
        for (int f = 0; f < block.numSamples; ++f) {
            const float gain = bakePanelGain ? 1.0f : ctx.commonControls.gainAt(f);
            const float sample = ctx.scratch.scratch[f] * gain;
            const int delayIdx = runtime.spreadWrite;
            const float delayed = runtime.spreadDelay[delayIdx];
            runtime.spreadDelay[delayIdx] = sample;
            runtime.spreadWrite =
                (runtime.spreadWrite + 1) % WavetableSynthRuntime::kSpreadDelayLen;
            const float angle =
                safe_clamp(ctx.commonControls.panAt(f), 0.0f, 1.0f) * kPiOver2;
            const float mid = sample * (1.0f - 0.35f * spread);
            const float side = delayed * spread * 0.55f;
            block.channelL[f] += mid * std::cos(angle) + side;
            block.channelR[f] += mid * std::sin(angle) - side;
        }
    } else {
        StereoOutputPanel::applyFromScratch(ctx.scratch.scratch, block, block.numSamples,
                                            ctx.commonControls, !bakePanelGain);
    }
}

} // namespace audioapp
