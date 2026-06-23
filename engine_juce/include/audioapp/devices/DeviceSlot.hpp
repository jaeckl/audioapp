#pragma once

#include <string>
#include <variant>

#include "audioapp/devices/DevicePanelTypes.hpp"

// Params types (replacing trivial Instance types)
#include "audioapp/DynamicsProcessor.hpp"   // GateParams, CompressorParams, ExpanderParams, LimiterParams
#include "audioapp/KickAlgorithm.hpp"       // KickGeneratorParams
#include "audioapp/SnareAlgorithm.hpp"      // SnareGeneratorParams
#include "audioapp/ClapAlgorithm.hpp"       // ClapGeneratorParams
#include "audioapp/CymbalAlgorithm.hpp"     // CymbalGeneratorParams
#include "audioapp/CrashAlgorithm.hpp"      // CrashGeneratorParams
#include "audioapp/SubtractiveSynthAlgorithm.hpp"    // SubtractiveSynthParams
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

/// Unified device config wrapping params, panels, and bypass.
/// Used as the single state holder inside DeviceSlot.
struct DeviceConfig {
    std::string typeId;            // canonical type identifier (e.g. "kick_generator")
    DeviceInstance instance;       // device-specific parameters
    InputPanelParams inputPanel;   // input stage panel (empty, dynamics trim, etc.)
    OutputPanelParams outputPanel; // output stage panel (mono gain, stereo gain+pan, etc.)
    bool bypassed = false;
};

struct DeviceSlot {
    std::string id;
    DeviceConfig config;
};

} // namespace audioapp