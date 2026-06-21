#pragma once

#include "audioapp/PhaseModSynth.hpp"

#include <array>

namespace audioapp {

struct PhaseModSynthOperatorState {
    float ratio = 0.0625f;      // normalized [0,1] → {0.5..8.0}
    float fine = 0.5f;          // normalized [0,1] → -50..+50 cents
    float level = 0.8f;
    float wave = 0.0f;
    float attack = 0.01f;
    float decay = 0.3f;
    float sustain = 0.8f;
    float release = 0.4f;
    float velocitySense = 1.0f;
    float keyTrack = 0.0f;
};

struct PhaseModSynthInstance {
    std::array<PhaseModSynthOperatorState, 4> op{};

    int algoIndex = 0;
    float feedback = 0.0f;

    // Filter (shared with existing system)
    float filterCutoff = 0.85f;
    float filterQ = 0.25f;
    float filterMode = 0.0f;
    float filterEnvAmount = 0.5f;
    float filterAttack = 0.05f;
    float filterDecay = 0.35f;
    float filterSustain = 0.4f;
    float filterRelease = 0.45f;
    float filterKeyTrack = 0.0f;

    // Amp
    float ampAttack = 0.01f;
    float ampDecay = 0.3f;
    float ampSustain = 0.75f;
    float ampRelease = 0.35f;

    // Performance
    float glideMs = 0.0f;
    float velocitySensitivity = 1.0f;
    float unisonVoices = 0.0f;
    float unisonDetune = 0.15f;
    float synthMono = 0.0f;
    float synthLegato = 0.0f;

    // Global
    float masterVol = 0.85f;

    // LFO
    float lfoRate = 0.2f;
    float lfoShape = 0.0f;
    float lfoAmount = 0.0f;
    int lfoDest = 0;
    float vibratoDepth = 0.0f;
    float vibratoRate = 0.3f;

    PhaseModSynthParams toPlaybackParams() const;
};

} // namespace audioapp