#include "audioapp/devices/OscillatorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/OscillatorInstance.hpp"

namespace audioapp {

std::string OscillatorDeviceType::typeId() const {
    return device_types::kOscillator;
}

DeviceState OscillatorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceState state;
    state.id = deviceId;
    OscillatorInstance instance;
    instance.frequencyHz = 440.0f;
    instance.applyTo(state);
    return state;
}

DeviceParameterResult OscillatorDeviceType::setParameter(DeviceState& state,
                                                         std::string_view parameterId,
                                                         float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(state, parameterId, value)) {
        result.handled = true;
        return result;
    }
    if (parameterId != "frequency") {
        return result;
    }
    OscillatorInstance instance = OscillatorInstance::fromState(state);
    instance.frequencyHz = value;
    instance.applyTo(state);
    result.handled = true;
    result.syncActiveFrequency = true;
    return result;
}

bool OscillatorDeviceType::setStringParameter(DeviceState&,
                                              std::string_view,
                                              const std::string&,
                                              const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> OscillatorDeviceType::modulatableParams() const {
    return {"frequency", "gain", "pan"};
}

void OscillatorDeviceType::buildPlaybackNode(const DeviceState& state,
                                             const PlaybackBuildContext&,
                                             DeviceNodePlayback& out) const {
    const OscillatorInstance instance = OscillatorInstance::fromState(state);
    out.kind = DeviceNodeKind::Oscillator;
    out.params = OscillatorParams{.frequencyHz = instance.frequencyHz};
}

bool OscillatorDeviceType::buildLiveInstrument(const DeviceState& state,
                                               const PlaybackBuildContext&,
                                               LiveInstrumentSnapshot& out) const {
    const OscillatorInstance instance = OscillatorInstance::fromState(state);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::Oscillator;
    out.frequencyHz = instance.frequencyHz;
    out.gain = state.gain;
    return true;
}

} // namespace audioapp
