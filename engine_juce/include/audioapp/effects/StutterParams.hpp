#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

struct StutterParams {
    double trigger = 0.0;
    double captureMs = 500.0;
    double rateMs = 125.0;
    double windowMs = 80.0;
    double position = 0.0;
    double gate = 0.85;
    double fadeMs = 3.0;
    double direction = 0.0;
    double mix = 0.75;
    double duck = 0.45;
    double outputGain = 1.0;

    void clamp() {
        trigger = juce::jlimit(0.0, 1.0, trigger);
        captureMs = juce::jlimit(1.0, 4000.0, captureMs);
        rateMs = juce::jlimit(1.0, 5000.0, rateMs);
        windowMs = juce::jlimit(1.0, 5000.0, windowMs);
        position = juce::jlimit(0.0, 1.0, position);
        gate = juce::jlimit(0.0, 1.0, gate);
        fadeMs = juce::jlimit(0.0, 250.0, fadeMs);
        direction = juce::jlimit(0.0, 4.0, direction);
        mix = juce::jlimit(0.0, 1.0, mix);
        duck = juce::jlimit(0.0, 1.0, duck);
        outputGain = juce::jlimit(0.0, 2.0, outputGain);
    }
};

} // namespace audioapp
