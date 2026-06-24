#include "audioapp/modulation/ModulationGraph.hpp"

#include <juce_core/juce_core.h>

#include <algorithm>

#include "audioapp/modulation/RandomGeneratorModulatorType.hpp"

namespace audioapp {

ModulationGraph::ModulationGraph() {
    modulatorTypes_.push_back(std::make_unique<LfoModulatorType>());
    modulatorTypes_.push_back(std::make_unique<EnvelopeModulatorType>());
    modulatorTypes_.push_back(std::make_unique<RandomGeneratorModulatorType>());
}

void ModulationGraph::clear() {
    lfos_.clear();
    modEdges_.clear();
    nextLfoId_ = 1;
    arena_.reset();
    lfoPlaybackCount_.store(0, std::memory_order_release);
    noteRetriggerGeneration_.store(0, std::memory_order_release);
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
    const int typeIndex = std::clamp(modulatorType, 0, static_cast<int>(modulatorTypes_.size()) - 1);
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
            const int newType = std::clamp(static_cast<int>(value), 0, static_cast<int>(modulatorTypes_.size()) - 1);
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

juce::var ModulationGraph::recordsToVar() const {
    juce::Array<juce::var> result;
    result.ensureStorageAllocated(static_cast<int>(lfos_.size()));
    for (const auto& rec : lfos_) {
        const auto& type = modulatorTypes_[static_cast<size_t>(rec.typeIndex)];
        juce::var paramsVar = type->paramsToVar(rec.params);
        if (auto* obj = paramsVar.getDynamicObject()) {
            obj->setProperty("id", rec.id);
            obj->setProperty("type", juce::String(type->typeId()));
        }
        result.add(paramsVar);
    }
    return juce::var(result);
}

void ModulationGraph::recordsFromVar(const juce::var& arr) {
    lfos_.clear();
    const auto* array = arr.getArray();
    if (array == nullptr) return;

    lfos_.reserve(static_cast<size_t>(array->size()));
    for (const auto& item : *array) {
        const auto* obj = item.getDynamicObject();
        if (obj == nullptr) continue;

        const int id = static_cast<int>(obj->getProperty("id"));
        const std::string typeId = obj->getProperty("type").toString().toStdString();

        // Find matching modulator type
        int typeIndex = -1;
        for (size_t i = 0; i < modulatorTypes_.size(); ++i) {
            if (modulatorTypes_[i]->typeId() == typeId) {
                typeIndex = static_cast<int>(i);
                break;
            }
        }
        if (typeIndex < 0) continue;

        ModulatorRecord rec;
        rec.id = id;
        rec.typeIndex = typeIndex;
        rec.params = modulatorTypes_[static_cast<size_t>(typeIndex)]->varToParams(item);
        lfos_.push_back(std::move(rec));
    }
}

void ModulationGraph::replaceRecords(const std::vector<ModulatorRecord>& records,
                                      const std::vector<ModulationEdge>& edges) {
    lfos_ = records;
    modEdges_ = edges;
    recomputeIdCounters();
    rebuildPlayback();
}

} // namespace audioapp