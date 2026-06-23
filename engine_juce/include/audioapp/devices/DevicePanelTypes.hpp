#pragma once

#include <variant>
#include <algorithm>
#include <cmath>

#include <juce_core/juce_core.h>

#include "audioapp/dsp/AudioBlock.hpp"

namespace audioapp {

// ── Input panel alternatives ──────────────────────────────────────────

/// Empty input panel — used for devices with no input-stage controls.
struct EmptyPanel {
    template <typename Callback>
    void enumerate(Callback&& /*cb*/) const {
        // no-op
    }
};

/// Input trim + metering for dynamics processors.
struct DynamicsInputPanel {
    float trim = 1.0f;           // input gain trim, [0, 1]

    template <typename Callback>
    void enumerate(Callback&& cb) const {
        cb("trim", trim);
    }
};

// ── Output panel alternatives ─────────────────────────────────────────

/// Mono output — gain only. Used for mono drum generators (kick, snare, etc.).
struct MonoOutputPanel {
    float gain = 1.0f;           // output gain, [0, 1]

    template <typename Callback>
    void enumerate(Callback&& cb) const {
        cb("gain", gain);
    }

    /// Apply per-frame gain from scratch to both stereo channels (centre pan).
    static void applyFromScratch(float* scratch, AudioBlock& block, int frames,
                                  const float* perFrameGain) noexcept {
        for (int f = 0; f < frames; ++f) {
            const float g = scratch[f] * perFrameGain[f];
            block.channelL[f] += g;
            block.channelR[f] += g;
        }
    }

    /// Apply per-frame gain in-place on an already-stereo AudioBlock.
    static void applyInPlace(AudioBlock& block, int frames, const float* perFrameGain) noexcept {
        for (int i = 0; i < frames; ++i) {
            block.channelL[i] *= perFrameGain[i];
            block.channelR[i] *= perFrameGain[i];
        }
    }
};

/// Stereo output — gain + pan. Used for all stereo-capable devices.
struct StereoOutputPanel {
    float gain = 1.0f;           // output gain, [0, 1]
    float pan  = 0.5f;           // pan, [0, 1] where 0.5 = centre

    template <typename Callback>
    void enumerate(Callback&& cb) const {
        cb("gain", gain);
        cb("pan",  pan);
    }

    /// Apply per-frame gain + pan from a mono scratch buffer to a stereo AudioBlock.
    static void applyFromScratch(float* scratch, AudioBlock& block, int frames,
                                  const float* perFrameGain, const float* perFramePan) noexcept {
        for (int f = 0; f < frames; ++f) {
            const float g = scratch[f] * perFrameGain[f];
            const float angle = std::clamp(perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
            block.channelL[f] += g * std::cos(angle);
            block.channelR[f] += g * std::sin(angle);
        }
    }

    /// Apply per-frame gain in-place on an already-stereo AudioBlock.
    static void applyInPlace(AudioBlock& block, int frames, const float* perFrameGain) noexcept {
        for (int i = 0; i < frames; ++i) {
            block.channelL[i] *= perFrameGain[i];
            block.channelR[i] *= perFrameGain[i];
        }
    }
};

// ── Variant aliases ───────────────────────────────────────────────────

using InputPanelParams  = std::variant<EmptyPanel, DynamicsInputPanel>;
using OutputPanelParams = std::variant<EmptyPanel, MonoOutputPanel, StereoOutputPanel>;

// ── Serialization helpers ─────────────────────────────────────────────

inline juce::var inputPanelToVar(const InputPanelParams& panel) {
    auto* obj = new juce::DynamicObject();
    std::visit([&](const auto& p) {
        using T = std::decay_t<decltype(p)>;
        if constexpr (std::is_same_v<T, DynamicsInputPanel>) {
            obj->setProperty("type", "dynamics");
            obj->setProperty("trim", static_cast<double>(p.trim));
        } else {
            obj->setProperty("type", "empty");
        }
    }, panel);
    return juce::var(obj);
}

inline InputPanelParams inputPanelFromVar(const juce::var& obj, float legacyInputGain = -1.0f) {
    if (const auto* o = obj.getDynamicObject()) {
        auto typeStr = o->getProperty("type").toString().toStdString();
        if (typeStr == "dynamics") {
            DynamicsInputPanel p;
            auto trimVal = o->getProperty("trim");
            if (trimVal.isDouble() || trimVal.isInt())
                p.trim = static_cast<float>(static_cast<double>(trimVal));
            return p;
        }
    }
    if (legacyInputGain >= 0.0f) {
        DynamicsInputPanel p;
        p.trim = legacyInputGain;
        return p;
    }
    return EmptyPanel{};
}

inline juce::var outputPanelToVar(const OutputPanelParams& panel) {
    auto* obj = new juce::DynamicObject();
    std::visit([&](const auto& p) {
        using T = std::decay_t<decltype(p)>;
        if constexpr (std::is_same_v<T, MonoOutputPanel>) {
            obj->setProperty("type", "mono");
            obj->setProperty("gain", static_cast<double>(p.gain));
        } else if constexpr (std::is_same_v<T, StereoOutputPanel>) {
            obj->setProperty("type", "stereo");
            obj->setProperty("gain", static_cast<double>(p.gain));
            obj->setProperty("pan", static_cast<double>(p.pan));
        } else {
            obj->setProperty("type", "empty");
        }
    }, panel);
    return juce::var(obj);
}

inline OutputPanelParams outputPanelFromVar(const juce::var& obj, float legacyGain = 1.0f, float legacyPan = 0.5f) {
    if (const auto* o = obj.getDynamicObject()) {
        auto typeStr = o->getProperty("type").toString().toStdString();
        auto readFloat = [&](const char* key, float fallback) -> float {
            const auto v = o->getProperty(key);
            if (v.isDouble() || v.isInt() || v.isInt64())
                return static_cast<float>(static_cast<double>(v));
            return fallback;
        };
        if (typeStr == "mono") {
            return MonoOutputPanel{ readFloat("gain", 1.0f) };
        } else if (typeStr == "stereo") {
            return StereoOutputPanel{ readFloat("gain", 1.0f), readFloat("pan", 0.5f) };
        }
    }
    // Legacy fallback
    return StereoOutputPanel{ legacyGain, legacyPan };
}

} // namespace audioapp