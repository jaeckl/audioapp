#pragma once

#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/NestingError.hpp"

#include <string_view>
#include <vector>

namespace audioapp {

/// Precomputed track-level usage for insert validation (control thread).
struct NestingTrackEstimate {
    int ringLeases = 0;
    int flattenedSlots = 0;
    int subgraphSteps = 0;
};

/// Control-thread capacity checks for open nesting. Never type-blocks containers.
class DeviceNestingValidator {
public:
    /// Estimate post-insert topology against soft limits. Does not mutate.
    static NestingError validateInsert(const DeviceSlot& parent,
                                       std::string_view childTypeId,
                                       bool childTypeKnown,
                                       int parentBranchCount,
                                       bool parentIsDrumPad,
                                       const NestingTrackEstimate& track,
                                       const NestingCapacityLimits& limits = {});

    /// Validate an existing tree against soft limits (no pending insert).
    static NestingError validateTree(const DeviceSlot& root,
                                     const NestingCapacityLimits& limits = {});

    /// Build track estimate by walking all top-level devices on a track.
    static NestingTrackEstimate estimateTrack(
        const std::vector<DeviceSlot>& trackDevices) noexcept;
};

} // namespace audioapp
