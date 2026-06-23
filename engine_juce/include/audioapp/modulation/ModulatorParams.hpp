#pragma once

#include <variant>

namespace audioapp {

/// Persistent LFO parameters (matches current LfoState fields for an LFO-type modulator).
struct LfoParams {
    int waveform = 0;          // LfoWaveform enum: 0=Sine, 1=Tri, 2=Saw, 3=Square, 4=Ramp
    float rate = 1.0f;
    int syncDivision = 3;      // 1=whole, 2=half, 3=quarter, 4=eighth, 5=sixteenth, 0=none
    int retrigger = 1;         // ModulatorRetrigger enum: 0=Free, 1=Sync, 2=OnNote
    float phase = 0.0f;
    int polarity = 0;          // 0=bipolar, 1=unipolar-pos, 2=unipolar-neg
    float attack = 0.1f;
    float decay = 0.25f;
    float sustain = 0.7f;
    float release = 0.35f;
};

/// Persistent ADSR envelope parameters.
struct AdsrParams {
    float attack = 0.08f;
    float decay = 0.22f;
    float sustain = 0.65f;
    float release = 0.28f;
    int polarity = 0;          // 0=bipolar, 1=unipolar-pos, 2=unipolar-neg
};

/// Persistent ADR envelope parameters (no sustain stage).
struct AdrParams {
    float attack = 0.08f;
    float decay = 0.22f;
    float release = 0.28f;
    int polarity = 0;          // 0=bipolar, 1=unipolar-pos, 2=unipolar-neg
};

using ModulatorParams = std::variant<LfoParams, AdsrParams, AdrParams>;

} // namespace audioapp