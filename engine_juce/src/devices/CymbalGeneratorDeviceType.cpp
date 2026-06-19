#include "audioapp/devices/CymbalGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/CymbalGeneratorInstance.hpp"

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

CymbalGeneratorInstance instanceFromSnapshot(const DeviceState& state) {
    CymbalGeneratorInstance instance;
    instance.cymbalModel = state.cymbalModel;
    instance.cymbalColor = state.cymbalColor;
    instance.cymbalDecay = state.cymbalDecay;
    instance.cymbalWidth = state.cymbalWidth;
    instance.cymbalVelocity = state.cymbalVelocity;
    return instance;
}

void applyInstanceToSnapshot(const CymbalGeneratorInstance& instance, DeviceState& state) {
    state.cymbalModel = instance.cymbalModel;
    state.cymbalColor = instance.cymbalColor;
    state.cymbalDecay = instance.cymbalDecay;
    state.cymbalWidth = instance.cymbalWidth;
    state.cymbalVelocity = instance.cymbalVelocity;
}

} // namespace

std::string CymbalGeneratorDeviceType::typeId() const {
    return device_types::kCymbalGenerator;
}

DeviceSlot CymbalGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = CymbalGeneratorInstance{};
    return slot;
}

DeviceState CymbalGeneratorDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kCymbalGenerator);
    applyInstanceToSnapshot(std::get<CymbalGeneratorInstance>(slot.instance), state);
    return state;
}

DeviceSlot CymbalGeneratorDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult CymbalGeneratorDeviceType::setParameter(DeviceSlot& slot,
                                                              std::string_view parameterId,
                                                              float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<CymbalGeneratorInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "cymbalModel") {
        instance.cymbalModel = clamped;
    } else if (parameterId == "cymbalColor") {
        instance.cymbalColor = clamped;
    } else if (parameterId == "cymbalDecay") {
        instance.cymbalDecay = clamped;
    } else if (parameterId == "cymbalWidth") {
        instance.cymbalWidth = clamped;
    } else if (parameterId == "cymbalVelocity") {
        instance.cymbalVelocity = clamped;
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool CymbalGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                   std::string_view,
                                                   const std::string&,
                                                   const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> CymbalGeneratorDeviceType::modulatableParams() const {
    return {"gain", "pan", "cymbalColor", "cymbalDecay", "cymbalWidth", "cymbalVelocity"};
}

void CymbalGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                  const PlaybackBuildContext&,
                                                  DeviceNodePlayback& out) const {
    const auto& instance = std::get<CymbalGeneratorInstance>(slot.instance);
    out.kind = DeviceNodeKind::CymbalGenerator;
    out.params = instance.toPlaybackParams(slot.gain);
}

bool CymbalGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                    const PlaybackBuildContext&,
                                                    LiveInstrumentSnapshot& out) const {
    const auto& instance = std::get<CymbalGeneratorInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::CymbalGenerator;
    out.gain = slot.gain;
    out.cymbal = instance.toPlaybackParams(slot.gain);
    return true;
}

} // namespace audioapp
