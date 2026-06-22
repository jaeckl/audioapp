#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"

namespace audioapp {
namespace test {

/// Convenience wrapper for tests — builds arena, sets up context, runs orchestrator.
/// Uses thread_local arena/scratch so tests don't need to manage them.
inline void processTestChain(
    float* trackLeft, float* trackRight, int numFrames,
    double sampleRate, int bpm, double playheadStartBeat,
    const MidiPlaybackNote* notes, int noteCount,
    const DeviceNodePlayback* devices, int deviceCount,
    bool suppressInstruments = false,
    DeviceMeterAtomic* deviceMeters = nullptr, int maxDeviceMeters = 0,
    const float* lfoValues = nullptr, int lfoCount = 0,
    const ModulationEdgePlayback* modEdges = nullptr, int modEdgeCount = 0,
    const AutomationClipPlayback* automationClips = nullptr, int automationClipCount = 0) noexcept
{
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 ||
        devices == nullptr || deviceCount <= 0) return;
    thread_local ProcessorArena arena;
    thread_local DeviceChainScratch scratch;
    constexpr int kScratchFrames = 4096;
    const int framesToProcess = numFrames > kScratchFrames ? kScratchFrames : numFrames;
    buildProcessorChain(devices, deviceCount, arena);
    DeviceChainOrchestrator::Context ctx(arena, scratch);
    ctx.trackLeft = trackLeft;
    ctx.trackRight = trackRight;
    ctx.numFrames = framesToProcess;
    ctx.sampleRate = sampleRate;
    ctx.bpm = bpm;
    ctx.playheadStartBeat = playheadStartBeat;
    ctx.notes = notes;
    ctx.noteCount = noteCount;
    ctx.suppressInstruments = suppressInstruments;
    ctx.deviceMeters = deviceMeters;
    ctx.maxDeviceMeters = maxDeviceMeters;
    ctx.lfoValues = lfoValues;
    ctx.lfoCount = lfoCount;
    ctx.modEdges = modEdges;
    ctx.modEdgeCount = modEdgeCount;
    ctx.automationClips = automationClips;
    ctx.automationClipCount = automationClipCount;
    DeviceChainOrchestrator::processChain(ctx);
}

} // namespace test
} // namespace audioapp