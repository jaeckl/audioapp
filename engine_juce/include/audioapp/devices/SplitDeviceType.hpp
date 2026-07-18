#pragma once

#include "audioapp/devices/IDeviceType.hpp"
#include "audioapp/devices/SplitMode.hpp"

namespace audioapp {

/// LR or Mid-Side split container device. One instance is registered per
/// SplitMode (kLrSplit, kMsSplit); mode_ selects the typeId, default model,
/// and playback kind — the two modes otherwise share all device-type logic.
class SplitDeviceType final : public IDeviceType {
public:
    explicit SplitDeviceType(SplitMode mode) noexcept;

    std::string typeId() const override;
    DeviceSlot createDefault(const std::string& deviceId) const override;
    DeviceParameterResult setParameter(DeviceSlot& slot, std::string_view parameterId, float value) const override;
    bool setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const override;
    std::vector<std::string_view> modulatableParams() const override;
    void buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext& context, DeviceNodePlayback& out) const override;
    bool buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const override;
    juce::var slotToVar(const DeviceSlot& slot) const override;
    DeviceSlot varToSlot(const juce::var& value) const override;
    DeviceProcessor* createProcessor(ProcessorArena& arena) const override;
    DeviceNodeKind kind() const noexcept override;
    uint16_t paramIdFromString(std::string_view name) const noexcept override;
    std::string_view paramIdToString(uint16_t id) const noexcept override;
    std::span<const ParamDescriptor> paramDescriptors() const noexcept override;

private:
    SplitMode mode_;
};

} // namespace audioapp
