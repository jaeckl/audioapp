#pragma once

#include <juce_core/juce_core.h>

#include "audioapp/modulation/IModulatorType.hpp"
#include "audioapp/modulation/AdsrModulator.hpp"

namespace audioapp {

/// Control-thread descriptor for ADSR-type modulators.
class AdsrModulatorType : public IModulatorType {
public:
    std::string typeId() const override { return "adsr"; }
    int modulatorTypeValue() const override { return 1; }

    ModulatorParams createDefault() const override {
        AdsrParams p;
        p.attack = 0.08f;
        p.decay = 0.22f;
        p.sustain = 0.65f;
        p.release = 0.28f;
        p.polarity = 0;
        return p;
    }

    bool setParameter(ModulatorParams& params, std::string_view paramId, float value) const override {
        auto& p = std::get<AdsrParams>(params);
        if (paramId == "attack") { p.attack = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "decay") { p.decay = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "sustain") { p.sustain = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "release") { p.release = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "polarity") { p.polarity = std::clamp(static_cast<int>(value), 0, 2); return true; }
        return false;
    }

    IModulator* createModulator(ModulatorArena& arena, const ModulatorParams& params) const override {
        return arena.emplace<AdsrModulator>(std::get<AdsrParams>(params));
    }

    juce::var paramsToVar(const ModulatorParams& params) const override {
        const auto& p = std::get<AdsrParams>(params);
        auto* obj = new juce::DynamicObject();
        obj->setProperty("type", "adsr");
        obj->setProperty("attack", static_cast<double>(p.attack));
        obj->setProperty("decay", static_cast<double>(p.decay));
        obj->setProperty("sustain", static_cast<double>(p.sustain));
        obj->setProperty("release", static_cast<double>(p.release));
        obj->setProperty("polarity", p.polarity);
        return juce::var(obj);
    }

    ModulatorParams varToParams(const juce::var& obj) const override {
        AdsrParams p;
        if (const auto* o = obj.getDynamicObject()) {
            auto readFloat = [&](const char* key, float fallback) -> float {
                const auto v = o->getProperty(key);
                return (v.isDouble() || v.isInt()) ? static_cast<float>(static_cast<double>(v)) : fallback;
            };
            auto readInt = [&](const char* key, int fallback) -> int {
                const auto v = o->getProperty(key);
                return (v.isDouble() || v.isInt()) ? static_cast<int>(static_cast<double>(v)) : fallback;
            };
            p.attack = readFloat("attack", 0.08f);
            p.decay = readFloat("decay", 0.22f);
            p.sustain = readFloat("sustain", 0.65f);
            p.release = readFloat("release", 0.28f);
            p.polarity = readInt("polarity", 0);
        }
        return p;
    }
};

} // namespace audioapp