#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

struct DeCracklerParams {
    double sensitivity = 0.5;
    double strength = 0.6;
    double width = 0.4;

    void clamp() {
        sensitivity = juce::jlimit(0.0, 1.0, sensitivity);
        strength = juce::jlimit(0.0, 1.0, strength);
        width = juce::jlimit(0.0, 1.0, width);
    }

    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("sensitivity", sensitivity);
        obj->setProperty("strength", strength);
        obj->setProperty("width", width);
        return juce::var(obj);
    }

    static DeCracklerParams fromJson(const juce::var& v) {
        DeCracklerParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            p.sensitivity = obj->getProperty("sensitivity").toString().getDoubleValue();
            p.strength = obj->getProperty("strength").toString().getDoubleValue();
            p.width = obj->getProperty("width").toString().getDoubleValue();
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
