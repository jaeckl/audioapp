#pragma once

#include <array>
#include <juce_core/juce_core.h>

namespace audioapp {

struct ChorusParams {
    static constexpr int kModeCount = 4;
    static constexpr int kParamsPerMode = 6;
    using Bank = std::array<double, kParamsPerMode>;

    double modeMorph = 0.0;
    Bank classic{0.286, 0.25, 0.30, 0.0, 0.5, 0.0};
    Bank ensemble{0.25, 0.50, 0.50, 0.65, 0.25, 0.65};
    Bank dimension{0.50, 0.35, 0.80, 0.25, 0.0, 0.90};
    Bank drift{0.30, 0.50, 0.40, 0.40, 0.70, 0.60};

    Bank& bank(int mode) noexcept {
        switch (mode) {
        case 1: return ensemble;
        case 2: return dimension;
        case 3: return drift;
        default: return classic;
        }
    }
    const Bank& bank(int mode) const noexcept {
        return const_cast<ChorusParams*>(this)->bank(mode);
    }

    void clamp() {
        modeMorph = juce::jlimit(0.0, 3.0, modeMorph);
        for (int mode = 0; mode < kModeCount; ++mode)
            for (double& value : bank(mode))
                value = juce::jlimit(0.0, 1.0, value);
    }

    static juce::var bankToVar(const Bank& bank) {
        juce::Array<juce::var> values;
        for (double value : bank) values.add(value);
        return juce::var(values);
    }

    static void readBank(const juce::var& value, Bank& bank) {
        if (const auto* values = value.getArray()) {
            for (int i = 0; i < kParamsPerMode && i < values->size(); ++i)
                bank[static_cast<size_t>(i)] = static_cast<double>(values->getReference(i));
        }
    }

    juce::var toJson() const {
        auto* obj = new juce::DynamicObject();
        obj->setProperty("modeMorph", modeMorph);
        obj->setProperty("classic", bankToVar(classic));
        obj->setProperty("ensemble", bankToVar(ensemble));
        obj->setProperty("dimension", bankToVar(dimension));
        obj->setProperty("drift", bankToVar(drift));
        return juce::var(obj);
    }

    static ChorusParams fromJson(const juce::var& value) {
        ChorusParams result;
        if (const auto* obj = value.getDynamicObject()) {
            const auto mode = obj->getProperty("modeMorph");
            if (mode.isDouble() || mode.isInt() || mode.isInt64())
                result.modeMorph = static_cast<double>(mode);
            readBank(obj->getProperty("classic"), result.classic);
            readBank(obj->getProperty("ensemble"), result.ensemble);
            readBank(obj->getProperty("dimension"), result.dimension);
            readBank(obj->getProperty("drift"), result.drift);

            // Legacy chorus projects become the Classic anchor.
            if (!obj->hasProperty("classic")) {
                auto read = [&](const char* key, double fallback) {
                    const auto v = obj->getProperty(key);
                    return v.isDouble() || v.isInt() || v.isInt64()
                        ? static_cast<double>(v) : fallback;
                };
                result.classic[0] = (read("rateHz", 1.5) - 0.1) / 4.9;
                result.classic[1] = read("depth", 0.25);
                result.classic[2] = (read("centreDelayMs", 7.0) - 2.0) / 18.0;
                result.classic[3] = read("feedback", 0.0) / 0.8;
            }
            result.clamp();
        }
        return result;
    }
};

} // namespace audioapp
