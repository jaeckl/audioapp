#pragma once

#include <string>

namespace audioapp {

/// LFO waveform types.
enum class LfoWaveform : int {
    Sine = 0,
    Tri,
    Saw,
    Square,
    Ramp,
};

/// Persistent LFO state (control thread).
struct LfoState {
    int id = 0;
    int waveform = 0;             // LfoWaveform as int
    float rate = 1.0f;            // Hz when syncDivision==0
    int syncDivision = 0;         // 0=Hz, 1=1/1, 2=1/2, 3=1/4, 4=1/8, 5=1/16
    float phase = 0.0f;           // initial phase offset 0..1
    int polarity = 0;             // 0=bipolar, 1=positive, 2=negative
};

/// A modulation edge: LFO id -> (deviceId, paramId, amount).
struct ModulationEdge {
    int lfoId = 0;
    std::string deviceId;
    std::string paramId;
    float amount = 0.0f;          // -1..1
};

} // namespace audioapp