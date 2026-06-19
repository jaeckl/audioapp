#pragma once

#include "audioapp/LfoTypes.hpp"

#include <atomic>
#include <string>
#include <vector>

namespace audioapp {

/// LFO + modulation edge state with audio-thread playback snapshots.
class ModulationGraph {
public:
    static constexpr int kMaxLfos = 16;
    static constexpr int kMaxModEdges = 64;

    struct LfoPlaybackEntry {
        LfoState state;
    };

    void clear();
    void load(const std::vector<LfoState>& lfos, const std::vector<ModulationEdge>& modEdges);
    void rebuildPlayback();
    void recomputeIdCounters();

    int createLfo();
    bool removeLfo(int lfoId);
    bool updateLfoParam(int lfoId, const std::string& param, float value);
    bool assignModulation(int lfoId,
                          const std::string& deviceId,
                          const std::string& paramId,
                          float amount);
    bool removeModulation(int lfoId, const std::string& paramId);
    void removeModulationForDevice(const std::string& deviceId);
    bool hasLfo(int lfoId) const;

    const std::vector<LfoState>& lfos() const { return lfos_; }
    const std::vector<ModulationEdge>& modEdges() const { return modEdges_; }

    int lfoPlaybackCount() const noexcept {
        return lfoPlaybackCount_.load(std::memory_order_acquire);
    }
    int modEdgePlaybackCount() const noexcept {
        return modEdgePlaybackCount_.load(std::memory_order_acquire);
    }
    const LfoPlaybackEntry& lfoPlaybackEntry(int index) const noexcept { return lfoPlayback_[index]; }
    const ModulationEdge& modEdgePlaybackEntry(int index) const noexcept {
        return modEdgePlayback_[index];
    }
    const ModulationEdge* modEdgePlaybackData() const noexcept { return modEdgePlayback_; }

private:
    std::vector<LfoState> lfos_;
    std::vector<ModulationEdge> modEdges_;
    int nextLfoId_ = 1;

    LfoPlaybackEntry lfoPlayback_[kMaxLfos]{};
    ModulationEdge modEdgePlayback_[kMaxModEdges]{};
    std::atomic<int> lfoPlaybackCount_{0};
    std::atomic<int> modEdgePlaybackCount_{0};
};

} // namespace audioapp
