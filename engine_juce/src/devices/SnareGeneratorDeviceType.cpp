#include "audioapp/devices/SnareGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/SnareGeneratorInstance.hpp"

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

SnareGeneratorInstance instanceFromSnapshot(const DeviceState& state) {
    SnareGeneratorInstance instance;
    instance.snareModel = state.snareModel;
    instance.snareBody = state.snareBody;
    instance.snareTune = state.snareTune;
    instance.snareSnares = state.snareSnares;
    instance.snareSnap = state.snareSnap;
    instance.snareDecay = state.snareDecay;
    instance.snareVelocity = state.snareVelocity;
    return instance;
}

void applyInstanceToSnapshot(const SnareGeneratorInstance& instance, DeviceState& state) {
    state.snareModel = instance.snareModel;
    state.snareBody = instance.snareBody;
    state.snareTune = instance.snareTune;
    state.snareSnares = instance.snareSnares;
    state.snareSnap = instance.snareSnap;
    state.snareDecay = instance.snareDecay;
    state.snareVelocity = instance.snareVelocity;
}

} // namespace

std::string SnareGeneratorDeviceType::typeId() const {
    return device_types::kSnareGenerator;
}

DeviceSlot SnareGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = SnareGeneratorInstance{};
    return slot;
}

DeviceState SnareGeneratorDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kSnareGenerator);
    applyInstanceToSnapshot(std::get<SnareGeneratorInstance>(slot.instance), state);
    return state;
}

DeviceSlot SnareGeneratorDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult SnareGeneratorDeviceType::setParameter(DeviceSlot& slot,
                                                             std::string_view parameterId,
                                                             float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<SnareGeneratorInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "snareModel") {
        instance.snareModel = clamped;
    } else if (parameterId == "snareBody") {
        instance.snareBody = clamped;
    } else if (parameterId == "snareTune") {
        instance.snareTune = clamped;
    } else if (parameterId == "snareSnares") {
        instance.snareSnares = clamped;
    } else if (parameterId == "snareSnap") {
        instance.snareSnap = clamped;
    } else if (parameterId == "snareDecay") {
        instance.snareDecay = clamped;
    } else if (parameterId == "snareVelocity") {
        instance.snareVelocity = clamped;
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool SnareGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                  std::string_view,
                                                  const std::string&,
                                                  const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> SnareGeneratorDeviceType::modulatableParams() const {
    return {"gain", "pan", "snareModel", "snareBody", "snareTune", "snareSnares", "snareSnap", "snareDecay",
            "snareVelocity"};
}

void SnareGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                 const PlaybackBuildContext&,
                                                 DeviceNodePlayback& out) const {
    const auto& instance = std::get<SnareGeneratorInstance>(slot.instance);
    out.kind = DeviceNodeKind::SnareGenerator;
    out.params = instance.toPlaybackParams(slot.gain);
}

bool SnareGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                   const PlaybackBuildContext&,
                                                   LiveInstrumentSnapshot& out) const {
    const auto& instance = std::get<SnareGeneratorInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::SnareGenerator;
    out.gain = slot.gain;
    out.snare = instance.toPlaybackParams(slot.gain);
    return true;
}

} // namespace audioapp
