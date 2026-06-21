#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

/**
    Parameters for a delay effect.
    JSON schema (see docs/features/time-based-effects-suite/04-data-contracts.md):
    {
        "timeMs":   number,   // ms, 1‑2000, default 250
        "feedback":  number,   // 0‑0.95, default 0.4
        "mix":       number    // 0‑1,   default 0.5
    }
*/
struct DelayParams {
    double delayTime = 250.0; // milliseconds
    double feedback  = 0.4;   // 0.0 – 0.95
    double mix       = 0.5;   // 0.0 – 1.0

    // Clamp values to safe ranges – called by callers or constructors.
    void clamp() {
        delayTime = juce::jlimit(1.0, 2000.0, delayTime);
        feedback  = juce::jlimit(0.0, 0.95,   feedback);
        mix       = juce::jlimit(0.0, 1.0,    mix);
    }

    /** Convert to a juce::var (DynamicObject) suitable for JSON serialisation */
    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("timeMs",   delayTime);
        obj->setProperty("feedback", feedback);
        obj->setProperty("mix",      mix);
        return juce::var(obj);
    }

    /** Create a DelayParams from a juce::var produced by toJson() */
    static DelayParams fromJson(const juce::var& v) {
        DelayParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            p.delayTime = obj->getProperty("timeMs").toString().getDoubleValue();
            p.feedback  = obj->getProperty("feedback").toString().getDoubleValue();
            p.mix       = obj->getProperty("mix").toString().getDoubleValue();
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
