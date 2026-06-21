#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

/**
    Parameters for a chorus effect.
    JSON schema (see docs/features/time-based-effects-suite/04-data-contracts.md):
    {
        "depth":          number, // 0.0 – 1.0, default 0.25
        "rateHz":         number, // 0.1 – 5.0, default 1.5
        "mix":            number, // 0.0 – 1.0, default 0.4
        "centreDelayMs":  number, // 0 – 20, default 7.0
        "feedback":       number  // 0.0 – 0.95, default 0.0 (optional)
    }
*/
struct ChorusParams {
    double depth          = 0.25;
    double rateHz         = 1.5;
    double mix            = 0.4;
    double centreDelayMs  = 7.0;
    double feedback       = 0.0; // optional

    void clamp() {
        depth         = juce::jlimit(0.0, 1.0, depth);
        rateHz        = juce::jlimit(0.1, 5.0, rateHz);
        mix           = juce::jlimit(0.0, 1.0, mix);
        centreDelayMs = juce::jlimit(0.0, 20.0, centreDelayMs);
        feedback      = juce::jlimit(0.0, 0.95, feedback);
    }

    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("depth",         depth);
        obj->setProperty("rateHz",        rateHz);
        obj->setProperty("mix",           mix);
        obj->setProperty("centreDelayMs", centreDelayMs);
        obj->setProperty("feedback",      feedback);
        return juce::var(obj);
    }

    static ChorusParams fromJson(const juce::var& v) {
        ChorusParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            p.depth         = obj->getProperty("depth").toString().getDoubleValue();
            p.rateHz        = obj->getProperty("rateHz").toString().getDoubleValue();
            p.mix           = obj->getProperty("mix").toString().getDoubleValue();
            p.centreDelayMs = obj->getProperty("centreDelayMs").toString().getDoubleValue();
            p.feedback      = obj->getProperty("feedback").toString().getDoubleValue();
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
