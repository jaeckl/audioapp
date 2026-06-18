#include "audioapp/devices/SubtractiveSynthDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/SubtractiveSynthInstance.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

std::string SubtractiveSynthDeviceType::typeId() const {
    return device_types::kSubtractiveSynth;
}

DeviceState SubtractiveSynthDeviceType::createDefault(const std::string& deviceId) const {
    DeviceState state;
    state.id = deviceId;
    SubtractiveSynthInstance instance;
    instance.ampAttack = 0.02f;
    instance.ampDecay = 0.25f;
    instance.ampSustain = 0.75f;
    instance.ampRelease = 0.35f;
    instance.filterCutoff = 0.75f;
    instance.filterQ = 0.2f;
    instance.osc1Wave = 2;
    instance.osc2Wave = 2;
    instance.osc1Shape = 0.5f;
    instance.osc2Shape = 0.5f;
    instance.osc1Level = 0.85f;
    instance.osc2Level = 0.5f;
    instance.filterEnvAmount = 0.5f;
    instance.filterAttack = 0.05f;
    instance.filterDecay = 0.35f;
    instance.filterSustain = 0.4f;
    instance.filterRelease = 0.45f;
    instance.velocitySensitivity = 1.0f;
    instance.applyTo(state);
    return state;
}

DeviceParameterResult SubtractiveSynthDeviceType::setParameter(DeviceState& state,
                                                               std::string_view parameterId,
                                                               float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(state, parameterId, value)) {
        result.handled = true;
        return result;
    }

    SubtractiveSynthInstance instance = SubtractiveSynthInstance::fromState(state);
    if (parameterId == "attack" || parameterId == "decay" || parameterId == "release" ||
        parameterId == "sustain") {
        const float clamped = std::clamp(value, 0.0f, 1.0f);
        if (parameterId == "attack") {
            instance.ampAttack = clamped;
        } else if (parameterId == "decay") {
            instance.ampDecay = clamped;
        } else if (parameterId == "release") {
            instance.ampRelease = clamped;
        } else {
            instance.ampSustain = clamped;
        }
    } else if (parameterId == "filterCutoff" || parameterId == "filterQ" ||
               parameterId == "filterEnvAmount" || parameterId == "filterAttack" ||
               parameterId == "filterDecay" || parameterId == "filterSustain" ||
               parameterId == "filterRelease" || parameterId == "osc1Octave" ||
               parameterId == "osc1Semi" || parameterId == "osc1Detune" ||
               parameterId == "osc2Octave" || parameterId == "osc2Semi" ||
               parameterId == "osc2Detune" || parameterId == "osc1Level" ||
               parameterId == "osc2Level" || parameterId == "oscMix" ||
               parameterId == "osc1Sync" || parameterId == "osc2Sync" ||
               parameterId == "noiseLevel" || parameterId == "unisonVoices" ||
               parameterId == "unisonDetune" || parameterId == "glideMs" ||
               parameterId == "velocitySensitivity") {
        const float clamped = std::clamp(value, 0.0f, 1.0f);
        if (parameterId == "filterCutoff") {
            instance.filterCutoff = clamped;
        } else if (parameterId == "filterQ") {
            instance.filterQ = clamped;
        } else if (parameterId == "filterEnvAmount") {
            instance.filterEnvAmount = clamped;
        } else if (parameterId == "filterAttack") {
            instance.filterAttack = clamped;
        } else if (parameterId == "filterDecay") {
            instance.filterDecay = clamped;
        } else if (parameterId == "filterSustain") {
            instance.filterSustain = clamped;
        } else if (parameterId == "filterRelease") {
            instance.filterRelease = clamped;
        } else if (parameterId == "osc1Octave") {
            instance.osc1Octave = clamped;
        } else if (parameterId == "osc1Semi") {
            instance.osc1Semi = clamped;
        } else if (parameterId == "osc1Detune") {
            instance.osc1Detune = clamped;
        } else if (parameterId == "osc2Octave") {
            instance.osc2Octave = clamped;
        } else if (parameterId == "osc2Semi") {
            instance.osc2Semi = clamped;
        } else if (parameterId == "osc2Detune") {
            instance.osc2Detune = clamped;
        } else if (parameterId == "osc1Level") {
            instance.osc1Level = clamped;
        } else if (parameterId == "osc2Level") {
            instance.osc2Level = clamped;
        } else if (parameterId == "oscMix") {
            instance.oscMix = clamped;
        } else if (parameterId == "osc1Sync") {
            instance.osc1Sync = clamped;
        } else if (parameterId == "osc2Sync") {
            instance.osc2Sync = clamped;
        } else if (parameterId == "noiseLevel") {
            instance.noiseLevel = clamped;
        } else if (parameterId == "unisonVoices") {
            instance.unisonVoices = clamped;
        } else if (parameterId == "unisonDetune") {
            instance.unisonDetune = clamped;
        } else if (parameterId == "glideMs") {
            instance.glideMs = clamped;
        } else {
            instance.velocitySensitivity = clamped;
        }
    } else if (parameterId == "osc1Wave") {
        instance.osc1Wave = std::clamp(static_cast<int>(std::lround(value)), 0, 4);
        instance.osc1Shape = static_cast<float>(instance.osc1Wave) / 4.0f;
    } else if (parameterId == "osc2Wave") {
        instance.osc2Wave = std::clamp(static_cast<int>(std::lround(value)), 0, 4);
        instance.osc2Shape = static_cast<float>(instance.osc2Wave) / 4.0f;
    } else if (parameterId == "osc1Shape") {
        const float clamped = std::clamp(value, 0.0f, 1.0f);
        instance.osc1Shape = clamped;
        instance.osc1Wave = std::clamp(static_cast<int>(std::lround(clamped * 4.0f)), 0, 4);
    } else if (parameterId == "osc2Shape") {
        const float clamped = std::clamp(value, 0.0f, 1.0f);
        instance.osc2Shape = clamped;
        instance.osc2Wave = std::clamp(static_cast<int>(std::lround(clamped * 4.0f)), 0, 4);
    } else if (parameterId == "oscMixMode") {
        instance.oscMixMode = std::clamp(static_cast<int>(std::lround(value)), 0, 4);
    } else {
        return result;
    }

    instance.applyTo(state);
    result.handled = true;
    return result;
}

bool SubtractiveSynthDeviceType::setStringParameter(DeviceState&,
                                                    std::string_view,
                                                    const std::string&,
                                                    const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> SubtractiveSynthDeviceType::modulatableParams() const {
    return {
        "gain", "pan", "filterCutoff", "filterQ", "attack", "decay", "sustain", "release",
        "osc1Shape", "osc2Shape", "osc1Octave", "osc1Semi", "osc1Detune", "osc2Octave",
        "osc2Semi", "osc2Detune", "osc1Level", "osc2Level", "oscMix", "osc1Sync", "osc2Sync",
        "noiseLevel", "unisonVoices", "unisonDetune", "filterEnvAmount", "filterAttack",
        "filterDecay", "filterSustain", "filterRelease", "glideMs", "velocitySensitivity",
    };
}

void SubtractiveSynthDeviceType::buildPlaybackNode(const DeviceState& state,
                                                   const PlaybackBuildContext&,
                                                   DeviceNodePlayback& out) const {
    const SubtractiveSynthInstance instance = SubtractiveSynthInstance::fromState(state);
    out.kind = DeviceNodeKind::SubtractiveSynth;
    out.params = instance.toPlaybackParams();
}

bool SubtractiveSynthDeviceType::buildLiveInstrument(const DeviceState& state,
                                                     const PlaybackBuildContext&,
                                                     LiveInstrumentSnapshot& out) const {
    const SubtractiveSynthInstance instance = SubtractiveSynthInstance::fromState(state);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::SubtractiveSynth;
    out.gain = state.gain;
    out.subtractive = instance.toPlaybackParams();
    return true;
}

} // namespace audioapp
