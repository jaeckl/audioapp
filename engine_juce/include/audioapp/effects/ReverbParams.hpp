#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

/**
    Parameters for a reverb effect.
    JSON schema (see docs/features/time-based-effects-suite/04-data-contracts.md):
    {
        "roomSize":   number, // 0.0 – 1.0, default 0.5
        "damping":    number, // 0.0 – 1.0, default 0.5
        "wetLevel":   number, // 0.0 – 1.0, default 0.33
        "dryLevel":   number, // 0.0 – 1.0, default 0.7
        "width":      number, // 0.0 – 1.0, default 1.0
        "freezeMode": boolean // default false
    }
*/
struct ReverbParams {
    double roomSize   = 0.5;
    double damping    = 0.5;
    double wetLevel   = 0.33;
    double dryLevel   = 0.7;
    double width      = 1.0;
    bool   freezeMode = false;

    void clamp() {
        roomSize   = juce::jlimit(0.0, 1.0, roomSize);
        damping    = juce::jlimit(0.0, 1.0, damping);
        wetLevel   = juce::jlimit(0.0, 1.0, wetLevel);
        dryLevel   = juce::jlimit(0.0, 1.0, dryLevel);
        width      = juce::jlimit(0.0, 1.0, width);
        // freezeMode is boolean, no clamping needed
    }

    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("roomSize",   roomSize);
        obj->setProperty("damping",    damping);
        obj->setProperty("wetLevel",   wetLevel);
        obj->setProperty("dryLevel",   dryLevel);
        obj->setProperty("width",      width);
        obj->setProperty("freezeMode", freezeMode);
        return juce::var(obj);
    }

    static ReverbParams fromJson(const juce::var& v) {
        ReverbParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            p.roomSize   = obj->getProperty("roomSize").toString().getDoubleValue();
            p.damping    = obj->getProperty("damping").toString().getDoubleValue();
            p.wetLevel   = obj->getProperty("wetLevel").toString().getDoubleValue();
            p.dryLevel   = obj->getProperty("dryLevel").toString().getDoubleValue();
            p.width      = obj->getProperty("width").toString().getDoubleValue();
            p.freezeMode = static_cast<bool>(obj->getProperty("freezeMode"));
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
