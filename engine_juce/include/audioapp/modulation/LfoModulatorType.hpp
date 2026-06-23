#pragma once

#include <juce_core/juce_core.h>

#include "audioapp/modulation/IModulatorType.hpp"
#include "audioapp/modulation/LfoModulator.hpp"

namespace audioapp {

/// Control-thread descriptor for LFO-type modulators.
class LfoModulatorType : public IModulatorType {
public:
    std::string typeId() const override { return "lfo"; }
    int modulatorTypeValue() const override { return 0; }

    ModulatorParams createDefault() const override {
        LfoParams p;
        p.waveform = 0;       // Sine
        p.rate = 1.0f;
        p.syncDivision = 3;   // Quarter
        p.retrigger = 1;      // Sync
        p.phase = 0.0f;
        p.polarity = 0;       // Bipolar
        p.attack = 0.1f;
        p.decay = 0.25f;
        p.sustain = 0.70f;
        p.release = 0.35f;
        return p;
    }

    bool setParameter(ModulatorParams& params, std::string_view paramId, float value) const override {
        auto& p = std::get<LfoParams>(params);
        if (paramId == "waveform") { p.waveform = std::clamp(static_cast<int>(value), 0, 4); return true; }
        if (paramId == "rate") { p.rate = std::max(0.01f, value); return true; }
        if (paramId == "syncDivision") { p.syncDivision = std::clamp(static_cast<int>(value), 0, 5); return true; }
        if (paramId == "retrigger") { p.retrigger = std::clamp(static_cast<int>(value), 0, 2); return true; }
        if (paramId == "phase") { p.phase = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "polarity") { p.polarity = std::clamp(static_cast<int>(value), 0, 2); return true; }
        if (paramId == "attack") { p.attack = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "decay") { p.decay = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "sustain") { p.sustain = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "release") { p.release = std::clamp(value, 0.0f, 1.0f); return true; }
        return false;
    }

    IModulator* createModulator(ModulatorArena& arena, const ModulatorParams& params) const override {
        return arena.emplace<LfoModulator>(std::get<LfoParams>(params));
    }

    juce::var paramsToVar(const ModulatorParams& params) const override {
        const auto& p = std::get<LfoParams>(params);
        auto* obj = new juce::DynamicObject();
        obj->setProperty("waveform", p.waveform);
        obj->setProperty("rate", static_cast<double>(p.rate));
        obj->setProperty("syncDivision", p.syncDivision);
        obj->setProperty("retrigger", p.retrigger);
        obj->setProperty("phase", static_cast<double>(p.phase));
        obj->setProperty("polarity", p.polarity);
        obj->setProperty("attack", static_cast<double>(p.attack));
        obj->setProperty("decay", static_cast<double>(p.decay));
        obj->setProperty("sustain", static_cast<double>(p.sustain));
        obj->setProperty("release", static_cast<double>(p.release));
        obj->setProperty("type", "lfo");
        return juce::var(obj);
    }

    ModulatorParams varToParams(const juce::var& obj) const override {
        LfoParams p;
        if (const auto* o = obj.getDynamicObject()) {
            auto readFloat = [&](const char* key, float fallback) -> float {
                const auto v = o->getProperty(key);
                return (v.isDouble() || v.isInt()) ? static_cast<float>(static_cast<double>(v)) : fallback;
            };
            auto readInt = [&](const char* key, int fallback) -> int {
                const auto v = o->getProperty(key);
                return (v.isDouble() || v.isInt()) ? static_cast<int>(static_cast<double>(v)) : fallback;
            };
            p.waveform = readInt("waveform", 0);
            p.rate = readFloat("rate", 1.0f);
            p.syncDivision = readInt("syncDivision", 3);
            p.retrigger = readInt("retrigger", 1);
            p.phase = readFloat("phase", 0.0f);
            p.polarity = readInt("polarity", 0);
            p.attack = readFloat("attack", 0.1f);
            p.decay = readFloat("decay", 0.25f);
            p.sustain = readFloat("sustain", 0.7f);
            p.release = readFloat("release", 0.35f);
        }
        return p;
    }
};

} // namespace audioapp