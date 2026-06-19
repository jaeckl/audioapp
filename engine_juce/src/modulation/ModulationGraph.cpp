#include "audioapp/modulation/ModulationGraph.hpp"

#include <algorithm>

namespace audioapp {

void ModulationGraph::clear() {
    lfos_.clear();
    modEdges_.clear();
    nextLfoId_ = 1;
    lfoPlaybackCount_.store(0, std::memory_order_release);
    modEdgePlaybackCount_.store(0, std::memory_order_release);
    noteRetriggerGeneration_.store(0, std::memory_order_release);
}

void ModulationGraph::load(const std::vector<LfoState>& lfos,
                           const std::vector<ModulationEdge>& modEdges) {
    lfos_ = lfos;
    modEdges_ = modEdges;
}

void ModulationGraph::rebuildPlayback() {
    int lfoIndex = 0;
    for (const auto& lfo : lfos_) {
        if (lfoIndex >= kMaxLfos) {
            break;
        }
        lfoPlayback_[lfoIndex].state = lfo;
        ++lfoIndex;
    }
    lfoPlaybackCount_.store(lfoIndex, std::memory_order_release);

    int edgeIndex = 0;
    for (const auto& edge : modEdges_) {
        if (edgeIndex >= kMaxModEdges) {
            break;
        }
        modEdgePlayback_[edgeIndex].lfoId = edge.lfoId;
        modEdgePlayback_[edgeIndex].deviceId = edge.deviceId;
        modEdgePlayback_[edgeIndex].paramId = paramIdFromString(edge.paramId.c_str());
        modEdgePlayback_[edgeIndex].amount = edge.amount;
        ++edgeIndex;
    }
    modEdgePlaybackCount_.store(edgeIndex, std::memory_order_release);
}

void ModulationGraph::recomputeIdCounters() {
    int maxLfo = 0;
    for (const auto& lfo : lfos_) {
        maxLfo = std::max(maxLfo, lfo.id);
    }
    nextLfoId_ = maxLfo + 1;
}

int ModulationGraph::createLfo(int modulatorType) {
    LfoState lfo;
    lfo.id = nextLfoId_++;
    lfo.modulatorType = std::clamp(modulatorType, 0, 2);
    if (lfo.modulatorType == static_cast<int>(ModulatorType::Lfo)) {
        lfo.waveform = static_cast<int>(LfoWaveform::Sine);
        lfo.rate = 1.0f;
        lfo.syncDivision = 3;
        lfo.retrigger = static_cast<int>(ModulatorRetrigger::Sync);
    } else {
        lfo.retrigger = static_cast<int>(ModulatorRetrigger::OnNote);
        lfo.syncDivision = 3;
        lfo.attack = 0.08f;
        lfo.decay = 0.22f;
        lfo.sustain = 0.65f;
        lfo.release = 0.28f;
    }
    lfos_.push_back(std::move(lfo));
    rebuildPlayback();
    return lfos_.back().id;
}

bool ModulationGraph::removeLfo(int lfoId) {
    for (auto it = lfos_.begin(); it != lfos_.end(); ++it) {
        if (it->id != lfoId) {
            continue;
        }
        lfos_.erase(it);
        for (auto eit = modEdges_.begin(); eit != modEdges_.end();) {
            if (eit->lfoId == lfoId) {
                eit = modEdges_.erase(eit);
            } else {
                ++eit;
            }
        }
        rebuildPlayback();
        return true;
    }
    return false;
}

bool ModulationGraph::updateLfoParam(int lfoId, const std::string& param, float value) {
    for (auto& lfo : lfos_) {
        if (lfo.id != lfoId) {
            continue;
        }
        if (param == "modulatorType") {
            lfo.modulatorType = std::clamp(static_cast<int>(value), 0, 2);
        } else if (param == "retrigger") {
            lfo.retrigger = std::clamp(static_cast<int>(value), 0, 2);
            if (lfo.retrigger == static_cast<int>(ModulatorRetrigger::Free)) {
                lfo.syncDivision = 0;
            } else if (lfo.retrigger == static_cast<int>(ModulatorRetrigger::Sync) &&
                       lfo.syncDivision == 0) {
                lfo.syncDivision = 3;
            }
        } else if (param == "waveform") {
            lfo.waveform = std::clamp(static_cast<int>(value), 0, static_cast<int>(LfoWaveform::Ramp));
        } else if (param == "rate") {
            lfo.rate = std::max(0.01f, value);
        } else if (param == "syncDivision") {
            lfo.syncDivision = std::clamp(static_cast<int>(value), 0, 5);
        } else if (param == "phase") {
            lfo.phase = std::clamp(value, 0.0f, 1.0f);
        } else if (param == "polarity") {
            lfo.polarity = std::clamp(static_cast<int>(value), 0, 2);
        } else if (param == "attack") {
            lfo.attack = std::clamp(value, 0.0f, 1.0f);
        } else if (param == "decay") {
            lfo.decay = std::clamp(value, 0.0f, 1.0f);
        } else if (param == "sustain") {
            lfo.sustain = std::clamp(value, 0.0f, 1.0f);
        } else if (param == "release") {
            lfo.release = std::clamp(value, 0.0f, 1.0f);
        } else {
            return false;
        }
        rebuildPlayback();
        return true;
    }
    return false;
}

bool ModulationGraph::hasLfo(int lfoId) const {
    for (const auto& lfo : lfos_) {
        if (lfo.id == lfoId) {
            return true;
        }
    }
    return false;
}

bool ModulationGraph::assignModulation(int lfoId,
                                       const std::string& deviceId,
                                       const std::string& paramId,
                                       float amount) {
    if (!hasLfo(lfoId)) {
        return false;
    }
    for (auto& edge : modEdges_) {
        if (edge.lfoId == lfoId && edge.paramId == paramId) {
            edge.deviceId = deviceId;
            edge.amount = std::clamp(amount, -1.0f, 1.0f);
            rebuildPlayback();
            return true;
        }
    }
    ModulationEdge edge;
    edge.lfoId = lfoId;
    edge.deviceId = deviceId;
    edge.paramId = paramId;
    edge.amount = std::clamp(amount, -1.0f, 1.0f);
    modEdges_.push_back(std::move(edge));
    rebuildPlayback();
    return true;
}

bool ModulationGraph::removeModulation(int lfoId, const std::string& paramId) {
    for (auto it = modEdges_.begin(); it != modEdges_.end(); ++it) {
        if (it->lfoId == lfoId && it->paramId == paramId) {
            modEdges_.erase(it);
            rebuildPlayback();
            return true;
        }
    }
    return false;
}

void ModulationGraph::removeModulationForDevice(const std::string& deviceId) {
    if (deviceId.empty()) {
        return;
    }
    bool changed = false;
    for (auto it = modEdges_.begin(); it != modEdges_.end();) {
        if (it->deviceId == deviceId) {
            it = modEdges_.erase(it);
            changed = true;
        } else {
            ++it;
        }
    }
    if (changed) {
        rebuildPlayback();
    }
}

void ModulationGraph::retriggerOnNote() noexcept {
    noteRetriggerGeneration_.fetch_add(1, std::memory_order_release);
}

} // namespace audioapp