#include "audioapp/devices/SubtractiveSynthDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/SubtractiveSynthInstance.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {
namespace {

DeviceState stripSnapshot(const DeviceSlot& slot, std::string_view typeId) {
    DeviceState state;
    state.id = slot.id;
    state.type = std::string(typeId);
    state.gain = slot.gain;
    state.pan = slot.pan;
    state.bypassed = slot.bypassed;
    return state;
}

SubtractiveSynthInstance instanceFromSnapshot(const DeviceState& state) {
    SubtractiveSynthInstance instance;
    instance.gain = state.gain;
    instance.osc1Shape = state.osc1Shape;
    instance.osc2Shape = state.osc2Shape;
    instance.osc1Octave = state.osc1Octave;
    instance.osc1Semi = state.osc1Semi;
    instance.osc1Detune = state.osc1Detune;
    instance.osc2Octave = state.osc2Octave;
    instance.osc2Semi = state.osc2Semi;
    instance.osc2Detune = state.osc2Detune;
    instance.oscMix = state.oscMix;
    instance.osc1Sync = state.osc1Sync;
    instance.osc2Sync = state.osc2Sync;
    instance.noiseLevel = state.noiseLevel;
    instance.oscMixMode = state.oscMixMode;
    instance.unisonVoices = state.unisonVoices;
    instance.unisonDetune = state.unisonDetune;
    instance.filterMode = static_cast<float>(state.filterMode);
    instance.filterCutoff = state.filterCutoff;
    instance.filterQ = state.filterQ;
    instance.filterEnvAmount = state.filterEnvAmount;
    instance.filterAttack = state.filterAttack;
    instance.filterDecay = state.filterDecay;
    instance.filterSustain = state.filterSustain;
    instance.filterRelease = state.filterRelease;
    instance.ampAttack = state.attack;
    instance.ampDecay = state.decay;
    instance.ampSustain = state.sustain;
    instance.ampRelease = state.release;
    instance.glideMs = state.glideMs;
    instance.velocitySensitivity = state.velocitySensitivity;
    return instance;
}

void applyInstanceToSnapshot(const SubtractiveSynthInstance& instance, DeviceState& state) {
    state.osc1Shape = instance.osc1Shape;
    state.osc2Shape = instance.osc2Shape;
    state.osc1Octave = instance.osc1Octave;
    state.osc1Semi = instance.osc1Semi;
    state.osc1Detune = instance.osc1Detune;
    state.osc2Octave = instance.osc2Octave;
    state.osc2Semi = instance.osc2Semi;
    state.osc2Detune = instance.osc2Detune;
    state.oscMix = instance.oscMix;
    state.osc1Sync = instance.osc1Sync;
    state.osc2Sync = instance.osc2Sync;
    state.noiseLevel = instance.noiseLevel;
    state.oscMixMode = instance.oscMixMode;
    state.unisonVoices = instance.unisonVoices;
    state.unisonDetune = instance.unisonDetune;
    state.filterMode = static_cast<int>(instance.filterMode);
    state.filterCutoff = instance.filterCutoff;
    state.filterQ = instance.filterQ;
    state.filterEnvAmount = instance.filterEnvAmount;
    state.filterAttack = instance.filterAttack;
    state.filterDecay = instance.filterDecay;
    state.filterSustain = instance.filterSustain;
    state.filterRelease = instance.filterRelease;
    state.attack = instance.ampAttack;
    state.decay = instance.ampDecay;
    state.sustain = instance.ampSustain;
    state.release = instance.ampRelease;
    state.glideMs = instance.glideMs;
    state.velocitySensitivity = instance.velocitySensitivity;
}

} // namespace

std::string SubtractiveSynthDeviceType::typeId() const {
    return device_types::kSubtractiveSynth;
}

DeviceSlot SubtractiveSynthDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    SubtractiveSynthInstance instance;
    instance.ampAttack = 0.02f;
    instance.ampDecay = 0.25f;
    instance.ampSustain = 0.75f;
    instance.ampRelease = 0.35f;
    instance.filterCutoff = 0.75f;
    instance.filterQ = 0.2f;
    instance.osc1Shape = 0.5f;
    instance.osc2Shape = 0.5f;
    instance.filterEnvAmount = 0.5f;
    instance.filterAttack = 0.05f;
    instance.filterDecay = 0.35f;
    instance.filterSustain = 0.4f;
    instance.filterRelease = 0.45f;
    instance.velocitySensitivity = 1.0f;
    slot.instance = std::move(instance);
    return slot;
}

DeviceState SubtractiveSynthDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kSubtractiveSynth);
    applyInstanceToSnapshot(std::get<SubtractiveSynthInstance>(slot.instance), state);
    return state;
}

DeviceSlot SubtractiveSynthDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult SubtractiveSynthDeviceType::setParameter(DeviceSlot& slot,
                                                               std::string_view parameterId,
                                                               float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<SubtractiveSynthInstance>(slot.instance);
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
               parameterId == "osc2Detune" || parameterId == "oscMix" ||
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
    } else if (parameterId == "osc1Shape") {
        instance.osc1Shape = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "osc2Shape") {
        instance.osc2Shape = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "oscMixMode") {
        instance.oscMixMode = std::clamp(static_cast<int>(std::lround(value)), 0, 4);
    } else if (parameterId == "filterMode") {
        instance.filterMode =
            static_cast<float>(std::clamp(static_cast<int>(std::lround(value)), 0, 4));
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool SubtractiveSynthDeviceType::setStringParameter(DeviceSlot&,
                                                    std::string_view,
                                                    const std::string&,
                                                    const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> SubtractiveSynthDeviceType::modulatableParams() const {
    return {
        "gain", "pan", "filterCutoff", "filterQ", "filterMode", "attack", "decay", "sustain",
        "release", "osc1Shape", "osc2Shape", "osc1Octave", "osc1Semi", "osc1Detune", "osc2Octave",
        "osc2Semi", "osc2Detune", "oscMix", "osc1Sync", "osc2Sync", "noiseLevel", "oscMixMode",
        "unisonVoices", "unisonDetune", "filterEnvAmount", "filterAttack", "filterDecay",
        "filterSustain", "filterRelease", "glideMs", "velocitySensitivity",
    };
}

void SubtractiveSynthDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                   const PlaybackBuildContext&,
                                                   DeviceNodePlayback& out) const {
    const auto& instance = std::get<SubtractiveSynthInstance>(slot.instance);
    auto params = instance.toPlaybackParams();
    params.gain = slot.gain;
    out.kind = DeviceNodeKind::SubtractiveSynth;
    out.params = params;
}

bool SubtractiveSynthDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                     const PlaybackBuildContext&,
                                                     LiveInstrumentSnapshot& out) const {
    const auto& instance = std::get<SubtractiveSynthInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::SubtractiveSynth;
    out.gain = slot.gain;
    out.subtractive = instance.toPlaybackParams();
    out.subtractive.gain = slot.gain;
    return true;
}

} // namespace audioapp
