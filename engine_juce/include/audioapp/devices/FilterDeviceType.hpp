#pragma once

#include "audioapp/devices/IDeviceType.hpp"
#include "audioapp/AutomationTypes.hpp"
#include <span>

namespace audioapp {

class FilterDeviceType final : public IDeviceType {
public:
    std::string typeId() const override;
    DeviceSlot createDefault(const std::string& deviceId) const override;
    DeviceParameterResult setParameter(DeviceSlot& slot,
                                       std::string_view parameterId,
                                       float value) const override;
    bool setStringParameter(DeviceSlot& slot,
                            std::string_view parameterId,
                            const std::string& value,
                            const PlaybackBuildContext& context) const override;
    std::vector<std::string_view> modulatableParams() const override;
    void buildPlaybackNode(const DeviceSlot& slot,
                           const PlaybackBuildContext& context,
                           DeviceNodePlayback& out) const override;
    bool buildLiveInstrument(const DeviceSlot& slot,
                             const PlaybackBuildContext& context,
                             LiveInstrumentSnapshot& out) const override;

    juce::var slotToVar(const DeviceSlot& slot) const override;
    DeviceSlot varToSlot(const juce::var& obj) const override;

    DeviceProcessor* createProcessor(ProcessorArena& arena) const override;
    DeviceNodeKind kind() const noexcept override;
    uint16_t paramIdFromString(std::string_view name) const noexcept override;
    std::string_view paramIdToString(uint16_t localId) const noexcept override;
    std::span<const ParamDescriptor> paramDescriptors() const noexcept override;
    bool usesDspAutomationSubBlocks() const noexcept override;
};

} // namespace audioapp