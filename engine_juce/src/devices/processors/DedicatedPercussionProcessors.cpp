#include "audioapp/devices/processors/DedicatedPercussionProcessors.hpp"

#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/devices/processors/ProcessorUtils.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {
namespace {

template <typename Params, typename Runtime, typename Trigger, typename SampleL,
          typename SampleR, typename Release, typename Velocity>
void processDedicated(AudioBlock& block, ProcessContext& ctx, Runtime& runtime,
                      const Params& params, int anchorPitch, Trigger trigger,
                      SampleL sampleL, SampleR sampleR, Release release,
                      Velocity velocityAmount) noexcept {
    if (ctx.suppressInstruments || ctx.noteCount <= 0) return;
    const int count = std::min(ctx.noteCount, kMaxInstrumentRegions);
    for (int i = 0; i < count; ++i) {
        const auto& n = ctx.notes[i];
        ctx.scratch.percussionRegions[i] = {n.pitch, i, n.clipStartBeat, n.clipLengthBeats,
            n.noteStartBeat, n.noteDurationBeats, n.velocity, n.loopContent, n.contentLengthBeats};
    }
    std::memset(ctx.scratch.tempStereoL, 0, static_cast<size_t>(block.numSamples) * sizeof(float));
    std::memset(ctx.scratch.tempStereoR, 0, static_cast<size_t>(block.numSamples) * sizeof(float));

    const uint16_t di = static_cast<uint16_t>(ctx.deviceIndex);
    const bool hasMod = ctx.lfoValues != nullptr && ctx.lfoCount > 0 &&
                        ctx.modEdges != nullptr && ctx.modEdgeCount > 0;
    InstrumentModulationContext instMod;
    const InstrumentModulationContext* instModPtr = nullptr;
    if (hasMod && ctx.modulators != nullptr) {
        instMod = ctx.instrumentModulation();
        instModPtr = &instMod;
    }
    const float releaseSec = release(params);

    for (int frame = 0; frame < block.numSamples; ++frame) {
        const double beat = ctx.playheadBeat + static_cast<double>(frame) / ctx.sampleRate * ctx.bpm / 60.0;
        int activeKey = -1, activeIndex = -1, pitch = anchorPitch;
        float noteVelocity = 100.0f;
        double elapsed = 0.0;
        for (int i = 0; i < count; ++i) {
            const auto& n = ctx.scratch.percussionRegions[i];
            const double looped = beatWithinClipContent(beat, n.clipStartBeat, n.clipLengthBeats,
                                                        n.contentLengthBeats, n.loopContent);
            if (looped < n.noteStartBeat) continue;
            const double end = n.noteStartBeat + n.noteDurationBeats + releaseSec * ctx.bpm / 60.0;
            if (looped >= end) continue;
            activeKey = n.noteKey; activeIndex = i; pitch = n.pitch; noteVelocity = n.velocity;
            elapsed = (looped - n.noteStartBeat) * 60.0 / ctx.bpm;
        }
        if (activeKey < 0) { runtime.voice.active = 0; runtime.lastNoteKey = -1; continue; }
        if (runtime.lastNoteKey != activeKey || runtime.voice.active == 0) {
            trigger(runtime.voice, pitch, noteVelocity);
            runtime.lastNoteKey = activeKey;
        }
        runtime.voice.elapsedSec = elapsed;
        const float vel = std::clamp(noteVelocity / 127.0f, 0.0f, 1.0f);
        const float velocityGain = 1.0f - velocityAmount(params) * (1.0f - vel);
        float gain = ctx.commonControls.gainAt(frame);
        if (instModPtr != nullptr && activeIndex >= 0) {
            const auto& n = ctx.scratch.percussionRegions[activeIndex];
            gain = applyPerNoteCommonGain(gain, di, elapsed, -1.0,
                noteModKeyFromRegion(n.pitch, n.clipStartBeat, n.noteStartBeat),
                instModPtr->evalContextForFrame(frame), *instModPtr);
        }
        ctx.scratch.tempStereoL[frame] += sampleL(runtime.voice, params, ctx.sampleRate, velocityGain) * gain;
        ctx.scratch.tempStereoR[frame] += sampleR(runtime.voice, params, ctx.sampleRate, velocityGain) * gain;
    }

    for (int f = 0; f < block.numSamples; ++f) {
        const float angle = std::clamp(ctx.commonControls.panAt(f), 0.0f, 1.0f) * 1.57079632679f;
        constexpr float kCenter = 1.41421356237f;
        block.channelL[f] += ctx.scratch.tempStereoL[f] * std::cos(angle) * kCenter;
        block.channelR[f] += ctx.scratch.tempStereoR[f] * std::sin(angle) * kCenter;
    }
}

} // namespace

void HihatProcessor::process(AudioBlock& b, ProcessContext& c) noexcept {
    processDedicated(b, c, runtime_, std::get<HihatGeneratorParams>(*c.modulatedParams), 42,
        triggerHihatVoice, hihatSampleL, hihatSampleR, hihatReleaseSeconds,
        [](const auto& p) { return p.hihatVelocity; });
}
void RideProcessor::process(AudioBlock& b, ProcessContext& c) noexcept {
    processDedicated(b, c, runtime_, std::get<RideGeneratorParams>(*c.modulatedParams), 51,
        triggerRideVoice, rideSampleL, rideSampleR, rideReleaseSeconds,
        [](const auto& p) { return p.rideVelocity; });
}
void TomProcessor::process(AudioBlock& b, ProcessContext& c) noexcept {
    processDedicated(b, c, runtime_, std::get<TomGeneratorParams>(*c.modulatedParams), 45,
        triggerTomVoice, tomSampleL, tomSampleR, tomReleaseSeconds,
        [](const auto& p) { return p.tomVelocity; });
}
void RimshotProcessor::process(AudioBlock& b, ProcessContext& c) noexcept {
    processDedicated(b, c, runtime_, std::get<RimshotGeneratorParams>(*c.modulatedParams), 37,
        triggerRimshotVoice, rimshotSampleL, rimshotSampleR, rimshotReleaseSeconds,
        [](const auto& p) { return p.rimshotVelocity; });
}

} // namespace audioapp
