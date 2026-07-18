#pragma once

#include <cstdint>

#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/ModulationTypes.hpp"
#include "audioapp/modulation/IModulator.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"

namespace audioapp {

class WavetableBank;
struct ProcessorGraphSnapshot;
struct GraphTapRuntime;

enum class CommonControlMode : uint8_t {
    Constant,
    Ramp,
    Dynamic,
};

/// Block-local execution descriptor for the common device-strip controls.
/// Constant controls carry no per-frame buffer. Ramp controls interpolate only
/// for the callback in which a manual target changes. Dynamic controls point to
/// the preallocated scratch arrays populated by automation and modulation.
struct CommonControlBlock {
    CommonControlMode gainMode = CommonControlMode::Constant;
    CommonControlMode panMode = CommonControlMode::Constant;
    float gainStart = 1.0f;
    float gainEnd = 1.0f;
    float panStart = 0.5f;
    float panEnd = 0.5f;
    const float* gainValues = nullptr;
    const float* panValues = nullptr;
    int numFrames = 0;

    float gainAt(int frame) const noexcept {
        if (gainMode == CommonControlMode::Dynamic && gainValues != nullptr)
            return gainValues[frame];
        if (gainMode == CommonControlMode::Ramp && numFrames > 0)
            return gainStart + (gainEnd - gainStart) *
                (static_cast<float>(frame + 1) / static_cast<float>(numFrames));
        return gainEnd;
    }

    float panAt(int frame) const noexcept {
        if (panMode == CommonControlMode::Dynamic && panValues != nullptr)
            return panValues[frame];
        if (panMode == CommonControlMode::Ramp && numFrames > 0)
            return panStart + (panEnd - panStart) *
                (static_cast<float>(frame + 1) / static_cast<float>(numFrames));
        return panEnd;
    }
};

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
    InstrumentVoicePolicy voicePolicy{};

    DeviceMeterAtomic* deviceMeters = nullptr;
    int maxDeviceMeters = 0;
    const bool* meterSlotSubscribed = nullptr;

    const ProcessorGraphSnapshot* tapGraph = nullptr;
    GraphTapRuntime* graphTapRuntimes = nullptr;
    int graphTapRuntimeCount = 0;

    int deviceIndex = 0;
    bool needsSubBlocks = false;
    int numFrames = 0;
    CommonControlBlock commonControls{};

    const DeviceVariantParams* modulatedParams = nullptr;
    const WavetableBank* wavetableBank = nullptr;

    IModulator* const* modulators = nullptr;
    uint32_t retriggerGeneration = 0;

    explicit ProcessContext(DeviceChainScratch& s) noexcept : scratch(s) {}

    InstrumentModulationContext instrumentModulation() const noexcept {
        InstrumentModulationContext out;
        out.lfoValues = lfoValues;
        out.lfoCount = lfoCount;
        out.lfoStride = numFrames > 0 ? numFrames : 0;
        out.modEdges = modEdges;
        out.modEdgeCount = modEdgeCount;
        out.deviceIndex = static_cast<uint16_t>(deviceIndex);
        out.modulators = modulators;
        out.retriggerGeneration = retriggerGeneration;
        out.playheadStartBeat = playheadBeat;
        out.bpm = bpm;
        out.sampleRate = sampleRate;
        out.noteCache = &scratch.perNoteModCache;
        return out;
    }
};

} // namespace audioapp
