#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

/**
    Parameters for a delay effect.
    JSON schema (see docs/features/time-based-effects-suite/04-data-contracts.md):
    {
        "timeMs":   number,   // ms, 1‑2000, default 250
        "timeMode": number,   // 0=time, 1=16th, 2=8th, 3=4th
        "noteCount": number,  // 1-8 notes in synced modes
        "blurMode": number,   // 0=off, 1=soft, 2=wide
        "feedback":  number,   // 0‑0.95, default 0.4
        "mix":       number    // 0‑1,   default 0.5
    }
*/
struct DelayParams {
    double delayTime = 250.0; // milliseconds
    double feedback  = 0.4;   // 0.0 – 0.95
    double mix       = 0.5;   // 0.0 – 1.0
    double timeMode  = 0.0;
    double noteCount = 1.0;
    double blurMode  = 0.0;
    double blurAmount = 0.5;
    double inputDucking = 0.0;
    double lowCutHz = 20.0;
    double highCutHz = 20000.0;

    // Clamp values to safe ranges – called by callers or constructors.
    void clamp() {
        delayTime = juce::jlimit(0.0, 5000.0, delayTime);
        feedback  = juce::jlimit(0.0, 0.95,   feedback);
        mix       = juce::jlimit(0.0, 1.0,    mix);
        timeMode  = juce::jlimit(0.0, 3.0, timeMode);
        noteCount = juce::jlimit(1.0, 8.0, noteCount);
        blurMode  = juce::jlimit(0.0, 2.0, blurMode);
        blurAmount = juce::jlimit(0.0, 1.0, blurAmount);
        inputDucking = juce::jlimit(0.0, 1.0, inputDucking);
        lowCutHz = juce::jlimit(20.0, 2000.0, lowCutHz);
        highCutHz = juce::jlimit(2000.0, 20000.0, highCutHz);
        if (highCutHz < lowCutHz * 2.0)
            highCutHz = juce::jmin(20000.0, lowCutHz * 2.0);
    }

    /** Convert to a juce::var (DynamicObject) suitable for JSON serialisation */
    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("timeMs",   delayTime);
        obj->setProperty("feedback", feedback);
        obj->setProperty("mix",      mix);
        obj->setProperty("timeMode", timeMode);
        obj->setProperty("noteCount", noteCount);
        obj->setProperty("blurMode", blurMode);
        obj->setProperty("blurAmount", blurAmount);
        obj->setProperty("inputDucking", inputDucking);
        obj->setProperty("lowCutHz", lowCutHz);
        obj->setProperty("highCutHz", highCutHz);
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
            p.timeMode  = obj->getProperty("timeMode").toString().getDoubleValue();
            p.noteCount = obj->getProperty("noteCount").toString().getDoubleValue();
            p.blurMode  = obj->getProperty("blurMode").toString().getDoubleValue();
            p.blurAmount = obj->getProperty("blurAmount").toString().getDoubleValue();
            p.inputDucking = obj->getProperty("inputDucking").toString().getDoubleValue();
            p.lowCutHz = obj->getProperty("lowCutHz").toString().getDoubleValue();
            p.highCutHz = obj->getProperty("highCutHz").toString().getDoubleValue();
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
