#pragma once

#include "audioapp/devices/IDeviceType.hpp"

namespace audioapp {

class DrumMachineDeviceType final : public IDeviceType {
public:
    std::string typeId() const override;
    DeviceSlot createDefault(const std::string& deviceId) const override;
    DeviceParameterResult setParameter(DeviceSlot&, std::string_view, float) const override;
    bool setStringParameter(DeviceSlot&, std::string_view, const std::string&,
                            const PlaybackBuildContext&) const override;
    std::vector<std::string_view> modulatableParams() const override { return {}; }
    void buildPlaybackNode(const DeviceSlot&, const PlaybackBuildContext&,
                           DeviceNodePlayback& out) const override;
    bool buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&,
                             LiveInstrumentSnapshot&) const override { return false; }
    juce::var slotToVar(const DeviceSlot& slot) const override;
    DeviceSlot varToSlot(const juce::var& obj) const override;
    DeviceProcessor* createProcessor(ProcessorArena& arena) const override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::DrumMachine; }
};

} // namespace audioapp
