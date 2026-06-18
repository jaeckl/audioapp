#include "audioapp/devices/TrackGainDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/TrackGainInstance.hpp"

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

} // namespace

std::string TrackGainDeviceType::typeId() const {
    return device_types::kTrackGain;
}

DeviceSlot TrackGainDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = TrackGainInstance{};
    return slot;
}

DeviceState TrackGainDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    return stripSnapshot(slot, device_types::kTrackGain);
}

DeviceSlot TrackGainDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = TrackGainInstance{};
    return slot;
}

DeviceParameterResult TrackGainDeviceType::setParameter(DeviceSlot& slot,
                                                        std::string_view parameterId,
                                                        float value) const {
    DeviceParameterResult result;
    if (parameterId != "gain") {
        return result;
    }
    slot.gain = std::clamp(value, 0.0f, 1.0f);
    result.handled = true;
    return result;
}

bool TrackGainDeviceType::setStringParameter(DeviceSlot&,
                                             std::string_view,
                                             const std::string&,
                                             const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> TrackGainDeviceType::modulatableParams() const {
    return {"gain"};
}

void TrackGainDeviceType::buildPlaybackNode(const DeviceSlot&,
                                            const PlaybackBuildContext&,
                                            DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::TrackGain;
    out.params = TrackGainParams{};
}

bool TrackGainDeviceType::buildLiveInstrument(const DeviceSlot&,
                                              const PlaybackBuildContext&,
                                              LiveInstrumentSnapshot&) const {
    return false;
}

} // namespace audioapp
