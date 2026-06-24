#pragma once

#include <juce_core/juce_core.h>

#include "audioapp/modulation/IModulatorType.hpp"
#include "audioapp/modulation/EnvelopeModulator.hpp"

namespace audioapp {

/// Control-thread descriptor for unified envelope-type modulators (ADSR/ASR/ADR/AHDSR).
class EnvelopeModulatorType : public IModulatorType {
public:
    std::string typeId() const override { return "envelope"; }
    int modulatorTypeValue() const override { return 1; }

    ModulatorParams createDefault() const override {
        EnvelopeParams p;
        p.attack = 0.08f;
        p.hold = 0.0f;
        p.decay = 0.22f;
        p.sustain = 0.65f;
        p.release = 0.28f;
        p.delay = 0.0f;
        p.attackCurve = 0.5f;
        p.decayCurve = 0.5f;
        p.releaseCurve = 0.5f;
        p.analogMode = 0;
        p.curveType = 0; // ADSR
        return p;
    }

    bool setParameter(ModulatorParams& params, std::string_view paramId, float value) const override {
        auto& p = std::get<EnvelopeParams>(params);
        if (paramId == "attack") { p.attack = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "hold") { p.hold = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "decay") { p.decay = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "sustain") { p.sustain = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "release") { p.release = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "delay") { p.delay = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "attackCurve") { p.attackCurve = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "decayCurve") { p.decayCurve = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "releaseCurve") { p.releaseCurve = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "analogMode") { p.analogMode = (value >= 0.5f) ? 1 : 0; return true; }
        if (paramId == "curveType") { p.curveType = std::clamp(static_cast<int>(value), 0, 3); return true; }
        return false;
    }

    IModulator* createModulator(ModulatorArena& arena, const ModulatorParams& params) const override {
        return arena.emplace<EnvelopeModulator>(std::get<EnvelopeParams>(params));
    }

    juce::var paramsToVar(const ModulatorParams& params) const override {
        const auto& p = std::get<EnvelopeParams>(params);
        auto* obj = new juce::DynamicObject();
        obj->setProperty("type", "envelope");
        obj->setProperty("curveType", p.curveType);
        obj->setProperty("attack", static_cast<double>(p.attack));
        obj->setProperty("hold", static_cast<double>(p.hold));
        obj->setProperty("decay", static_cast<double>(p.decay));
        obj->setProperty("sustain", static_cast<double>(p.sustain));
        obj->setProperty("release", static_cast<double>(p.release));
        obj->setProperty("delay", static_cast<double>(p.delay));
        obj->setProperty("attackCurve", static_cast<double>(p.attackCurve));
        obj->setProperty("decayCurve", static_cast<double>(p.decayCurve));
        obj->setProperty("releaseCurve", static_cast<double>(p.releaseCurve));
        obj->setProperty("analogMode", p.analogMode);
        return juce::var(obj);
    }

    ModulatorParams varToParams(const juce::var& obj) const override {
        EnvelopeParams p;
        if (const auto* o = obj.getDynamicObject()) {
            auto readFloat = [&](const char* key, float fallback) -> float {
                const auto v = o->getProperty(key);
                return (v.isDouble() || v.isInt()) ? static_cast<float>(static_cast<double>(v)) : fallback;
            };
            auto readInt = [&](const char* key, int fallback) -> int {
                const auto v = o->getProperty(key);
                return (v.isDouble() || v.isInt()) ? static_cast<int>(static_cast<double>(v)) : fallback;
            };
            p.curveType = readInt("curveType", 0);
            p.attack = readFloat("attack", 0.08f);
            p.hold = readFloat("hold", 0.0f);
            p.decay = readFloat("decay", 0.22f);
            p.sustain = readFloat("sustain", 0.65f);
            p.release = readFloat("release", 0.28f);
            p.delay = readFloat("delay", 0.0f);
            p.attackCurve = readFloat("attackCurve", 0.5f);
            p.decayCurve = readFloat("decayCurve", 0.5f);
            p.releaseCurve = readFloat("releaseCurve", 0.5f);
            p.analogMode = readInt("analogMode", 0);
        }
        return p;
    }
};

} // namespace audioapp