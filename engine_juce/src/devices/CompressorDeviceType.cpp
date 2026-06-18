#include "audioapp/devices/CompressorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/CompressorInstance.hpp"

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

CompressorInstance instanceFromSnapshot(const DeviceState& state) {
    CompressorInstance instance;
    instance.compThreshold = state.compThreshold;
    instance.compRatio = state.compRatio;
    instance.compAttack = state.compAttack;
    instance.compRelease = state.compRelease;
    instance.compKnee = state.compKnee;
    instance.compMakeup = state.compMakeup;
    return instance;
}

void applyInstanceToSnapshot(const CompressorInstance& instance, DeviceState& state) {
    state.compThreshold = instance.compThreshold;
    state.compRatio = instance.compRatio;
    state.compAttack = instance.compAttack;
    state.compRelease = instance.compRelease;
    state.compKnee = instance.compKnee;
    state.compMakeup = instance.compMakeup;
}

} // namespace

std::string CompressorDeviceType::typeId() const { return device_types::kCompressor; }

DeviceSlot CompressorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = CompressorInstance{};
    return slot;
}

DeviceState CompressorDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kCompressor);
    applyInstanceToSnapshot(std::get<CompressorInstance>(slot.instance), state);
    return state;
}

DeviceSlot CompressorDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult CompressorDeviceType::setParameter(DeviceSlot& slot,
                                                         std::string_view parameterId,
                                                         float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<CompressorInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "compThreshold") {
        instance.compThreshold = clamped;
    } else if (parameterId == "compRatio") {
        instance.compRatio = clamped;
    } else if (parameterId == "compAttack") {
        instance.compAttack = clamped;
    } else if (parameterId == "compRelease") {
        instance.compRelease = clamped;
    } else if (parameterId == "compKnee") {
        instance.compKnee = clamped;
    } else if (parameterId == "compMakeup") {
        instance.compMakeup = clamped;
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool CompressorDeviceType::setStringParameter(DeviceSlot&,
                                              std::string_view,
                                              const std::string&,
                                              const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> CompressorDeviceType::modulatableParams() const {
    return {"gain", "pan", "compThreshold", "compRatio", "compAttack", "compRelease", "compKnee",
            "compMakeup"};
}

void CompressorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                             const PlaybackBuildContext&,
                                             DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Compressor;
    out.params = std::get<CompressorInstance>(slot.instance).toPlaybackParams();
}

bool CompressorDeviceType::buildLiveInstrument(const DeviceSlot&,
                                               const PlaybackBuildContext&,
                                               LiveInstrumentSnapshot&) const {
    return false;
}

} // namespace audioapp
