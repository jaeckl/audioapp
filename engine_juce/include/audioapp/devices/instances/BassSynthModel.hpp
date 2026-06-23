#pragma once

#include "audioapp/SubtractiveSynthAlgorithm.hpp"

namespace audioapp {

struct BassSynthModel {
    float gain = 1.0f;
    // TONE
    float oscShape = 0.3f;          // 0=sine → 1=pulse morph
    float subMix = 0.5f;            // 0=only osc1, 1=only sub
    int subOctave = 0;              // 0=-1oct, 1=-2oct, 2=-3oct
    float noise = 0.0f;
    float ampAttack = 0.02f;
    float ampSustain = 0.8f;
    float ampRelease = 0.35f;
    int octave = 2;                 // 0=-4, 1=-3, 2=-2, 3=-1, 4=0 semitones
    // FILTER
    float filterCutoff = 0.85f;
    float filterResonance = 0.25f;
    float filterEnvAmount = 0.6f;
    float filterDecay = 0.4f;
    // CHAR
    float drive = 0.0f;
    float squash = 0.0f;
    float glideMs = 0.0f;
    float velocitySense = 1.0f;

    SubtractiveSynthParams toPlaybackParams() const;
};

} // namespace audioapp