#include "audioapp/devices/KickGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/KickGeneratorInstance.hpp"

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

KickGeneratorInstance instanceFromSnapshot(const DeviceState& state) {
    KickGeneratorInstance instance;
    instance.kickModel = state.kickModel;
    instance.kickPitch = state.kickPitch;
    instance.kickPunch = state.kickPunch;
    instance.kickDecay = state.kickDecay;
    instance.kickClick = state.kickClick;
    instance.kickTone = state.kickTone;
    instance.kickVelocity = state.kickVelocity;
    return instance;
}

void applyInstanceToSnapshot(const KickGeneratorInstance& instance, DeviceState& state) {
    state.kickModel = instance.kickModel;
    state.kickPitch = instance.kickPitch;
    state.kickPunch = instance.kickPunch;
    state.kickDecay = instance.kickDecay;
    state.kickClick = instance.kickClick;
    state.kickTone = instance.kickTone;
    state.kickVelocity = instance.kickVelocity;
}

} // namespace

std::string KickGeneratorDeviceType::typeId() const {
    return device_types::kKickGenerator;
}

DeviceSlot KickGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = KickGeneratorInstance{};
    return slot;
}

DeviceState KickGeneratorDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kKickGenerator);
    applyInstanceToSnapshot(std::get<KickGeneratorInstance>(slot.instance), state);
    return state;
}

DeviceSlot KickGeneratorDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult KickGeneratorDeviceType::setParameter(DeviceSlot& slot,
                                                            std::string_view parameterId,
                                                            float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<KickGeneratorInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "kickModel") {
        instance.kickModel = clamped;
    } else if (parameterId == "kickPitch") {
        instance.kickPitch = clamped;
    } else if (parameterId == "kickPunch") {
        instance.kickPunch = clamped;
    } else if (parameterId == "kickDecay") {
        instance.kickDecay = clamped;
    } else if (parameterId == "kickClick") {
        instance.kickClick = clamped;
    } else if (parameterId == "kickTone") {
        instance.kickTone = clamped;
    } else if (parameterId == "kickVelocity") {
        instance.kickVelocity = clamped;
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool KickGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                 std::string_view,
                                                 const std::string&,
                                                 const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> KickGeneratorDeviceType::modulatableParams() const {
    return {"gain", "pan", "kickPitch", "kickPunch", "kickDecay", "kickClick", "kickTone",
            "kickVelocity"};
}

void KickGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                const PlaybackBuildContext&,
                                                DeviceNodePlayback& out) const {
    const auto& instance = std::get<KickGeneratorInstance>(slot.instance);
    out.kind = DeviceNodeKind::KickGenerator;
    out.params = instance.toPlaybackParams(slot.gain);
}

bool KickGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                  const PlaybackBuildContext&,
                                                  LiveInstrumentSnapshot& out) const {
    const auto& instance = std::get<KickGeneratorInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::KickGenerator;
    out.gain = slot.gain;
    out.kick = instance.toPlaybackParams(slot.gain);
    return true;
}

} // namespace audioapp
