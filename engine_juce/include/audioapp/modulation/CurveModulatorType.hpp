#pragma once

#include <juce_core/juce_core.h>

#include "audioapp/modulation/IModulatorType.hpp"
#include "audioapp/modulation/CurveModulator.hpp"

namespace audioapp {

/// Control-thread descriptor for Curve (user-drawn breakpoint) modulators.
class CurveModulatorType : public IModulatorType {
public:
    std::string typeId() const override { return "curve"; }
    int modulatorTypeValue() const override { return 4; }

    ModulatorParams createDefault() const override {
        CurveParams p;
        p.rate = 0.5f;
        p.retrigger = 1;
        p.syncDivision = 3;
        p.polarity = 0;
        p.smoothing = 0.0f;
        p.breakpointCount = 2;
        p.breakpoints[0] = {0.0f, 0.0f, 0};
        p.breakpoints[1] = {1.0f, 1.0f, 0};
        return p;
    }

    bool setParameter(ModulatorParams& params, std::string_view paramId, float value) const override {
        auto& p = std::get<CurveParams>(params);
        if (paramId == "rate") { p.rate = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "retrigger") { p.retrigger = std::clamp(static_cast<int>(value), 0, 2); return true; }
        if (paramId == "syncDivision") { p.syncDivision = std::clamp(static_cast<int>(value), 0, 5); return true; }
        if (paramId == "polarity") { p.polarity = std::clamp(static_cast<int>(value), 0, 1); return true; }
        if (paramId == "smoothing") { p.smoothing = std::clamp(value, 0.0f, 1.0f); return true; }
        if (paramId == "breakpointCount") { p.breakpointCount = std::clamp(static_cast<int>(value), 2, 32); return true; }
        if (paramId.size() > 4) {
            const auto prefix = paramId.substr(0, 4);
            if (prefix == "bp_") {
                const auto rest = paramId.substr(4);
                auto usPos = rest.find('_');
                if (usPos != std::string_view::npos) {
                    int idx = 0;
                    for (char c : rest.substr(0, usPos)) {
                        if (c < '0' || c > '9') return false;
                        idx = idx * 10 + (c - '0');
                    }
                    if (idx < 0 || idx >= 32) return false;
                    const auto attr = rest.substr(usPos + 1);
                    if (attr == "pos") {
                        p.breakpoints[idx].position = std::clamp(value, 0.0f, 1.0f);
                        return true;
                    }
                    if (attr == "val") {
                        p.breakpoints[idx].value = std::clamp(value, -1.0f, 1.0f);
                        return true;
                    }
                    if (attr == "shape") {
                        p.breakpoints[idx].shape = std::clamp(static_cast<int>(value), 0, 2);
                        return true;
                    }
                }
            }
        }
        return false;
    }

    IModulator* createModulator(ModulatorArena& arena, const ModulatorParams& params) const override {
        return arena.emplace<CurveModulator>(std::get<CurveParams>(params));
    }

    juce::var paramsToVar(const ModulatorParams& params) const override {
        const auto& p = std::get<CurveParams>(params);
        auto* obj = new juce::DynamicObject();
        obj->setProperty("rate", static_cast<double>(p.rate));
        obj->setProperty("retrigger", p.retrigger);
        obj->setProperty("syncDivision", p.syncDivision);
        obj->setProperty("polarity", p.polarity);
        obj->setProperty("smoothing", static_cast<double>(p.smoothing));
        obj->setProperty("breakpointCount", p.breakpointCount);
        for (int i = 0; i < p.breakpointCount; ++i) {
            const auto posKey = "bp_" + std::to_string(i) + "_pos";
            const auto valKey = "bp_" + std::to_string(i) + "_val";
            const auto shapeKey = "bp_" + std::to_string(i) + "_shape";
            obj->setProperty(posKey.c_str(), static_cast<double>(p.breakpoints[i].position));
            obj->setProperty(valKey.c_str(), static_cast<double>(p.breakpoints[i].value));
            obj->setProperty(shapeKey.c_str(), p.breakpoints[i].shape);
        }
        obj->setProperty("type", "curve");
        return juce::var(obj);
    }

    ModulatorParams varToParams(const juce::var& obj) const override {
        CurveParams p;
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
            p.retrigger = readInt("retrigger", 1);
            p.syncDivision = readInt("syncDivision", 3);
            p.polarity = readInt("polarity", 0);
            p.smoothing = readFloat("smoothing", 0.0f);
            p.breakpointCount = std::clamp(readInt("breakpointCount", 2), 2, 32);
            for (int i = 0; i < p.breakpointCount; ++i) {
                const auto pk = "bp_" + std::to_string(i) + "_";
                p.breakpoints[i].position = readFloat((pk + "pos").c_str(),
                    i == 0 ? 0.0f : (i == p.breakpointCount - 1 ? 1.0f : 0.5f));
                p.breakpoints[i].value = readFloat((pk + "val").c_str(), 0.0f);
                p.breakpoints[i].shape = readInt((pk + "shape").c_str(), 0);
            }
        }
        return p;
    }
};

} // namespace audioapp