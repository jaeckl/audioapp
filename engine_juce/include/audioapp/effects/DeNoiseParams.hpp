#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

struct DeNoiseParams {
    double threshold = 0.35;
    double reduction = 0.5;
    double smoothing = 0.4;

    void clamp() {
        threshold = juce::jlimit(0.0, 1.0, threshold);
        reduction = juce::jlimit(0.0, 1.0, reduction);
        smoothing = juce::jlimit(0.0, 1.0, smoothing);
    }

    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("threshold", threshold);
        obj->setProperty("reduction", reduction);
        obj->setProperty("smoothing", smoothing);
        return juce::var(obj);
    }

    static DeNoiseParams fromJson(const juce::var& v) {
        DeNoiseParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            p.threshold = obj->getProperty("threshold").toString().getDoubleValue();
            p.reduction = obj->getProperty("reduction").toString().getDoubleValue();
            p.smoothing = obj->getProperty("smoothing").toString().getDoubleValue();
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
