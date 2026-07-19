#pragma once

#include <variant>
#include <algorithm>
#include <cmath>

#include <juce_core/juce_core.h>

#include "audioapp/dsp/AudioBlock.hpp"
#include "audioapp/dsp/CommonControlBlock.hpp"

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
            const float g = scratch[f] * (perFrameGain != nullptr ? perFrameGain[f] : 1.0f);
            block.channelL[f] += g;
            block.channelR[f] += g;
        }
    }

    /// Apply per-frame gain in-place on an already-stereo AudioBlock.
    static void applyInPlace(AudioBlock& block, int frames, const float* perFrameGain) noexcept {
        for (int i = 0; i < frames; ++i) {
            block.channelL[i] *= perFrameGain != nullptr ? perFrameGain[i] : 1.0f;
            block.channelR[i] *= perFrameGain != nullptr ? perFrameGain[i] : 1.0f;
        }
    }
};

/// Stereo output — gain + pan + outputMix + outputWidth.
struct StereoOutputPanel {
    float gain = 1.0f;           // output gain, [0, 1]
    float pan  = 0.5f;           // pan, [0, 1] where 0.5 = centre
    float outputMix = 1.0f;      // dry/wet mix, [0, 1]
    float outputWidth = 1.0f;    // stereo width, [0, 1]

    template <typename Callback>
    void enumerate(Callback&& cb) const {
        cb("gain", gain);
        cb("pan",  pan);
        cb("outputMix", outputMix);
        cb("outputWidth", outputWidth);
    }

    /// Apply per-frame gain + pan from a mono scratch buffer to a stereo AudioBlock.
    static void applyFromScratch(float* scratch, AudioBlock& block, int frames,
                                  const float* perFrameGain, const float* perFramePan) noexcept {
        for (int f = 0; f < frames; ++f) {
            const float g = scratch[f] * (perFrameGain != nullptr ? perFrameGain[f] : 1.0f);
            const float angle = std::clamp(perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
            block.channelL[f] += g * std::cos(angle);
            block.channelR[f] += g * std::sin(angle);
        }
    }

    /// Apply the compact common-control descriptor without forcing constant
    /// or one-block ramp values through materialized scratch arrays.
    static void applyFromScratch(float* scratch, AudioBlock& block, int frames,
                                  const CommonControlBlock& controls,
                                  bool applyGain = true) noexcept {
        for (int f = 0; f < frames; ++f) {
            const float gain = applyGain ? controls.gainAt(f) : 1.0f;
            const float sample = scratch[f] * gain;
            const float angle = std::clamp(controls.panAt(f), 0.0f, 1.0f) *
                1.57079632679f;
            block.channelL[f] += sample * std::cos(angle);
            block.channelR[f] += sample * std::sin(angle);
        }
    }

    /// Apply per-frame gain in-place on an already-stereo AudioBlock.
    static void applyInPlace(AudioBlock& block, int frames, const float* perFrameGain) noexcept {
        for (int i = 0; i < frames; ++i) {
            block.channelL[i] *= perFrameGain != nullptr ? perFrameGain[i] : 1.0f;
            block.channelR[i] *= perFrameGain != nullptr ? perFrameGain[i] : 1.0f;
        }
    }
};

/// Visual-only output cap for routing receivers. It deliberately exposes no
/// DSP parameters; the matching Flutter chrome keeps the card symmetrical.
struct RoutingOutputPanel {
    template <typename Callback>
    void enumerate(Callback&& /*cb*/) const {}
};

/// Mix-only output with PRE FX / POST FX virtual strips (chrome toggles).
/// Dry = device input (before PRE); wet = after POST. Mix blends them.
struct PrePostMixOutputPanel {
    float outputMix = 1.0f; // dry/wet, [0, 1]

    template <typename Callback>
    void enumerate(Callback&& cb) const {
        cb("outputMix", outputMix);
    }
};

// ── Variant aliases ───────────────────────────────────────────────────

using InputPanelParams  = std::variant<EmptyPanel, DynamicsInputPanel>;
using OutputPanelParams = std::variant<EmptyPanel, MonoOutputPanel, StereoOutputPanel,
                                       RoutingOutputPanel, PrePostMixOutputPanel>;

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
            obj->setProperty("outputMix", static_cast<double>(p.outputMix));
            obj->setProperty("outputWidth", static_cast<double>(p.outputWidth));
        } else if constexpr (std::is_same_v<T, RoutingOutputPanel>) {
            obj->setProperty("type", "routing");
        } else if constexpr (std::is_same_v<T, PrePostMixOutputPanel>) {
            obj->setProperty("type", "pre_post_mix");
            obj->setProperty("outputMix", static_cast<double>(p.outputMix));
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
            StereoOutputPanel sp;
            sp.gain = readFloat("gain", 1.0f);
            sp.pan = readFloat("pan", 0.5f);
            sp.outputMix = readFloat("outputMix", 1.0f);
            sp.outputWidth = readFloat("outputWidth", 1.0f);
            return sp;
        } else if (typeStr == "routing") {
            return RoutingOutputPanel{};
        } else if (typeStr == "pre_post_mix") {
            return PrePostMixOutputPanel{ readFloat("outputMix", 1.0f) };
        }
    }
    // Legacy fallback
    return StereoOutputPanel{ legacyGain, legacyPan };
}

} // namespace audioapp
