#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

struct DeEsserParams {
    double freq = 0.55;
    double threshold = 0.45;
    double amount = 0.5;
    double listen = 0.0;

    void clamp() {
        freq = juce::jlimit(0.0, 1.0, freq);
        threshold = juce::jlimit(0.0, 1.0, threshold);
        amount = juce::jlimit(0.0, 1.0, amount);
        listen = juce::jlimit(0.0, 1.0, listen);
    }

    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("freq", freq);
        obj->setProperty("threshold", threshold);
        obj->setProperty("amount", amount);
        obj->setProperty("listen", listen);
        return juce::var(obj);
    }

    static DeEsserParams fromJson(const juce::var& v) {
        DeEsserParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            p.freq = obj->getProperty("freq").toString().getDoubleValue();
            p.threshold = obj->getProperty("threshold").toString().getDoubleValue();
            p.amount = obj->getProperty("amount").toString().getDoubleValue();
            p.listen = obj->getProperty("listen").toString().getDoubleValue();
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
