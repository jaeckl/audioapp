#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

struct TremoloParams {
    double depth  = 0.5;   // 0.0 – 1.0
    double rateHz = 5.0;   // 0.1 – 20.0
    double shape  = 0.0;   // 0.0 = sine, 1.0 = square

    void clamp() {
        depth  = juce::jlimit(0.0, 1.0, depth);
        rateHz = juce::jlimit(0.1, 20.0, rateHz);
        shape  = juce::jlimit(0.0, 1.0, shape);
    }

    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("depth",  depth);
        obj->setProperty("rateHz", rateHz);
        obj->setProperty("shape",  shape);
        return juce::var(obj);
    }

    static TremoloParams fromJson(const juce::var& v) {
        TremoloParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            p.depth  = obj->getProperty("depth").toString().getDoubleValue();
            p.rateHz = obj->getProperty("rateHz").toString().getDoubleValue();
            p.shape  = obj->getProperty("shape").toString().getDoubleValue();
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
