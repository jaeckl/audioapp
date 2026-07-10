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
        "centreFrequencyHz":   number, // 20 – 20000, default 1000
        "rateMode":            number, // 0 free, 1 16th, 2 8th, 3 4th
        "waveform":            number, // 0 sine, 1 triangle, 2 ramp, 3 random
        "waveShape":           number, // 0.0 – 1.0
        "phaseOffset":         number, // 0.0 – 1.0 (0 – 360 degrees)
        "stereoPhase":         number, // 0.0 – 1.0 (0 – 180 degrees)
        "stages":              number  // 2 – 12
    }
*/
struct PhaserParams {
    double depth            = 0.5;
    double rateHz           = 0.8;
    double feedback         = 0.3;
    double centreFrequencyHz = 1000.0;
    double rateMode         = 0.0;
    double waveform         = 0.0;
    double waveShape        = 0.5;
    double phaseOffset      = 0.0;
    double stereoPhase      = 0.75;
    double stages           = 8.0;

    void clamp() {
        depth            = juce::jlimit(0.0, 1.0, depth);
        rateHz           = juce::jlimit(0.05, 10.0, rateHz);
        feedback         = juce::jlimit(0.0, 0.95, feedback);
        centreFrequencyHz = juce::jlimit(20.0, 20000.0, centreFrequencyHz);
        rateMode         = juce::jlimit(0.0, 3.0, rateMode);
        waveform         = juce::jlimit(0.0, 3.0, waveform);
        waveShape        = juce::jlimit(0.0, 1.0, waveShape);
        phaseOffset      = juce::jlimit(0.0, 1.0, phaseOffset);
        stereoPhase      = juce::jlimit(0.0, 1.0, stereoPhase);
        stages           = juce::jlimit(2.0, 12.0, stages);
    }

    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("depth",            depth);
        obj->setProperty("rateHz",           rateHz);
        obj->setProperty("feedback",         feedback);
        obj->setProperty("centreFrequencyHz", centreFrequencyHz);
        obj->setProperty("rateMode", rateMode);
        obj->setProperty("waveform", waveform);
        obj->setProperty("waveShape", waveShape);
        obj->setProperty("phaseOffset", phaseOffset);
        obj->setProperty("stereoPhase", stereoPhase);
        obj->setProperty("stages", stages);
        return juce::var(obj);
    }

    static PhaserParams fromJson(const juce::var& v) {
        PhaserParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            auto read = [obj](const char* key, double fallback) {
                const auto value = obj->getProperty(key);
                return value.isDouble() || value.isInt() || value.isInt64()
                    ? static_cast<double>(value) : fallback;
            };
            p.depth = read("depth", p.depth);
            p.rateHz = read("rateHz", p.rateHz);
            p.feedback = read("feedback", p.feedback);
            p.centreFrequencyHz = read("centreFrequencyHz", p.centreFrequencyHz);
            p.rateMode = read("rateMode", p.rateMode);
            p.waveform = read("waveform", p.waveform);
            p.waveShape = read("waveShape", p.waveShape);
            p.phaseOffset = read("phaseOffset", p.phaseOffset);
            p.stereoPhase = read("stereoPhase", p.stereoPhase);
            p.stages = read("stages", p.stages);
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
