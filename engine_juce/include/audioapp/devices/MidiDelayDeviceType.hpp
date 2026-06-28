#pragma once

#include "audioapp/devices/IDeviceType.hpp"

namespace audioapp {

class MidiDelayDeviceType final : public IDeviceType {
public:
    std::string typeId() const override;
    DeviceSlot createDefault(const std::string& deviceId) const override;
    DeviceParameterResult setParameter(DeviceSlot&, std::string_view, float) const override;
    bool setStringParameter(DeviceSlot&, std::string_view, const std::string&,
                            const PlaybackBuildContext&) const override;
    std::vector<std::string_view> modulatableParams() const override;
    void buildPlaybackNode(const DeviceSlot&, const PlaybackBuildContext&,
                           DeviceNodePlayback&) const override;
    bool buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&,
                             LiveInstrumentSnapshot&) const override;
    juce::var slotToVar(const DeviceSlot&) const override;
    DeviceSlot varToSlot(const juce::var&) const override;
    DeviceProcessor* createProcessor(ProcessorArena&) const override;
    DeviceNodeKind kind() const noexcept override;
    uint16_t paramIdFromString(std::string_view) const noexcept override;
    std::string_view paramIdToString(uint16_t) const noexcept override;
    std::span<const ParamDescriptor> paramDescriptors() const noexcept override;
};

} // namespace audioapp
