#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

/**
    Parameters for a phaser effect.
    JSON schema (see docs/features/time-based-effects-suite/04-data-contracts.md):
    {
        "depth":               number, // 0.0 – 1.0, default 0.5
        "rateHz":              number, // 0.1 – 5.0, default 0.8
        "feedback":            number, // 0.0 – 0.95, default 0.3
        "centreFrequencyHz":   number  // 20 – 20000, default 1000
    }
*/
struct PhaserParams {
    double depth            = 0.5;
    double rateHz           = 0.8;
    double feedback         = 0.3;
    double centreFrequencyHz = 1000.0;

    void clamp() {
        depth            = juce::jlimit(0.0, 1.0, depth);
        rateHz           = juce::jlimit(0.1, 5.0, rateHz);
        feedback         = juce::jlimit(0.0, 0.95, feedback);
        centreFrequencyHz = juce::jlimit(20.0, 20000.0, centreFrequencyHz);
    }

    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("depth",            depth);
        obj->setProperty("rateHz",           rateHz);
        obj->setProperty("feedback",         feedback);
        obj->setProperty("centreFrequencyHz", centreFrequencyHz);
        return juce::var(obj);
    }

    static PhaserParams fromJson(const juce::var& v) {
        PhaserParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            p.depth            = obj->getProperty("depth").toString().getDoubleValue();
            p.rateHz           = obj->getProperty("rateHz").toString().getDoubleValue();
            p.feedback         = obj->getProperty("feedback").toString().getDoubleValue();
            p.centreFrequencyHz = obj->getProperty("centreFrequencyHz").toString().getDoubleValue();
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
