#include "audioapp/devices/LimiterDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/LimiterInstance.hpp"

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

LimiterInstance instanceFromSnapshot(const DeviceState& state) {
    LimiterInstance instance;
    instance.inputGain = state.inputGain;
    instance.limitCeiling = state.limitCeiling;
    instance.limitAttack = state.limitAttack;
    instance.limitRelease = state.limitRelease;
    instance.limitKnee = state.limitKnee;
    instance.limitDrive = state.limitDrive;
    instance.limitMakeup = state.limitMakeup;
    return instance;
}

void applyInstanceToSnapshot(const LimiterInstance& instance, DeviceState& state) {
    state.inputGain = instance.inputGain;
    state.limitCeiling = instance.limitCeiling;
    state.limitAttack = instance.limitAttack;
    state.limitRelease = instance.limitRelease;
    state.limitKnee = instance.limitKnee;
    state.limitDrive = instance.limitDrive;
    state.limitMakeup = instance.limitMakeup;
}

} // namespace

std::string LimiterDeviceType::typeId() const { return device_types::kLimiter; }

DeviceSlot LimiterDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = LimiterInstance{};
    return slot;
}

DeviceState LimiterDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kLimiter);
    applyInstanceToSnapshot(std::get<LimiterInstance>(slot.instance), state);
    return state;
}

DeviceSlot LimiterDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult LimiterDeviceType::setParameter(DeviceSlot& slot,
                                                      std::string_view parameterId,
                                                      float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<LimiterInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "inputGain") {
        instance.inputGain = clamped;
    } else if (parameterId == "limitCeiling") {
        instance.limitCeiling = clamped;
    } else if (parameterId == "limitAttack") {
        instance.limitAttack = clamped;
    } else if (parameterId == "limitRelease") {
        instance.limitRelease = clamped;
    } else if (parameterId == "limitKnee") {
        instance.limitKnee = clamped;
    } else if (parameterId == "limitDrive") {
        instance.limitDrive = clamped;
    } else if (parameterId == "limitMakeup") {
        instance.limitMakeup = clamped;
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool LimiterDeviceType::setStringParameter(DeviceSlot&,
                                           std::string_view,
                                           const std::string&,
                                           const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> LimiterDeviceType::modulatableParams() const {
    return {"gain", "pan", "inputGain", "limitCeiling", "limitAttack", "limitRelease", "limitKnee",
            "limitDrive", "limitMakeup"};
}

void LimiterDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                          const PlaybackBuildContext&,
                                          DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Limiter;
    out.params = std::get<LimiterInstance>(slot.instance).toPlaybackParams();
}

bool LimiterDeviceType::buildLiveInstrument(const DeviceSlot&,
                                            const PlaybackBuildContext&,
                                            LiveInstrumentSnapshot&) const {
    return false;
}

} // namespace audioapp
