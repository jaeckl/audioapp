#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

struct BitcrusherParams {
    double rate = 0.5;   // 0.0 – 1.0 (sample rate reduction factor)
    double bits = 8.0;   // 1.0 – 16.0
    double mix  = 0.5;   // 0.0 – 1.0

    void clamp() {
        rate = juce::jlimit(0.0, 1.0, rate);
        bits = juce::jlimit(1.0, 16.0, bits);
        mix  = juce::jlimit(0.0, 1.0, mix);
    }

    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("rate", rate);
        obj->setProperty("bits", bits);
        obj->setProperty("mix",  mix);
        return juce::var(obj);
    }

    static BitcrusherParams fromJson(const juce::var& v) {
        BitcrusherParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            p.rate = obj->getProperty("rate").toString().getDoubleValue();
            p.bits = obj->getProperty("bits").toString().getDoubleValue();
            p.mix  = obj->getProperty("mix").toString().getDoubleValue();
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
