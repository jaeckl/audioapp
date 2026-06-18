#include "audioapp/devices/OscillatorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/OscillatorInstance.hpp"

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

} // namespace

std::string OscillatorDeviceType::typeId() const {
    return device_types::kOscillator;
}

DeviceSlot OscillatorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = OscillatorInstance{.frequencyHz = 440.0f};
    return slot;
}

DeviceState OscillatorDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kOscillator);
    state.frequencyHz = std::get<OscillatorInstance>(slot.instance).frequencyHz;
    return state;
}

DeviceSlot OscillatorDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = OscillatorInstance{.frequencyHz = state.frequencyHz};
    return slot;
}

DeviceParameterResult OscillatorDeviceType::setParameter(DeviceSlot& slot,
                                                         std::string_view parameterId,
                                                         float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    if (parameterId != "frequency") {
        return result;
    }
    std::get<OscillatorInstance>(slot.instance).frequencyHz = value;
    result.handled = true;
    result.syncActiveFrequency = true;
    return result;
}

bool OscillatorDeviceType::setStringParameter(DeviceSlot&,
                                              std::string_view,
                                              const std::string&,
                                              const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> OscillatorDeviceType::modulatableParams() const {
    return {"frequency", "gain", "pan"};
}

void OscillatorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                             const PlaybackBuildContext&,
                                             DeviceNodePlayback& out) const {
    const auto& instance = std::get<OscillatorInstance>(slot.instance);
    out.kind = DeviceNodeKind::Oscillator;
    out.params = OscillatorParams{.frequencyHz = instance.frequencyHz};
}

bool OscillatorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                               const PlaybackBuildContext&,
                                               LiveInstrumentSnapshot& out) const {
    const auto& instance = std::get<OscillatorInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::Oscillator;
    out.frequencyHz = instance.frequencyHz;
    out.gain = slot.gain;
    return true;
}

} // namespace audioapp
