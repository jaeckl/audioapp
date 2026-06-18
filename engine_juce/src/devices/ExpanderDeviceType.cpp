#include "audioapp/devices/ExpanderDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/ExpanderInstance.hpp"

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

ExpanderInstance instanceFromSnapshot(const DeviceState& state) {
    ExpanderInstance instance;
    instance.expandThreshold = state.expandThreshold;
    instance.expandRatio = state.expandRatio;
    instance.expandAttack = state.expandAttack;
    instance.expandRelease = state.expandRelease;
    instance.expandRange = state.expandRange;
    return instance;
}

void applyInstanceToSnapshot(const ExpanderInstance& instance, DeviceState& state) {
    state.expandThreshold = instance.expandThreshold;
    state.expandRatio = instance.expandRatio;
    state.expandAttack = instance.expandAttack;
    state.expandRelease = instance.expandRelease;
    state.expandRange = instance.expandRange;
}

} // namespace

std::string ExpanderDeviceType::typeId() const { return device_types::kExpander; }

DeviceSlot ExpanderDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = ExpanderInstance{};
    return slot;
}

DeviceState ExpanderDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kExpander);
    applyInstanceToSnapshot(std::get<ExpanderInstance>(slot.instance), state);
    return state;
}

DeviceSlot ExpanderDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult ExpanderDeviceType::setParameter(DeviceSlot& slot,
                                                       std::string_view parameterId,
                                                       float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<ExpanderInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "expandThreshold") {
        instance.expandThreshold = clamped;
    } else if (parameterId == "expandRatio") {
        instance.expandRatio = clamped;
    } else if (parameterId == "expandAttack") {
        instance.expandAttack = clamped;
    } else if (parameterId == "expandRelease") {
        instance.expandRelease = clamped;
    } else if (parameterId == "expandRange") {
        instance.expandRange = clamped;
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool ExpanderDeviceType::setStringParameter(DeviceSlot&,
                                            std::string_view,
                                            const std::string&,
                                            const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> ExpanderDeviceType::modulatableParams() const {
    return {"gain", "pan", "expandThreshold", "expandRatio", "expandAttack", "expandRelease",
            "expandRange"};
}

void ExpanderDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                           const PlaybackBuildContext&,
                                           DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Expander;
    out.params = std::get<ExpanderInstance>(slot.instance).toPlaybackParams();
}

bool ExpanderDeviceType::buildLiveInstrument(const DeviceSlot&,
                                             const PlaybackBuildContext&,
                                             LiveInstrumentSnapshot&) const {
    return false;
}

} // namespace audioapp
