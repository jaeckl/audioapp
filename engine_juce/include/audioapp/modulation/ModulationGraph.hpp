#pragma once

#include "audioapp/LfoTypes.hpp"

#include <atomic>
#include <cstdint>
#include <string>
#include <vector>

namespace audioapp {

/// Modulators + modulation edge state.
class ModulationGraph {
public:
    static constexpr int kMaxLfos = 16;

    struct EnvelopeRuntime {
        float level = 0.0f;
        int stage = 0;
        double segStartSeconds = 0.0;
        uint32_t lastRetriggerGeneration = 0;
    };

    struct LfoPlaybackEntry {
        LfoState state;
        EnvelopeRuntime envelope;
    };

    void clear();
    void load(const std::vector<LfoState>& lfos, const std::vector<ModulationEdge>& modEdges);
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

    const std::vector<LfoState>& lfos() const { return lfos_; }
    const std::vector<ModulationEdge>& modEdges() const { return modEdges_; }

    int lfoPlaybackCount() const noexcept {
        return lfoPlaybackCount_.load(std::memory_order_acquire);
    }
    const LfoPlaybackEntry& lfoPlaybackEntry(int index) const noexcept { return lfoPlayback_[index]; }
    LfoPlaybackEntry& lfoPlaybackEntryMutable(int index) noexcept { return lfoPlayback_[index]; }
    uint32_t noteRetriggerGeneration() const noexcept {
        return noteRetriggerGeneration_.load(std::memory_order_acquire);
    }

private:
    std::vector<LfoState> lfos_;
    std::vector<ModulationEdge> modEdges_;
    int nextLfoId_ = 1;

    LfoPlaybackEntry lfoPlayback_[kMaxLfos]{};
    std::atomic<int> lfoPlaybackCount_{0};
    std::atomic<uint32_t> noteRetriggerGeneration_{0};
};

} // namespace audioapp