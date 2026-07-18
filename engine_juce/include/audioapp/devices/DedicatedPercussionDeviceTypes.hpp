#pragma once

#include "audioapp/devices/IDeviceType.hpp"

namespace audioapp {

enum class DedicatedPercussionKind : uint8_t { Hihat, Ride, Tom, Rimshot };

class DedicatedPercussionDeviceType : public IDeviceType {
public:
    explicit DedicatedPercussionDeviceType(DedicatedPercussionKind kind) : percussionKind_(kind) {}
    std::string typeId() const override;
    DeviceSlot createDefault(const std::string&) const override;
    DeviceParameterResult setParameter(DeviceSlot&, std::string_view, float) const override;
    bool setStringParameter(DeviceSlot&, std::string_view, const std::string&,
                            const PlaybackBuildContext&) const override { return false; }
    std::vector<std::string_view> modulatableParams() const override;
    void buildPlaybackNode(const DeviceSlot&, const PlaybackBuildContext&, DeviceNodePlayback&) const override;
    bool buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const override;
    juce::var slotToVar(const DeviceSlot&) const override;
    DeviceSlot varToSlot(const juce::var&) const override;
    DeviceProcessor* createProcessor(ProcessorArena&) const override;
    DeviceNodeKind kind() const noexcept override;
    uint16_t paramIdFromString(std::string_view) const noexcept override;
    std::string_view paramIdToString(uint16_t) const noexcept override;
    std::span<const ParamDescriptor> paramDescriptors() const noexcept override;
    bool usesDspAutomationSubBlocks() const noexcept override { return false; }

private:
    DedicatedPercussionKind percussionKind_;
};

class HihatGeneratorDeviceType final : public DedicatedPercussionDeviceType {
public: HihatGeneratorDeviceType() : DedicatedPercussionDeviceType(DedicatedPercussionKind::Hihat) {}
};
class RideGeneratorDeviceType final : public DedicatedPercussionDeviceType {
public: RideGeneratorDeviceType() : DedicatedPercussionDeviceType(DedicatedPercussionKind::Ride) {}
};
class TomGeneratorDeviceType final : public DedicatedPercussionDeviceType {
public: TomGeneratorDeviceType() : DedicatedPercussionDeviceType(DedicatedPercussionKind::Tom) {}
};
class RimshotGeneratorDeviceType final : public DedicatedPercussionDeviceType {
public: RimshotGeneratorDeviceType() : DedicatedPercussionDeviceType(DedicatedPercussionKind::Rimshot) {}
};

} // namespace audioapp
