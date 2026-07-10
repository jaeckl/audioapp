#pragma once

#include <juce_core/juce_core.h>

namespace audioapp {

struct ReverbParams {
    double modeMorph = 2.0;
    double decay = 0.56;
    double preDelay = 0.112;
    double size = 0.64;
    double diffusion = 0.78;
    double damping = 0.68;
    double modulation = 0.18;
    double lowCut = 0.26;
    double highCut = 0.86;
    double ducking = 0.25;
    double freeze = 0.0;

    void clamp() noexcept {
        modeMorph = juce::jlimit(0.0, 3.0, modeMorph);
        decay = juce::jlimit(0.0, 1.0, decay);
        preDelay = juce::jlimit(0.0, 1.0, preDelay);
        size = juce::jlimit(0.0, 1.0, size);
        diffusion = juce::jlimit(0.0, 1.0, diffusion);
        damping = juce::jlimit(0.0, 1.0, damping);
        modulation = juce::jlimit(0.0, 1.0, modulation);
        lowCut = juce::jlimit(0.0, 1.0, lowCut);
        highCut = juce::jlimit(0.0, 1.0, highCut);
        ducking = juce::jlimit(0.0, 1.0, ducking);
        freeze = juce::jlimit(0.0, 1.0, freeze);
    }

    juce::var toJson() const {
        auto* obj = new juce::DynamicObject();
        obj->setProperty("modeMorph", modeMorph);
        obj->setProperty("decay", decay);
        obj->setProperty("preDelay", preDelay);
        obj->setProperty("size", size);
        obj->setProperty("diffusion", diffusion);
        obj->setProperty("damping", damping);
        obj->setProperty("modulation", modulation);
        obj->setProperty("lowCut", lowCut);
        obj->setProperty("highCut", highCut);
        obj->setProperty("ducking", ducking);
        obj->setProperty("freeze", freeze);
        return juce::var(obj);
    }

    static ReverbParams fromJson(const juce::var& value) {
        ReverbParams out;
        const auto* obj = value.getDynamicObject();
        if (obj == nullptr) return out;
        auto number = [&](const char* key, double fallback) {
            const auto v = obj->getProperty(key);
            return v.isDouble() || v.isInt() || v.isInt64()
                ? static_cast<double>(v) : fallback;
        };
        const bool modern = obj->hasProperty("decay");
        if (modern) {
            out.modeMorph = number("modeMorph", out.modeMorph);
            out.decay = number("decay", out.decay);
            out.preDelay = number("preDelay", out.preDelay);
            out.size = number("size", out.size);
            out.diffusion = number("diffusion", out.diffusion);
            out.damping = number("damping", out.damping);
            out.modulation = number("modulation", out.modulation);
            out.lowCut = number("lowCut", out.lowCut);
            out.highCut = number("highCut", out.highCut);
            out.ducking = number("ducking", out.ducking);
            out.freeze = number("freeze", out.freeze);
        } else {
            const double roomSize = number("roomSize", 0.5);
            out.size = roomSize;
            out.decay = juce::jlimit(0.0, 1.0, 0.25 + roomSize * 0.55);
            out.damping = number("damping", 0.5);
        }
        out.clamp();
        return out;
    }
};

} // namespace audioapp
