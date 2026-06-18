#include "audioapp/devices/GateDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/GateInstance.hpp"

#include <algorithm>

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

GateInstance instanceFromSnapshot(const DeviceState& state) {
    GateInstance instance;
    instance.gateThreshold = state.gateThreshold;
    instance.gateAttack = state.gateAttack;
    instance.gateRelease = state.gateRelease;
    instance.gateHold = state.gateHold;
    instance.gateRange = state.gateRange;
    return instance;
}

void applyInstanceToSnapshot(const GateInstance& instance, DeviceState& state) {
    state.gateThreshold = instance.gateThreshold;
    state.gateAttack = instance.gateAttack;
    state.gateRelease = instance.gateRelease;
    state.gateHold = instance.gateHold;
    state.gateRange = instance.gateRange;
}

} // namespace

std::string GateDeviceType::typeId() const { return device_types::kGate; }

DeviceSlot GateDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = GateInstance{};
    return slot;
}

DeviceState GateDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kGate);
    applyInstanceToSnapshot(std::get<GateInstance>(slot.instance), state);
    return state;
}

DeviceSlot GateDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult GateDeviceType::setParameter(DeviceSlot& slot,
                                                   std::string_view parameterId,
                                                   float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<GateInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "gateThreshold") {
        instance.gateThreshold = clamped;
    } else if (parameterId == "gateAttack") {
        instance.gateAttack = clamped;
    } else if (parameterId == "gateRelease") {
        instance.gateRelease = clamped;
    } else if (parameterId == "gateHold") {
        instance.gateHold = clamped;
    } else if (parameterId == "gateRange") {
        instance.gateRange = clamped;
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool GateDeviceType::setStringParameter(DeviceSlot&,
                                        std::string_view,
                                        const std::string&,
                                        const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> GateDeviceType::modulatableParams() const {
    return {"gain", "pan", "gateThreshold", "gateAttack", "gateRelease", "gateHold", "gateRange"};
}

void GateDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                       const PlaybackBuildContext&,
                                       DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Gate;
    out.params = std::get<GateInstance>(slot.instance).toPlaybackParams();
}

bool GateDeviceType::buildLiveInstrument(const DeviceSlot&,
                                         const PlaybackBuildContext&,
                                         LiveInstrumentSnapshot&) const {
    return false;
}

} // namespace audioapp
