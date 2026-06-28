#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"
#include "audioapp/dsp/AudioBlock.hpp"
#include "audioapp/dsp/ProcessContext.hpp"
#include "audioapp/WavetableBank.hpp"
#include "audioapp/ProcessorGraph.hpp"

namespace audioapp {

struct DeviceChainOrchestrator {

    /// Bridge context — holds everything the orchestrator loop needs.
    struct Context {
        float* trackLeft = nullptr;
        float* trackRight = nullptr;
        int numFrames = 0;
        double sampleRate = 48000.0;
        int bpm = 120;
        double playheadStartBeat = 0.0;
        const MidiPlaybackNote* notes = nullptr;
        int noteCount = 0;
        ProcessorArena& arena;
        DeviceChainScratch& scratch;
        bool suppressInstruments = false;
        DeviceMeterAtomic* deviceMeters = nullptr;
        int maxDeviceMeters = 0;
        const float* lfoValues = nullptr;
        int lfoCount = 0;
        const ModulationEdgePlayback* modEdges = nullptr;
        int modEdgeCount = 0;
        const AutomationClipPlayback* automationClips = nullptr;
        int automationClipCount = 0;
        const WavetableBank* wavetableBank = nullptr;
        const ProcessorGraphSnapshot* graph = nullptr;
        int graphTrackIndex = -1;
        float* graphAudioLeft = nullptr;
        float* graphAudioRight = nullptr;
        int graphAudioStride = 0;
        const MidiPlaybackNote* graphMidiNotes = nullptr;
        const int* graphMidiCounts = nullptr;
        int graphMidiStride = 0;

        Context(ProcessorArena& ar, DeviceChainScratch& s) noexcept
            : arena(ar), scratch(s) {}
    };

    /// Main orchestrator loop — replaces the switch-case in processDeviceNode.
    static void processChain(Context& ctx) noexcept;

    /// Apply common gain/pan LFO modulation to per-frame arrays.
    static void applyCommonGainPanLfo(
        DeviceChainScratch& scratch,
        uint16_t deviceIndex,
        int framesToProcess,
        const float* lfoValues, int lfoCount,
        const ModulationEdgePlayback* modEdges, int modEdgeCount) noexcept;
};

/// Build processors in the arena from a device chain snapshot.
/// Called on the control thread.
/// Returns the number of processors emplaced.
int buildProcessorChain(
    const DeviceNodePlayback* devices,
    int deviceCount,
    ProcessorArena& arena) noexcept;

} // namespace audioapp
