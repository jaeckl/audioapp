#include "audioapp/modulation/ModulationGraph.hpp"

#include <algorithm>

namespace audioapp {

ModulationGraph::ModulationGraph() {
    modulatorTypes_.push_back(std::make_unique<LfoModulatorType>());
    modulatorTypes_.push_back(std::make_unique<AdsrModulatorType>());
    modulatorTypes_.push_back(std::make_unique<AdrModulatorType>());
}

void ModulationGraph::clear() {
    lfos_.clear();
    modEdges_.clear();
    nextLfoId_ = 1;
    arena_.reset();
    lfoPlaybackCount_.store(0, std::memory_order_release);
    noteRetriggerGeneration_.store(0, std::memory_order_release);
}

void ModulationGraph::reloadFromLfoStates(const std::vector<LfoState>& lfos,
                                          const std::vector<ModulationEdge>& modEdges) {
    lfos_.clear();
    lfos_.reserve(lfos.size());
    for (const auto& old : lfos) {
        ModulatorRecord rec;
        rec.id = old.id;
        rec.typeIndex = std::clamp(old.modulatorType, 0, 2);
        // Convert old LfoState to appropriate ModulatorParams variant
        if (old.modulatorType == static_cast<int>(ModulatorType::Lfo)) {
            LfoParams p;
            p.waveform = old.waveform;
            p.rate = old.rate;
            p.syncDivision = old.syncDivision;
            p.retrigger = old.retrigger;
            p.phase = old.phase;
            p.polarity = old.polarity;
            p.attack = old.attack;
            p.decay = old.decay;
            p.sustain = old.sustain;
            p.release = old.release;
            rec.params = p;
        } else if (old.modulatorType == static_cast<int>(ModulatorType::Adsr)) {
            AdsrParams p;
            p.attack = old.attack;
            p.decay = old.decay;
            p.sustain = old.sustain;
            p.release = old.release;
            p.polarity = old.polarity;
            rec.params = p;
        } else {
            AdrParams p;
            p.attack = old.attack;
            p.decay = old.decay;
            p.release = old.release;
            p.polarity = old.polarity;
            rec.params = p;
        }
        lfos_.push_back(std::move(rec));
    }
    modEdges_ = modEdges;
}

void ModulationGraph::rebuildPlayback() {
    arena_.reset();
    int lfoIndex = 0;
    for (const auto& rec : lfos_) {
        if (lfoIndex >= kMaxLfos) break;
        const auto& type = modulatorTypes_[static_cast<size_t>(rec.typeIndex)];
        IModulator* mod = type->createModulator(arena_, rec.params);
        if (mod) {
            modulatorIds_[lfoIndex] = rec.id;
            ++lfoIndex;
        }
    }
    lfoPlaybackCount_.store(lfoIndex, std::memory_order_release);
}

void ModulationGraph::recomputeIdCounters() {
    int maxLfo = 0;
    for (const auto& lfo : lfos_) maxLfo = std::max(maxLfo, lfo.id);
    nextLfoId_ = maxLfo + 1;
}

int ModulationGraph::createLfo(int modulatorType) {
    const int typeIndex = std::clamp(modulatorType, 0, 2);
    const auto& type = modulatorTypes_[static_cast<size_t>(typeIndex)];
    ModulatorRecord rec;
    rec.id = nextLfoId_++;
    rec.typeIndex = typeIndex;
    rec.params = type->createDefault();
    lfos_.push_back(std::move(rec));
    rebuildPlayback();
    return lfos_.back().id;
}

bool ModulationGraph::removeLfo(int lfoId) {
    for (auto it = lfos_.begin(); it != lfos_.end(); ++it) {
        if (it->id != lfoId) continue;
        lfos_.erase(it);
        for (auto eit = modEdges_.begin(); eit != modEdges_.end();) {
            if (eit->lfoId == lfoId) eit = modEdges_.erase(eit);
            else ++eit;
        }
        rebuildPlayback();
        return true;
    }
    return false;
}

bool ModulationGraph::updateLfoParam(int lfoId, const std::string& param, float value) {
    for (auto& rec : lfos_) {
        if (rec.id != lfoId) continue;

        // Special case: changing the modulator type
        if (param == "modulatorType") {
            const int newType = std::clamp(static_cast<int>(value), 0, 2);
            if (newType != rec.typeIndex) {
                rec.typeIndex = newType;
                rec.params = modulatorTypes_[static_cast<size_t>(newType)]->createDefault();
                rebuildPlayback();
            }
            return true;
        }

        // Delegate to the current modulator type's setParameter
        const auto& type = modulatorTypes_[static_cast<size_t>(rec.typeIndex)];
        if (type->setParameter(rec.params, param, value)) {
            rebuildPlayback();
            return true;
        }

        return false;
    }
    return false;
}

bool ModulationGraph::hasLfo(int lfoId) const {
    for (const auto& lfo : lfos_) if (lfo.id == lfoId) return true;
    return false;
}

bool ModulationGraph::assignModulation(int lfoId, const std::string& deviceId,
                                       const std::string& paramId, float amount) {
    if (!hasLfo(lfoId)) return false;
    for (auto& edge : modEdges_) {
        if (edge.lfoId == lfoId && edge.paramId == paramId) {
            edge.deviceId = deviceId;
            edge.amount = std::clamp(amount, -1.0f, 1.0f);
            return true;
        }
    }
    ModulationEdge edge;
    edge.lfoId = lfoId;
    edge.deviceId = deviceId;
    edge.paramId = paramId;
    edge.amount = std::clamp(amount, -1.0f, 1.0f);
    modEdges_.push_back(std::move(edge));
    return true;
}

bool ModulationGraph::removeModulation(int lfoId, const std::string& paramId) {
    for (auto it = modEdges_.begin(); it != modEdges_.end(); ++it) {
        if (it->lfoId == lfoId && it->paramId == paramId) {
            modEdges_.erase(it);
            return true;
        }
    }
    return false;
}

void ModulationGraph::removeModulationForDevice(const std::string& deviceId) {
    if (deviceId.empty()) return;
    for (auto it = modEdges_.begin(); it != modEdges_.end();) {
        if (it->deviceId == deviceId) { it = modEdges_.erase(it); }
        else ++it;
    }
}

void ModulationGraph::retriggerOnNote() noexcept {
    noteRetriggerGeneration_.fetch_add(1, std::memory_order_release);
}

std::vector<LfoState> ModulationGraph::toLfoStates() const {
    std::vector<LfoState> result;
    result.reserve(lfos_.size());
    for (const auto& rec : lfos_) {
        LfoState s;
        s.id = rec.id;
        s.modulatorType = rec.typeIndex;
        std::visit([&](const auto& params) {
            using T = std::decay_t<decltype(params)>;
            if constexpr (std::is_same_v<T, LfoParams>) {
                s.waveform = params.waveform;
                s.rate = params.rate;
                s.syncDivision = params.syncDivision;
                s.retrigger = params.retrigger;
                s.phase = params.phase;
                s.polarity = params.polarity;
                s.attack = params.attack;
                s.decay = params.decay;
                s.sustain = params.sustain;
                s.release = params.release;
            } else if constexpr (std::is_same_v<T, AdsrParams>) {
                s.retrigger = static_cast<int>(ModulatorRetrigger::OnNote);
                s.syncDivision = 3;
                s.attack = params.attack;
                s.decay = params.decay;
                s.sustain = params.sustain;
                s.release = params.release;
                s.polarity = params.polarity;
            } else {
                s.retrigger = static_cast<int>(ModulatorRetrigger::OnNote);
                s.syncDivision = 3;
                s.attack = params.attack;
                s.decay = params.decay;
                s.release = params.release;
                s.polarity = params.polarity;
                s.sustain = 0.0f;
            }
        }, rec.params);
        result.push_back(s);
    }
    return result;
}

} // namespace audioapp