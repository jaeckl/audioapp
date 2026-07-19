#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

struct DcOffsetParams {
    double mode = 1.0;
    double amount = 1.0;
    double cutoff = 0.3;

    void clamp() {
        mode = juce::jlimit(0.0, 1.0, mode);
        amount = juce::jlimit(0.0, 1.0, amount);
        cutoff = juce::jlimit(0.0, 1.0, cutoff);
    }

    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("mode", mode);
        obj->setProperty("amount", amount);
        obj->setProperty("cutoff", cutoff);
        return juce::var(obj);
    }

    static DcOffsetParams fromJson(const juce::var& v) {
        DcOffsetParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            p.mode = obj->getProperty("mode").toString().getDoubleValue();
            p.amount = obj->getProperty("amount").toString().getDoubleValue();
            p.cutoff = obj->getProperty("cutoff").toString().getDoubleValue();
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
