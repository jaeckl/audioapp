#pragma once

#include "audioapp/LfoTypes.hpp"
#include "audioapp/modulation/ModulatorParams.hpp"
#include "audioapp/modulation/IModulator.hpp"
#include "audioapp/modulation/IModulatorType.hpp"
#include "audioapp/modulation/ModulatorArena.hpp"
#include "audioapp/modulation/LfoModulatorType.hpp"
#include "audioapp/modulation/AdsrModulatorType.hpp"
#include "audioapp/modulation/AdrModulatorType.hpp"

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
        int typeIndex = 0;  // 0=Lfo, 1=Adsr, 2=Adr (index into modulatorTypes_)
        ModulatorParams params;
    };

    ModulationGraph();

    void clear();
    void reloadFromLfoStates(const std::vector<LfoState>& lfos,
                             const std::vector<ModulationEdge>& modEdges);
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
        return arena_.get(index);
    }

    ModulatorArena& arena() noexcept { return arena_; }
    const ModulatorArena& arena() const noexcept { return arena_; }

    /// Maps a domain LFO id (from ModulationEdge.lfoId) to the compact
    /// playback array index. Returns -1 if the LFO is no longer present.
    int playbackIndexForLfoId(int lfoId) const noexcept {
        const int count = lfoPlaybackCount_.load(std::memory_order_acquire);
        for (int i = 0; i < count; ++i) {
            if (modulatorIds_[i] == lfoId) return i;
        }
        return -1;
    }

    uint32_t noteRetriggerGeneration() const noexcept {
        return noteRetriggerGeneration_.load(std::memory_order_acquire);
    }

    const std::vector<std::unique_ptr<IModulatorType>>& modulatorTypes() const { return modulatorTypes_; }

    /// Backward-compat: convert current ModulatorRecord list to LfoState vector
    /// for ProjectFileData / bridge serialization.
    std::vector<LfoState> toLfoStates() const;

    /// Backward-compat: load from old LfoState vector (calls reloadFromLfoStates).
    void load(const std::vector<LfoState>& lfos,
              const std::vector<ModulationEdge>& modEdges) {
        reloadFromLfoStates(lfos, modEdges);
    }

private:
    std::vector<ModulatorRecord> lfos_;
    std::vector<ModulationEdge> modEdges_;
    std::vector<std::unique_ptr<IModulatorType>> modulatorTypes_;
    int nextLfoId_ = 1;

    ModulatorArena arena_;
    int modulatorIds_[kMaxLfos]{};
    std::atomic<int> lfoPlaybackCount_{0};
    std::atomic<uint32_t> noteRetriggerGeneration_{0};
};

} // namespace audioapp