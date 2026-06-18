#include "audioapp/devices/TrackGainDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/TrackGainInstance.hpp"

namespace audioapp {

std::string TrackGainDeviceType::typeId() const {
    return device_types::kTrackGain;
}

DeviceState TrackGainDeviceType::createDefault(const std::string& deviceId) const {
    DeviceState state;
    state.id = deviceId;
    TrackGainInstance instance;
    instance.gain = 1.0f;
    instance.applyTo(state);
    return state;
}

DeviceParameterResult TrackGainDeviceType::setParameter(DeviceState& state,
                                                        std::string_view parameterId,
                                                        float value) const {
    DeviceParameterResult result;
    if (parameterId != "gain") {
        return result;
    }
    TrackGainInstance instance = TrackGainInstance::fromState(state);
    instance.gain = std::clamp(value, 0.0f, 1.0f);
    instance.applyTo(state);
    result.handled = true;
    return result;
}

bool TrackGainDeviceType::setStringParameter(DeviceState&,
                                             std::string_view,
                                             const std::string&,
                                             const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> TrackGainDeviceType::modulatableParams() const {
    return {"gain"};
}

void TrackGainDeviceType::buildPlaybackNode(const DeviceState&,
                                            const PlaybackBuildContext&,
                                            DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::TrackGain;
    out.params = TrackGainParams{};
}

bool TrackGainDeviceType::buildLiveInstrument(const DeviceState&,
                                              const PlaybackBuildContext&,
                                              LiveInstrumentSnapshot&) const {
    return false;
}

} // namespace audioapp
