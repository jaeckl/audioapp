#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

struct BitcrusherParams {
    double rate = 0.5;   // 0.0 – 1.0 (sample rate reduction factor)
    double bits = 8.0;   // 1.0 – 16.0
    double mix  = 0.5;   // 0.0 – 1.0
    double mode = 0.0;   // Classic, Impact, Sub, Organic
    double shape = 0.0;  // Linear, Soft, Fold, Step
    double jitter = 0.0;
    double drive = 0.0;
    double ditherMode = 0.0; // Off, Rect, TPDF, Shaped
    double ditherAmount = 0.0;
    double clipMode = 0.0; // Off, Soft, Hard
    double clipAmount = 0.0;
    double filter = 1.0;

    void clamp() {
        rate = juce::jlimit(0.0, 1.0, rate);
        bits = juce::jlimit(1.0, 16.0, bits);
        mix  = juce::jlimit(0.0, 1.0, mix);
        mode = juce::jlimit(0.0, 3.0, mode);
        shape = juce::jlimit(0.0, 3.0, shape);
        jitter = juce::jlimit(0.0, 1.0, jitter);
        drive = juce::jlimit(0.0, 1.0, drive);
        ditherMode = juce::jlimit(0.0, 3.0, ditherMode);
        ditherAmount = juce::jlimit(0.0, 1.0, ditherAmount);
        clipMode = juce::jlimit(0.0, 2.0, clipMode);
        clipAmount = juce::jlimit(0.0, 1.0, clipAmount);
        filter = juce::jlimit(0.0, 1.0, filter);
    }

    juce::var toJson() const {
        juce::DynamicObject* obj = new juce::DynamicObject();
        obj->setProperty("rate", rate);
        obj->setProperty("bits", bits);
        obj->setProperty("mix",  mix);
        obj->setProperty("mode", mode); obj->setProperty("shape", shape);
        obj->setProperty("jitter", jitter); obj->setProperty("drive", drive);
        obj->setProperty("ditherMode", ditherMode); obj->setProperty("ditherAmount", ditherAmount);
        obj->setProperty("clipMode", clipMode); obj->setProperty("clipAmount", clipAmount);
        obj->setProperty("filter", filter);
        return juce::var(obj);
    }

    static BitcrusherParams fromJson(const juce::var& v) {
        BitcrusherParams p;
        if (v.isObject()) {
            const auto* obj = v.getDynamicObject();
            p.rate = obj->getProperty("rate").toString().getDoubleValue();
            p.bits = obj->getProperty("bits").toString().getDoubleValue();
            p.mix  = obj->getProperty("mix").toString().getDoubleValue();
            auto read = [&](const char* key, double fallback) {
                const auto value = obj->getProperty(key);
                return (value.isDouble() || value.isInt() || value.isInt64())
                    ? static_cast<double>(value) : fallback;
            };
            p.mode = read("mode", p.mode); p.shape = read("shape", p.shape);
            p.jitter = read("jitter", p.jitter); p.drive = read("drive", p.drive);
            p.ditherMode = read("ditherMode", p.ditherMode); p.ditherAmount = read("ditherAmount", p.ditherAmount);
            p.clipMode = read("clipMode", p.clipMode); p.clipAmount = read("clipAmount", p.clipAmount);
            p.filter = read("filter", p.filter);
            p.clamp();
        }
        return p;
    }
};

} // namespace audioapp
