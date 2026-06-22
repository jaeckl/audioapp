#pragma once

#include <cstdint>

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainScratch.hpp"

namespace audioapp::DeviceChainProcessor {

void applyCommonGainPanLfo(
    DeviceChainScratch& scratch,
    uint16_t deviceIndex,
    int framesToProcess,
    const float* lfoValues, int lfoCount,
    const ModulationEdgePlayback* modEdges, int modEdgeCount) noexcept;

void processDeviceNode(
    const DeviceNodePlayback& node,
    int deviceIndex,
    float* trackLeft, float* trackRight,
    int framesToProcess,
    double sampleRate, int bpm, double playheadStartBeat,
    const MidiPlaybackNote* notes, int noteCount,
    const DeviceVariantParams& modulatedParams,
    bool needsSubBlocks,
    bool suppressInstruments,
    DeviceChainScratch& scratch,
    float& oscillatorPhase,
    BiquadState* samplerFilterStates,
    SubtractiveSynthRuntime* subtractiveRuntimes,
    KickGeneratorRuntime* kickRuntimes,
    SnareGeneratorRuntime* snareRuntimes,
    ClapGeneratorRuntime* clapRuntimes,
    CymbalGeneratorRuntime* cymbalRuntimes,
    CrashGeneratorRuntime* crashRuntimes,
    PhaseModSynthRuntime* phaseModRuntimes,
    DynamicsRuntime* dynamicsRuntimes,
    TimeBasedEffectRuntime* timeBasedRuntimes,
    DeviceMeterAtomic* deviceMeters, int maxDeviceMeters,
    const float* lfoValues, int lfoCount,
    const ModulationEdgePlayback* modEdges, int modEdgeCount,
    const AutomationClipPlayback* automationClips, int automationClipCount,
    FilterRuntime* filterRuntimes,
    FourBandEqRuntime* fourBandEqRuntimes,
    FrequencyShifterRuntime* frequencyShifterRuntimes) noexcept;

} // namespace audioapp::DeviceChainProcessor