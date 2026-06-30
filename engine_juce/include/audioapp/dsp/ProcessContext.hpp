#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/ModulationTypes.hpp"
#include "audioapp/modulation/IModulator.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"

namespace audioapp {

class WavetableBank;

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
    int numFrames = 0;

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