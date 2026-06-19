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

enum class ModulatorType : int {
    Lfo = 0,
    Adsr = 1,
    Adr = 2,
};

/// 0=free (Hz / per-note clock), 1=sync to project phase, 2=retrigger on note.
enum class ModulatorRetrigger : int {
    Free = 0,
    Sync = 1,
    OnNote = 2,
};

/// Persistent modulator state (control thread). Serialized as project "lfos".
struct LfoState {
    int id = 0;
    int modulatorType = 0;
    int retrigger = 0;
    int waveform = 0;
    float rate = 1.0f;
    int syncDivision = 0;
    float phase = 0.0f;
    int polarity = 0;
    float attack = 0.1f;
    float decay = 0.25f;
    float sustain = 0.7f;
    float release = 0.35f;
};

struct ModulationEdge {
    int lfoId = 0;
    std::string deviceId;
    std::string paramId;
    float amount = 0.0f;
};

} // namespace audioapp
