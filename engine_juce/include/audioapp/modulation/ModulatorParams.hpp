#pragma once

#include <variant>

namespace audioapp {

/// Persistent LFO parameters.
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
    float morph = 0.0f;       // [0,1]: 0=sine, 0.25=tri, 0.5=saw, 0.75=sq, 1.0=ramp
    float spread = 0.5f;      // [0,1]: 0.5=symmetric, <0.5 skew left, >0.5 skew right
    int analogMode = 0;       // 0=digital, 1=analog
};

/// Unified envelope parameters (ADSR / ASR / ADR / AHDSR).
struct EnvelopeParams {
    float attack = 0.08f;
    float hold = 0.0f;         // AHDSR only
    float decay = 0.22f;
    float sustain = 0.65f;     // level for ADSR/AHDSR/ASR, ignored for ADR
    float release = 0.28f;
    float delay = 0.0f;        // pre-delay before attack
    float attackCurve = 0.5f;  // curvature: 0=concave, 0.5=linear, 1=convex (digital only)
    float decayCurve = 0.5f;
    float releaseCurve = 0.5f;
    int curveType = 0;         // EnvelopeCurve enum: 0=ADSR, 1=ASR, 2=ADR, 3=AHDSR
    int analogMode = 0;        // 0=digital (adjustable curves), 1=analog (fixed RC-style curves)
};

using ModulatorParams = std::variant<LfoParams, EnvelopeParams>;

} // namespace audioapp