#pragma once

#include <array>
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

/// Random generator (sample & hold) parameters.
struct RandomGeneratorParams {
    float rate = 0.5f;
    float smoothing = 0.0f;
    int retrigger = 1;
    int polarity = 0;
};

/// Step sequencer modulator parameters.
struct SequencerParams {
    int stepCount = 16;                     // [1, 32] active step count
    float rate = 0.5f;                      // [0, 1] normalized (Free mode Hz)
    int syncDivision = 3;                   // 0=none, 1=whole, 2=half, 3=quarter, 4=eighth, 5=sixteenth
    int retrigger = 1;                      // ModulatorRetrigger: 0=Free, 1=Sync, 2=OnNote
    int direction = 0;                      // SequencerDirection: 0=Forward, 1=Reverse, 2=PingPong, 3=Random
    int shape = 0;                          // SequencerShape: 0=Hold, 1=Linear, 2=Smooth
    int polarity = 0;                       // 0=bipolar, 1=unipolar-pos
    float smoothing = 0.0f;                 // [0, 1] single-pole lowpass coefficient
    std::array<float, 32> stepValues{};     // [0, 1] per step, initialized to 0.5
    SequencerParams() { stepValues.fill(0.5f); }
};

/// Curve (user-drawn breakpoint) modulator parameters.
struct CurveBreakpoint {
    float position = 0.0f;  // [0, 1] normalized position in cycle
    float value = 0.0f;     // [-1, 1] output value at this point
    int shape = 0;           // 0=linear, 1=smooth (cubic), 2=step
};

struct CurveParams {
    float rate = 0.5f;
    int retrigger = 1;               // ModulatorRetrigger
    int syncDivision = 3;             // 1=whole ... 5=16th, 0=none
    int polarity = 0;                 // 0=bipolar, 1=unipolar-pos
    float smoothing = 0.0f;          // [0, 1] single-pole lowpass
    int breakpointCount = 2;
    std::array<CurveBreakpoint, 32> breakpoints{};
    CurveParams() {
        breakpoints[0] = {0.0f, 0.0f, 0};
        breakpoints[1] = {1.0f, 1.0f, 0};
    }
};

using ModulatorParams = std::variant<LfoParams, EnvelopeParams, RandomGeneratorParams, SequencerParams, CurveParams>;

} // namespace audioapp