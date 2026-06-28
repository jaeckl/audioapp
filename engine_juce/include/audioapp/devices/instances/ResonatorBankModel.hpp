#pragma once

#include "audioapp/ResonatorBank.hpp"
#include "audioapp/MidiUtils.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

struct ResonatorBankModel {
    float resRoot = 0.5f;
    float resSpread = 0.5f;
    float resDecay = 0.55f;
    float resDamping = 0.35f;
    float resColor = 0.5f;
    float resWidth = 0.5f;
    float resMix = 0.5f;

    ResonatorBankParams toPlaybackParams() const noexcept {
        ResonatorBankParams p;
        const float rootNote = 24.0f + std::clamp(resRoot, 0.0f, 1.0f) * 72.0f;
        p.rootHz = 440.0f * std::pow(2.0f, (rootNote - 69.0f) / 12.0f);
        p.spread = 0.5f + std::clamp(resSpread, 0.0f, 1.0f);
        p.decaySeconds = 0.08f * std::pow(150.0f, std::clamp(resDecay, 0.0f, 1.0f));
        p.damping = std::clamp(resDamping, 0.0f, 1.0f);
        p.colorDbPerOctave = (std::clamp(resColor, 0.0f, 1.0f) - 0.5f) * 24.0f;
        p.width = std::clamp(resWidth, 0.0f, 1.0f) * 2.0f;
        p.mix = std::clamp(resMix, 0.0f, 1.0f);
        return p;
    }
};

} // namespace audioapp
