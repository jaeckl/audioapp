#pragma once

#include "audioapp/ModulationTypes.hpp"
#include "audioapp/modulation/ModulatorParams.hpp"
#include "audioapp/modulation/IModulator.hpp"
#include "audioapp/modulation/IModulatorType.hpp"
#include "audioapp/modulation/ModulatorArena.hpp"
#include "audioapp/modulation/LfoModulatorType.hpp"
#include "audioapp/modulation/EnvelopeModulatorType.hpp"

#include <atomic>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace audioapp {

/// Modulators + modulation edge state.
class ModulationGraph {
public:
    static constexpr int kMaxLfos = 16;

    /// Pair of domain id + modulator params (control thread only).
    struct ModulatorRecord {
        int id = 0;
        int typeIndex = 0;  // 0=Lfo, 1=Envelope (index into modulatorTypes_)
        ModulatorParams params;
    };

    ModulationGraph();

    void clear();
    void rebuildPlayback();
    void recomputeIdCounters();

    int createLfo(int modulatorType = 0);
    bool removeLfo(int lfoId);
    bool updateLfoParam(int lfoId, const std::string& param, float value);
    bool assignModulation(int lfoId,
                          const std::string& deviceId,
                          const std::string& paramId,
                          float amount);
    bool removeModulation(int lfoId, const std::string& paramId);
    void removeModulationForDevice(const std::string& deviceId);
    bool hasLfo(int lfoId) const;
    void retriggerOnNote() noexcept;

    const std::vector<ModulatorRecord>& lfos() const { return lfos_; }
    const std::vector<ModulationEdge>& modEdges() const { return modEdges_; }

    int lfoPlaybackCount() const noexcept {
        return lfoPlaybackCount_.load(std::memory_order_acquire);
    }

    IModulator* modulator(int index) const noexcept {
        const int slot = activeSlot_.load(std::memory_order_acquire);
        return slots_[slot].arena.get(index);
    }

    /// Points to the active slot's arena for the audio thread.
    const ModulatorArena& arenaForAudio() const noexcept {
        const int slot = activeSlot_.load(std::memory_order_acquire);
        return slots_[slot].arena;
    }

    /// Maps a domain LFO id (from ModulationEdge.lfoId) to the compact
    /// playback array index. Returns -1 if the LFO is no longer present.
    int playbackIndexForLfoId(int lfoId) const noexcept {
        const int count = lfoPlaybackCount_.load(std::memory_order_acquire);
        if (count <= 0) return -1;
        const int slot = activeSlot_.load(std::memory_order_acquire);
        for (int i = 0; i < count; ++i) {
            if (slots_[slot].ids[i] == lfoId) return i;
        }
        return -1;
    }

    uint32_t noteRetriggerGeneration() const noexcept {
        return noteRetriggerGeneration_.load(std::memory_order_acquire);
    }

    const std::vector<std::unique_ptr<IModulatorType>>& modulatorTypes() const { return modulatorTypes_; }

    /// Serialize all modulator records to a juce::var array for JSON output.
    /// Each element: { "id": N, "type": "lfo"|"envelope", ...params }
    juce::var recordsToVar() const;

    /// Deserialize modulator records from a juce::var array.
    /// Each element must have "type" matching a registered IModulatorType::typeId().
    void recordsFromVar(const juce::var& arr);

    /// Replace all records and edges (for project load).
    void replaceRecords(const std::vector<ModulatorRecord>& records,
                        const std::vector<ModulationEdge>& edges);

private:
    /// Double-buffered playback state. The control thread rebuilds into the
    /// inactive slot, then atomically flips activeSlot_. The audio thread
    /// reads from the active slot, so placement-new never races with reads.
    struct PlaybackState {
        ModulatorArena arena;
        int ids[kMaxLfos]{};
    };
    PlaybackState slots_[2];
    std::atomic<int> activeSlot_{0};
    std::atomic<int> lfoPlaybackCount_{0};

    std::vector<ModulatorRecord> lfos_;
    std::vector<ModulationEdge> modEdges_;
    std::vector<std::unique_ptr<IModulatorType>> modulatorTypes_;
    int nextLfoId_ = 1;

    std::atomic<uint32_t> noteRetriggerGeneration_{0};
};

} // namespace audioapp