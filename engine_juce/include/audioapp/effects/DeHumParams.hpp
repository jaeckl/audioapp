#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

struct DeHumParams {
    double mainsFreq = 0.0;
    double depth = 0.7;
    double harmonics = 0.4;

    void clamp() {
        mainsFreq = juce::jlimit(0.0, 1.0, mainsFreq);
        depth = juce::jlimit(0.0, 1.0, depth);
        harmonics = juce::jlimit(0.0, 1.0, harmonics);
    }

    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("mainsFreq", mainsFreq);
        obj->setProperty("depth", depth);
        obj->setProperty("harmonics", harmonics);
        return juce::var(obj);
    }

    static DeHumParams fromJson(const juce::var& v) {
        DeHumParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            p.mainsFreq = obj->getProperty("mainsFreq").toString().getDoubleValue();
            p.depth = obj->getProperty("depth").toString().getDoubleValue();
            p.harmonics = obj->getProperty("harmonics").toString().getDoubleValue();
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
