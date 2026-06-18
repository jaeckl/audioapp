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
    instance.cymbalMetal = state.cymbalMetal;
    instance.cymbalBrightness = state.cymbalBrightness;
    instance.cymbalDecay = state.cymbalDecay;
    instance.cymbalChoke = state.cymbalChoke;
    instance.cymbalVelocity = state.cymbalVelocity;
    return instance;
}

void applyInstanceToSnapshot(const CymbalGeneratorInstance& instance, DeviceState& state) {
    state.cymbalModel = instance.cymbalModel;
    state.cymbalMetal = instance.cymbalMetal;
    state.cymbalBrightness = instance.cymbalBrightness;
    state.cymbalDecay = instance.cymbalDecay;
    state.cymbalChoke = instance.cymbalChoke;
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
    } else if (parameterId == "cymbalMetal") {
        instance.cymbalMetal = clamped;
    } else if (parameterId == "cymbalBrightness") {
        instance.cymbalBrightness = clamped;
    } else if (parameterId == "cymbalDecay") {
        instance.cymbalDecay = clamped;
    } else if (parameterId == "cymbalChoke") {
        instance.cymbalChoke = clamped;
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
    return {"gain", "pan", "cymbalMetal", "cymbalBrightness", "cymbalDecay", "cymbalChoke",
            "cymbalVelocity"};
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
