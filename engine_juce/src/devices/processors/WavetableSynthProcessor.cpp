#include "audioapp/devices/processors/WavetableSynthProcessor.hpp"
#include "audioapp/WavetableSynthAlgorithm.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include <algorithm>
#include <cmath>
#include <cstring>
#ifdef __ANDROID__
#include <android/log.h>
#define WT_LOG(...) __android_log_print(ANDROID_LOG_INFO, "audioapp_engine", __VA_ARGS__)
#else
#define WT_LOG(...) ((void)0)
#endif

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

void WavetableSynthProcessor::initParams(const DeviceVariantParams& params) noexcept {
    DeviceProcessor::initParams(params);
    if (const auto* wt = std::get_if<WavetableSynthParams>(&params)) {
        realtimeWtPosition_.store(safe_clamp(wt->wtPosition, 0.0f, 1.0f), std::memory_order_release);
        realtimeWtPositionValid_.store(true, std::memory_order_release);
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

namespace {

bool isWtPositionParam(uint16_t paramId) noexcept {
    if (paramId == static_cast<uint16_t>(WavetableParam::WtPosition)) return true;
    return unpackParamKind(paramId) == ParamKind::WavetableSynth &&
           unpackParamId(paramId) == static_cast<uint16_t>(WavetableParam::WtPosition);
}

bool blockHasWtPositionAutomation(uint16_t deviceIndex,
                                  const AutomationClipPlayback* clips,
                                  int clipCount) noexcept {
    if (clips == nullptr || clipCount <= 0) return false;
    for (int i = 0; i < clipCount; ++i) {
        if (clips[i].deviceIndex == deviceIndex && isWtPositionParam(clips[i].localParamId)) {
            return true;
        }
    }
    return false;
}

bool blockHasWtPositionModulation(uint16_t deviceIndex,
                                  const ModulationEdgePlayback* edges,
                                  int edgeCount) noexcept {
    if (edges == nullptr || edgeCount <= 0) return false;
    for (int i = 0; i < edgeCount; ++i) {
        if (edges[i].deviceIndex == deviceIndex && isWtPositionParam(edges[i].localParamId)) {
            return true;
        }
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
    auto params = std::get<WavetableSynthParams>(*ctx.modulatedParams);
    const uint16_t di = static_cast<uint16_t>(ctx.deviceIndex);
    if (realtimeWtPositionValid_.load(std::memory_order_acquire) &&
        !blockHasWtPositionAutomation(di, ctx.automationClips, ctx.automationClipCount) &&
        !blockHasWtPositionModulation(di, ctx.modEdges, ctx.modEdgeCount)) {
        params.wtPosition = realtimeWtPosition_.load(std::memory_order_acquire);
    }
    const auto& wtId = params.wavetableId;
    if (ctx.wavetableBank != nullptr) {
        int bankIdx = -1;
        if (!wtId.empty()) {
            bankIdx = ctx.wavetableBank->findByName(wtId);
        }
        if (bankIdx < 0) {
            bankIdx = 0;
        }
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
            note.pitch, note.pitch,
            note.clipStartBeat, note.clipLengthBeats,
            note.noteStartBeat, note.noteDurationBeats, note.velocity
        };
    }

    std::memset(ctx.scratch.scratch, 0, static_cast<size_t>(block.numSamples) * sizeof(float));

    auto& runtime = runtime_;
    const bool hasAuto = nodeHasDspAutomation(di, ctx.automationClips, ctx.automationClipCount);
    const bool hasMod = ctx.lfoValues != nullptr && ctx.lfoCount > 0 &&
                        ctx.modEdges != nullptr && ctx.modEdgeCount > 0 &&
                        DeviceChainAutomationModulation::nodeHasDspModulation(di, ctx.modEdges, ctx.modEdgeCount);

    mixWavetableMidiNotesBlock(ctx.scratch.scratch, block.numSamples, ctx.sampleRate, ctx.bpm, ctx.playheadBeat,
        ctx.scratch.wavetableRegions, regionCount,
        params, runtime,
        pcmData, pcmFrameCount, pcmFrameLength,
        hasAuto ? ctx.automationClips : nullptr, hasAuto ? ctx.automationClipCount : 0,
        hasAuto ? &di : nullptr,
        hasMod ? ctx.lfoValues : nullptr, hasMod ? ctx.lfoCount : 0, hasMod ? block.numSamples : 0,
        hasMod ? ctx.modEdges : nullptr, hasMod ? ctx.modEdgeCount : 0,
        hasMod ? &di : nullptr);

    StereoOutputPanel::applyFromScratch(ctx.scratch.scratch, block, block.numSamples,
                                         ctx.scratch.perFrameGain, ctx.scratch.perFramePan);
}

} // namespace audioapp
