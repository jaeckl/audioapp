#pragma once

#include <juce_core/juce_core.h>

#include "audioapp/modulation/IModulatorType.hpp"
#include "audioapp/modulation/RandomGeneratorModulator.hpp"

namespace audioapp {

/// Control-thread descriptor for Random Generator (sample & hold) modulators.
class RandomGeneratorModulatorType : public IModulatorType {
public:
    std::string typeId() const override { return "random_generator"; }
    int modulatorTypeValue() const override { return 2; }

    ModulatorParams createDefault() const override {
        RandomGeneratorParams p;
        p.rate = 0.5f;
        p.smoothing = 0.0f;
        p.retrigger = 1;
        p.polarity = 0;
        return p;
    }

    bool setParameter(ModulatorParams& params, std::string_view paramId, float value) const override {
        auto& p = std::get<RandomGeneratorParams>(params);
        if (paramId == "rate") { p.rate = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "smoothing") { p.smoothing = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "retrigger") { p.retrigger = std::clamp(static_cast<int>(value), 0, 2); return true; }
        if (paramId == "polarity") { p.polarity = std::clamp(static_cast<int>(value), 0, 1); return true; }
        return false;
    }

    IModulator* createModulator(ModulatorArena& arena, const ModulatorParams& params) const override {
        return arena.emplace<RandomGeneratorModulator>(std::get<RandomGeneratorParams>(params));
    }

    juce::var paramsToVar(const ModulatorParams& params) const override {
        const auto& p = std::get<RandomGeneratorParams>(params);
        auto* obj = new juce::DynamicObject();
        obj->setProperty("rate", static_cast<double>(p.rate));
        obj->setProperty("smoothing", static_cast<double>(p.smoothing));
        obj->setProperty("retrigger", p.retrigger);
        obj->setProperty("polarity", p.polarity);
        obj->setProperty("type", "random_generator");
        return juce::var(obj);
    }

    ModulatorParams varToParams(const juce::var& obj) const override {
        RandomGeneratorParams p;
        if (const auto* o = obj.getDynamicObject()) {
            auto readFloat = [&](const char* key, float fallback) -> float {
                const auto v = o->getProperty(key);
                return (v.isDouble() || v.isInt()) ? static_cast<float>(static_cast<double>(v)) : fallback;
            };
            auto readInt = [&](const char* key, int fallback) -> int {
                const auto v = o->getProperty(key);
                return (v.isDouble() || v.isInt()) ? static_cast<int>(static_cast<double>(v)) : fallback;
            };
            p.rate = readFloat("rate", 0.5f);
            p.smoothing = readFloat("smoothing", 0.0f);
            p.retrigger = readInt("retrigger", 1);
            p.polarity = readInt("polarity", 0);
        }
        return p;
    }
};

} // namespace audioapp