#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/ModulationTypes.hpp"

namespace audioapp {

struct ProcessContext {
    DeviceChainScratch& scratch;

    const float* lfoValues = nullptr;
    int lfoCount = 0;

    const ModulationEdgePlayback* modEdges = nullptr;
    int modEdgeCount = 0;

    const AutomationClipPlayback* automationClips = nullptr;
    int automationClipCount = 0;

    const MidiPlaybackNote* notes = nullptr;
    int noteCount = 0;

    double playheadBeat = 0.0;
    int bpm = 120;
    double sampleRate = 48000.0;

    bool suppressInstruments = false;

    DeviceMeterAtomic* deviceMeters = nullptr;
    int maxDeviceMeters = 0;

    int deviceIndex = 0;
    bool needsSubBlocks = false;

    const DeviceVariantParams* modulatedParams = nullptr;

    explicit ProcessContext(DeviceChainScratch& s) noexcept : scratch(s) {}
};

} // namespace audioapp