#pragma once

#include <juce_core/juce_core.h>

#include "audioapp/modulation/IModulatorType.hpp"
#include "audioapp/modulation/SequencerModulator.hpp"

namespace audioapp {

/// Control-thread descriptor for Step Sequencer modulators.
class SequencerModulatorType : public IModulatorType {
public:
    std::string typeId() const override { return "sequencer"; }
    int modulatorTypeValue() const override { return 3; }

    ModulatorParams createDefault() const override {
        SequencerParams p;
        p.stepCount = 16;
        p.rate = 0.5f;
        p.syncDivision = 3;     // quarter note
        p.retrigger = 1;        // Sync
        p.direction = 0;        // Forward
        p.shape = 0;            // Hold
        p.polarity = 0;         // bipolar
        p.smoothing = 0.0f;
        // stepValues default to 0.5f via SequencerParams constructor
        return p;
    }

    bool setParameter(ModulatorParams& params, std::string_view paramId, float value) const override {
        auto& p = std::get<SequencerParams>(params);
        if (paramId == "steps") { p.stepCount = std::clamp(static_cast<int>(value), 1, 32); return true; }
        if (paramId == "rate") { p.rate = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "syncDivision") { p.syncDivision = std::clamp(static_cast<int>(value), 0, 5); return true; }
        if (paramId == "retrigger") { p.retrigger = std::clamp(static_cast<int>(value), 0, 2); return true; }
        if (paramId == "direction") { p.direction = std::clamp(static_cast<int>(value), 0, 3); return true; }
        if (paramId == "shape") { p.shape = std::clamp(static_cast<int>(value), 0, 2); return true; }
        if (paramId == "polarity") { p.polarity = std::clamp(static_cast<int>(value), 0, 1); return true; }
        if (paramId == "smoothing") { p.smoothing = std::clamp(value, 0.0f, 1.0f); return true; }
        // step_N: N = 0..31
        if (paramId.size() > 5 && paramId.substr(0, 5) == "step_") {
            const auto idxStr = paramId.substr(5);
            char* end = nullptr;
            const long idx = std::strtol(idxStr.data(), &end, 10);
            if (end == idxStr.data() + idxStr.size() && idx >= 0 && idx < 32) {
                p.stepValues[static_cast<size_t>(idx)] = std::clamp(value, 0.0f, 1.0f);
                return true;
            }
        }
        return false;
    }

    IModulator* createModulator(ModulatorArena& arena, const ModulatorParams& params) const override {
        return arena.emplace<SequencerModulator>(std::get<SequencerParams>(params));
    }

    juce::var paramsToVar(const ModulatorParams& params) const override {
        const auto& p = std::get<SequencerParams>(params);
        auto* obj = new juce::DynamicObject();
        obj->setProperty("stepCount", p.stepCount);
        obj->setProperty("rate", static_cast<double>(p.rate));
        obj->setProperty("syncDivision", p.syncDivision);
        obj->setProperty("retrigger", p.retrigger);
        obj->setProperty("direction", p.direction);
        obj->setProperty("shape", p.shape);
        obj->setProperty("polarity", p.polarity);
        obj->setProperty("smoothing", static_cast<double>(p.smoothing));
        obj->setProperty("type", "sequencer");
        // Emit step_N for N in [0, stepCount-1]
        for (int i = 0; i < p.stepCount; ++i) {
            const std::string key = "step_" + std::to_string(i);
            obj->setProperty(juce::Identifier(key), static_cast<double>(p.stepValues[static_cast<size_t>(i)]));
        }
        return juce::var(obj);
    }

    ModulatorParams varToParams(const juce::var& obj) const override {
        SequencerParams p;
        if (const auto* o = obj.getDynamicObject()) {
            auto readFloat = [&](const char* key, float fallback) -> float {
                const auto v = o->getProperty(key);
                return (v.isDouble() || v.isInt()) ? static_cast<float>(static_cast<double>(v)) : fallback;
            };
            auto readInt = [&](const char* key, int fallback) -> int {
                const auto v = o->getProperty(key);
                return (v.isDouble() || v.isInt()) ? static_cast<int>(static_cast<double>(v)) : fallback;
            };
            p.stepCount = std::clamp(readInt("stepCount", 16), 1, 32);
            p.rate = std::clamp(readFloat("rate", 0.5f), 0.0f, 1.0f);
            p.syncDivision = std::clamp(readInt("syncDivision", 3), 0, 5);
            p.retrigger = std::clamp(readInt("retrigger", 1), 0, 2);
            p.direction = std::clamp(readInt("direction", 0), 0, 3);
            p.shape = std::clamp(readInt("shape", 0), 0, 2);
            p.polarity = std::clamp(readInt("polarity", 0), 0, 1);
            p.smoothing = std::clamp(readFloat("smoothing", 0.0f), 0.0f, 1.0f);
            // Read step_N for N in [0, stepCount-1]; missing keys default to 0.5
            for (int i = 0; i < p.stepCount; ++i) {
                const std::string key = "step_" + std::to_string(i);
                p.stepValues[static_cast<size_t>(i)] = std::clamp(readFloat(key.c_str(), 0.5f), 0.0f, 1.0f);
            }
        }
        return p;
    }
};

} // namespace audioapp