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
    instance.limitCeiling = state.limitCeiling;
    instance.limitRelease = state.limitRelease;
    instance.limitDrive = state.limitDrive;
    return instance;
}

void applyInstanceToSnapshot(const LimiterInstance& instance, DeviceState& state) {
    state.limitCeiling = instance.limitCeiling;
    state.limitRelease = instance.limitRelease;
    state.limitDrive = instance.limitDrive;
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
    if (parameterId == "limitCeiling") {
        instance.limitCeiling = clamped;
    } else if (parameterId == "limitRelease") {
        instance.limitRelease = clamped;
    } else if (parameterId == "limitDrive") {
        instance.limitDrive = clamped;
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
    return {"gain", "pan", "limitCeiling", "limitRelease", "limitDrive"};
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
