#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

struct DistortionParams {
    double drive = 0.5;  // 0.0 – 1.0
    double tone  = 0.5;  // 0.0 – 1.0 (low-pass filter cutoff)
    double mix   = 0.5;  // 0.0 – 1.0

    void clamp() {
        drive = juce::jlimit(0.0, 1.0, drive);
        tone  = juce::jlimit(0.0, 1.0, tone);
        mix   = juce::jlimit(0.0, 1.0, mix);
    }

    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("drive", drive);
        obj->setProperty("tone",  tone);
        obj->setProperty("mix",   mix);
        return juce::var(obj);
    }

    static DistortionParams fromJson(const juce::var& v) {
        DistortionParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            p.drive = obj->getProperty("drive").toString().getDoubleValue();
            p.tone  = obj->getProperty("tone").toString().getDoubleValue();
            p.mix   = obj->getProperty("mix").toString().getDoubleValue();
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
