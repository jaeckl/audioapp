#pragma once

#include <cstdint>

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/modulation/IModulator.hpp"
#include "audioapp/modulation/ModulationGraph.hpp"
#include "audioapp/modulation/RandomGeneratorModulator.hpp"
#include "audioapp/modulation/SequencerModulator.hpp"

namespace audioapp {

/// Stable identity for one MIDI note event (per-note mod instance, not per voice).
struct NoteModKey {
    int pitch = 60;
    double clipStartBeat = 0.0;
    double noteStartBeat = 0.0;

    bool operator==(const NoteModKey& other) const noexcept {
        return pitch == other.pitch
            && clipStartBeat == other.clipStartBeat
            && noteStartBeat == other.noteStartBeat;
    }
};

inline NoteModKey noteModKeyFromMidi(const MidiPlaybackNote& note) noexcept {
    return NoteModKey{note.pitch, note.clipStartBeat, note.noteStartBeat};
}

inline NoteModKey noteModKeyFromRegion(int pitch, double clipStartBeat, double noteStartBeat) noexcept {
    return NoteModKey{pitch, clipStartBeat, noteStartBeat};
}

constexpr int kMaxPerNoteModEntries = 32;

struct PerNoteModEntry {
    NoteModKey key{};
    bool inUse = false;
    RandomGeneratorModulator::NoteRuntimeState random[ModulationGraph::kMaxLfos]{};
    SequencerModulator::NoteRuntimeState sequencer[ModulationGraph::kMaxLfos]{};
};

struct PerNoteModCache {
    PerNoteModEntry entries[kMaxPerNoteModEntries]{};

    void reset() noexcept {
        for (auto& entry : entries) {
            entry.inUse = false;
        }
    }

    PerNoteModEntry* findOrAlloc(const NoteModKey& key) noexcept;
};

/// Transport + frame context for modulator evaluation.
struct ModulationEvalContext {
    double playheadBeat = 0.0;
    int bpm = 120;
    double sampleRate = 48000.0;
    double playheadSeconds = 0.0;
    int frameIndex = 0;
    int numFrames = 0;
    uint32_t retriggerGeneration = 0;
};

/// Bundled modulation inputs passed into instrument mix functions.
struct InstrumentModulationContext {
    const float* lfoValues = nullptr;
    int lfoCount = 0;
    int lfoStride = 0;
    const ModulationEdgePlayback* modEdges = nullptr;
    int modEdgeCount = 0;
    uint16_t deviceIndex = 0;
    IModulator* const* modulators = nullptr;
    uint32_t retriggerGeneration = 0;
    double playheadStartBeat = 0.0;
    int bpm = 120;
    double sampleRate = 48000.0;
    PerNoteModCache* noteCache = nullptr;

    ModulationEvalContext evalContextForFrame(int frameIndex) const noexcept;
};

bool modulatorUsesPerNoteClock(const IModulator* mod) noexcept;

bool deviceHasPerNoteModEdges(uint16_t deviceIndex,
                              const ModulationEdgePlayback* modEdges,
                              int modEdgeCount,
                              IModulator* const* modulators,
                              int modulatorCount) noexcept;

float evaluateModulatorForNote(IModulator* mod,
                               int modPlaybackIndex,
                               const NoteModKey& key,
                               double noteElapsedSeconds,
                               const ModulationEvalContext& ctx,
                               PerNoteModCache& cache) noexcept;

float evaluateGlobalModulator(IModulator* mod,
                              int modPlaybackIndex,
                              const ModulationEvalContext& ctx,
                              const float* lfoValues,
                              int lfoStride) noexcept;

float applyPerNoteCommonGain(float baseGain,
                             uint16_t deviceIndex,
                             double noteElapsedSeconds,
                             const NoteModKey& key,
                             const ModulationEvalContext& ctx,
                             const InstrumentModulationContext& modCtx) noexcept;

float applyPerNoteCommonPan(float basePan,
                            uint16_t deviceIndex,
                            double noteElapsedSeconds,
                            const NoteModKey& key,
                            const ModulationEvalContext& ctx,
                            const InstrumentModulationContext& modCtx) noexcept;

void applyGlobalDspModulationAtFrame(DeviceVariantParams& params,
                                     DeviceNodeKind kind,
                                     uint16_t deviceIndex,
                                     int lfoFrame,
                                     int framesToProcess,
                                     const InstrumentModulationContext& modCtx) noexcept;

void applyPerNoteDspModulation(DeviceVariantParams& params,
                               DeviceNodeKind kind,
                               uint16_t deviceIndex,
                               double noteElapsedSeconds,
                               const NoteModKey& key,
                               const ModulationEvalContext& ctx,
                               const InstrumentModulationContext& modCtx) noexcept;

} // namespace audioapp
