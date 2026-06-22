#pragma once

#include <string>
#include <variant>

// Params types (replacing trivial Instance types)
#include "audioapp/DynamicsProcessor.hpp"   // GateParams, CompressorParams, ExpanderParams, LimiterParams
#include "audioapp/KickGenerator.hpp"       // KickGeneratorParams
#include "audioapp/SnareGenerator.hpp"      // SnareGeneratorParams
#include "audioapp/ClapGenerator.hpp"       // ClapGeneratorParams
#include "audioapp/CymbalGenerator.hpp"     // CymbalGeneratorParams
#include "audioapp/CrashGenerator.hpp"      // CrashGeneratorParams
#include "audioapp/SubtractiveSynth.hpp"    // SubtractiveSynthParams
#include "audioapp/DeviceChain.hpp"         // OscillatorParams, TrackGainParams
#include "audioapp/effects/DelayParams.hpp" // DelayParams
#include "audioapp/effects/ReverbParams.hpp" // ReverbParams
#include "audioapp/effects/ChorusParams.hpp" // ChorusParams
#include "audioapp/effects/PhaserParams.hpp" // PhaserParams

// Model types (non-trivial replacements)
#include "audioapp/devices/instances/SamplerModel.hpp"
#include "audioapp/devices/instances/BassSynthModel.hpp"
#include "audioapp/devices/instances/PhaseModSynthModel.hpp"
#include "audioapp/devices/instances/FrequencyFxModel.hpp" // FilterModel, FourBandEqModel, FrequencyShifterModel

namespace audioapp {

using DeviceInstance = std::variant<
    OscillatorParams,           // was OscillatorInstance
    SamplerModel,               // was SamplerInstance
    TrackGainParams,            // was TrackGainInstance
    SubtractiveSynthParams,     // was SubtractiveSynthInstance
    KickGeneratorParams,        // was KickGeneratorInstance
    SnareGeneratorParams,       // was SnareGeneratorInstance
    ClapGeneratorParams,        // was ClapGeneratorInstance
    CymbalGeneratorParams,      // was CymbalGeneratorInstance
    CrashGeneratorParams,       // was CrashGeneratorInstance
    GateParams,                 // was GateInstance
    CompressorParams,           // was CompressorInstance
    ExpanderParams,             // was ExpanderInstance
    LimiterParams,              // was LimiterInstance
    BassSynthModel,             // was BassSynthInstance
    PhaseModSynthModel,         // was PhaseModSynthInstance
    DelayParams,                // was DelayInstance
    ReverbParams,               // was ReverbInstance
    ChorusParams,               // was ChorusInstance
    PhaserParams,               // was PhaserInstance
    FilterModel,                // was FilterInstance
    FourBandEqModel,            // was FourBandEqInstance
    FrequencyShifterModel       // was FrequencyShifterInstance
>;

struct DeviceSlot {
    std::string id;
    float gain = 1.0f;
    float pan = 0.5f;
    bool bypassed = false;
    DeviceInstance instance;
};

} // namespace audioapp