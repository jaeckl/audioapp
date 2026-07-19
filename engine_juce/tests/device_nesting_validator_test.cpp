#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/devices/DeviceNestingValidator.hpp"
#include "audioapp/devices/DeviceTreeWalk.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/ChainModel.hpp"
#include "audioapp/devices/instances/DrumMachineModel.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"

#include <algorithm>
#include <memory>
#include <vector>

namespace {

audioapp::DeviceSlot makeSlot(const std::string& typeId, const std::string& id) {
    static const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
    return registry.createDefault(typeId, id);
}

} // namespace

class DeviceNestingValidatorTest : public juce::UnitTest {
public:
    DeviceNestingValidatorTest()
        : juce::UnitTest("DeviceNestingValidator", "Devices") {}

    void runTest() override {
        beginTest("bridge codes are snake_case");
        {
            expect(audioapp::nestingErrorBridgeCode(
                       audioapp::NestingErrorCode::BranchDeviceCap) ==
                   "branch_device_cap");
            expect(audioapp::nestingErrorBridgeCode(
                       audioapp::NestingErrorCode::RingLeaseExhausted) ==
                   "ring_lease_exhausted");
        }

        beginTest("ring lease counts match ensureBuffers");
        {
            expectEquals(audioapp::ringLeasesForDeviceType(audioapp::device_types::kDelay), 1);
            expectEquals(audioapp::ringLeasesForDeviceType(audioapp::device_types::kMbSplit2), 2);
            expectEquals(
                audioapp::ringLeasesForDeviceType(audioapp::device_types::kSpectralLoudSplit),
                1);
            expectEquals(audioapp::ringLeasesForDeviceType(audioapp::device_types::kFilter), 0);
            expectEquals(audioapp::ringLeasesForDeviceType(audioapp::device_types::kPhaser), 0);
        }

        beginTest("branch_device_cap when nest branch full");
        {
            auto chain = makeSlot(audioapp::device_types::kChain, "c0");
            auto& kids = std::get<audioapp::ChainModel>(chain.config.instance).devices;
            for (int i = 0; i < audioapp::kMaxDevicesPerNestBranch; ++i)
                kids.push_back(std::make_shared<audioapp::DeviceSlot>(
                    makeSlot(audioapp::device_types::kFilter, "f" + std::to_string(i))));

            audioapp::NestingTrackEstimate track{};
            track.flattenedSlots = 1 + audioapp::kMaxDevicesPerNestBranch;
            const auto err = audioapp::DeviceNestingValidator::validateInsert(
                chain, audioapp::device_types::kCompressor, true,
                static_cast<int>(kids.size()), false, track);
            expect(err.code == audioapp::NestingErrorCode::BranchDeviceCap);
            expect(std::string(audioapp::nestingErrorBridgeCode(err.code)) ==
                   "branch_device_cap");
        }

        beginTest("pad_device_cap when drum pad full");
        {
            auto drum = makeSlot(audioapp::device_types::kDrumMachine, "dm0");
            audioapp::NestingTrackEstimate track{};
            const auto err = audioapp::DeviceNestingValidator::validateInsert(
                drum, audioapp::device_types::kFilter, true,
                audioapp::DrumMachineModel::kMaxDevicesPerPad, true, track);
            expect(err.code == audioapp::NestingErrorCode::PadDeviceCap);
        }

        beginTest("unknown_type");
        {
            auto chain = makeSlot(audioapp::device_types::kChain, "c1");
            audioapp::NestingTrackEstimate track{};
            const auto err = audioapp::DeviceNestingValidator::validateInsert(
                chain, "not_a_real_type", false, 0, false, track);
            expect(err.code == audioapp::NestingErrorCode::UnknownType);
        }

        beginTest("ring_lease_exhausted");
        {
            auto chain = makeSlot(audioapp::device_types::kChain, "c2");
            audioapp::NestingTrackEstimate track{};
            track.ringLeases = 6;
            const auto err = audioapp::DeviceNestingValidator::validateInsert(
                chain, audioapp::device_types::kDelay, true, 0, false, track);
            expect(err.code == audioapp::NestingErrorCode::RingLeaseExhausted);
        }

        beginTest("track_device_cap");
        {
            auto chain = makeSlot(audioapp::device_types::kChain, "c3");
            audioapp::NestingCapacityLimits limits;
            limits.maxDevicesPerTrack = 2;
            audioapp::NestingTrackEstimate track{};
            track.flattenedSlots = 2;
            const auto err = audioapp::DeviceNestingValidator::validateInsert(
                chain, audioapp::device_types::kFilter, true, 0, false, track, limits);
            expect(err.code == audioapp::NestingErrorCode::TrackDeviceCap);
        }

        beginTest("subgraph_step_overflow");
        {
            auto chain = makeSlot(audioapp::device_types::kChain, "c4");
            audioapp::NestingCapacityLimits limits;
            limits.maxCompiledSubgraphSteps = 3; // one more node would be 6
            audioapp::NestingTrackEstimate track{};
            track.subgraphSteps = 3;
            const auto err = audioapp::DeviceNestingValidator::validateInsert(
                chain, audioapp::device_types::kFilter, true, 0, false, track, limits);
            expect(err.code == audioapp::NestingErrorCode::SubgraphStepOverflow);
        }

        beginTest("validator does not type-reject containers");
        {
            auto chain = makeSlot(audioapp::device_types::kChain, "c5");
            audioapp::NestingTrackEstimate track{};
            const auto err = audioapp::DeviceNestingValidator::validateInsert(
                chain, audioapp::device_types::kChain, true, 0, false, track);
            expect(err.ok(), "open nesting: chain-in-chain must pass capacity check");
        }

        beginTest("walkDeviceTree recurses chain-in-chain");
        {
            auto outer = makeSlot(audioapp::device_types::kChain, "outer");
            auto inner = std::make_shared<audioapp::DeviceSlot>(
                makeSlot(audioapp::device_types::kChain, "inner"));
            auto leaf = std::make_shared<audioapp::DeviceSlot>(
                makeSlot(audioapp::device_types::kFilter, "leaf"));
            std::get<audioapp::ChainModel>(inner->config.instance).devices.push_back(leaf);
            std::get<audioapp::ChainModel>(outer.config.instance).devices.push_back(inner);

            std::vector<std::string> ids;
            audioapp::collectDeviceTreeIds(outer, ids);
            expectEquals(static_cast<int>(ids.size()), 3);
            expect(std::find(ids.begin(), ids.end(), "leaf") != ids.end());
        }
    }
};

static DeviceNestingValidatorTest deviceNestingValidatorTest;
