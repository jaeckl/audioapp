#include "audioapp/devices/DeviceNestingValidator.hpp"

#include "audioapp/devices/DeviceTreeWalk.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/ChainModel.hpp"
#include "audioapp/devices/instances/DrumMachineModel.hpp"
#include "audioapp/devices/instances/MultibandSplitModel.hpp"
#include "audioapp/devices/instances/SpectralLoudSplitModel.hpp"
#include "audioapp/devices/instances/SplitModel.hpp"

#include <string>

namespace audioapp {

NestingTrackEstimate DeviceNestingValidator::estimateTrack(
    const std::vector<DeviceSlot>& trackDevices) noexcept {
    NestingTrackEstimate est;
    for (const auto& device : trackDevices) {
        est.ringLeases += countDeviceTreeRingLeases(device);
        est.flattenedSlots += countDeviceTreeSlots(device);
        est.subgraphSteps += estimateDeviceTreeSubgraphSteps(device);
    }
    return est;
}

NestingError DeviceNestingValidator::validateInsert(
    const DeviceSlot& parent, std::string_view childTypeId, bool childTypeKnown,
    int parentBranchCount, bool parentIsDrumPad, const NestingTrackEstimate& track,
    const NestingCapacityLimits& limits) {
    if (!childTypeKnown) {
        return makeNestingError(NestingErrorCode::UnknownType, "Unknown device type.",
                                parent.id, std::string(childTypeId));
    }

    if (parentIsDrumPad) {
        if (parentBranchCount >= limits.maxDevicesPerPad) {
            return makeNestingError(
                NestingErrorCode::PadDeviceCap,
                "This drum pad is full (max " + std::to_string(limits.maxDevicesPerPad) +
                    " devices).",
                parent.id, std::string(childTypeId), limits.maxDevicesPerPad,
                parentBranchCount + 1);
        }
    } else if (parentBranchCount >= limits.maxDevicesPerNestBranch) {
        return makeNestingError(
            NestingErrorCode::BranchDeviceCap,
            "This strip is full (max " + std::to_string(limits.maxDevicesPerNestBranch) +
                " devices).",
            parent.id, std::string(childTypeId), limits.maxDevicesPerNestBranch,
            parentBranchCount + 1);
    }

    const int childLeases = ringLeasesForDeviceType(childTypeId);
    if (track.ringLeases + childLeases > limits.maxRingLeases) {
        return makeNestingError(
            NestingErrorCode::RingLeaseExhausted,
            "Too many time-based/buffer effects on this track (max " +
                std::to_string(limits.maxRingLeases) + ").",
            parent.id, std::string(childTypeId), limits.maxRingLeases,
            track.ringLeases + childLeases);
    }

    // Leaf insert adds one flattened slot (+ nested children if inserting a
    // pre-built tree — insert path only adds createDefault leaf).
    if (track.flattenedSlots + 1 > limits.maxDevicesPerTrack) {
        return makeNestingError(
            NestingErrorCode::TrackDeviceCap,
            "Track device limit reached (max " + std::to_string(limits.maxDevicesPerTrack) +
                ").",
            parent.id, std::string(childTypeId), limits.maxDevicesPerTrack,
            track.flattenedSlots + 1);
    }

    constexpr int kStepsPerNode = 3;
    if (track.subgraphSteps + kStepsPerNode > limits.maxCompiledSubgraphSteps) {
        return makeNestingError(
            NestingErrorCode::SubgraphStepOverflow,
            "Device graph too deep/complex for this track.", parent.id,
            std::string(childTypeId), limits.maxCompiledSubgraphSteps,
            track.subgraphSteps + kStepsPerNode);
    }

    return {};
}

NestingError DeviceNestingValidator::validateTree(const DeviceSlot& root,
                                                  const NestingCapacityLimits& limits) {
    NestingError first;

    auto checkBranch = [&](int count, bool isPad, const std::string& parentId) {
        if (first.code != NestingErrorCode::None) return;
        if (isPad) {
            if (count > limits.maxDevicesPerPad) {
                first = makeNestingError(
                    NestingErrorCode::PadDeviceCap,
                    "This drum pad is full (max " + std::to_string(limits.maxDevicesPerPad) +
                        " devices).",
                    parentId, {}, limits.maxDevicesPerPad, count);
            }
        } else if (count > limits.maxDevicesPerNestBranch) {
            first = makeNestingError(
                NestingErrorCode::BranchDeviceCap,
                "This strip is full (max " +
                    std::to_string(limits.maxDevicesPerNestBranch) + " devices).",
                parentId, {}, limits.maxDevicesPerNestBranch, count);
        }
    };

    walkDeviceTree(root, [&](const DeviceSlot& slot) {
        if (first.code != NestingErrorCode::None) return;
        if (slot.config.typeId == device_types::kChain) {
            checkBranch(
                static_cast<int>(std::get<ChainModel>(slot.config.instance).devices.size()),
                false, slot.id);
        } else if (device_types::isSplitType(slot.config.typeId)) {
            const auto& split = std::get<SplitModel>(slot.config.instance);
            checkBranch(static_cast<int>(split.branch0.size()), false, slot.id);
            checkBranch(static_cast<int>(split.branch1.size()), false, slot.id);
        } else if (device_types::isMultibandSplitType(slot.config.typeId)) {
            const auto& mb = std::get<MultibandSplitModel>(slot.config.instance);
            for (int b = 0; b < mb.bandCount && b < kMaxMbBands; ++b)
                checkBranch(static_cast<int>(mb.bands[b].size()), false, slot.id);
        } else if (device_types::isSpectralLoudSplitType(slot.config.typeId)) {
            const auto& sl = std::get<SpectralLoudSplitModel>(slot.config.instance);
            checkBranch(static_cast<int>(sl.preFxDevices.size()), false, slot.id);
            checkBranch(static_cast<int>(sl.postFxDevices.size()), false, slot.id);
            for (int b = 0; b < kSpectralLoudBands; ++b)
                checkBranch(static_cast<int>(sl.bands[b].size()), false, slot.id);
        } else if (slot.config.typeId == device_types::kDrumMachine) {
            for (const auto& pad : std::get<DrumMachineModel>(slot.config.instance).pads)
                checkBranch(static_cast<int>(pad.devices.size()), true, slot.id);
        }
        checkBranch(static_cast<int>(slot.audioFxDevices.size()), false, slot.id);
        checkBranch(static_cast<int>(slot.noteFxDevices.size()), false, slot.id);
    });
    if (first.code != NestingErrorCode::None) return first;

    const int leases = countDeviceTreeRingLeases(root);
    if (leases > limits.maxRingLeases) {
        return makeNestingError(
            NestingErrorCode::RingLeaseExhausted,
            "Too many time-based/buffer effects on this track (max " +
                std::to_string(limits.maxRingLeases) + ").",
            root.id, {}, limits.maxRingLeases, leases);
    }

    const int steps = estimateDeviceTreeSubgraphSteps(root);
    if (steps > limits.maxCompiledSubgraphSteps) {
        return makeNestingError(
            NestingErrorCode::SubgraphStepOverflow,
            "Device graph too deep/complex for this track.", root.id, {},
            limits.maxCompiledSubgraphSteps, steps);
    }

    const int slots = countDeviceTreeSlots(root);
    if (slots > limits.maxDevicesPerTrack) {
        return makeNestingError(
            NestingErrorCode::TrackDeviceCap,
            "Track device limit reached (max " + std::to_string(limits.maxDevicesPerTrack) +
                ").",
            root.id, {}, limits.maxDevicesPerTrack, slots);
    }

    return {};
}

} // namespace audioapp
