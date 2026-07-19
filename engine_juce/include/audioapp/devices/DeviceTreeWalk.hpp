#pragma once

#include "audioapp/devices/DeviceSlot.hpp"

#include <functional>
#include <string>
#include <vector>

namespace audioapp {

/// Pre-order visit of every DeviceSlot in a subtree (root included).
/// Walks: chain children, split branches, MB bands, spectral pre/bands/post,
/// drum pads, noteFx, audioFx — recursively.
void walkDeviceTree(DeviceSlot& root, const std::function<void(DeviceSlot&)>& visitor);
void walkDeviceTree(const DeviceSlot& root,
                    const std::function<void(const DeviceSlot&)>& visitor);

/// Collect every device id in the subtree (pre-order, root first).
void collectDeviceTreeIds(const DeviceSlot& root, std::vector<std::string>& ids);

/// Count slots in subtree including root.
int countDeviceTreeSlots(const DeviceSlot& root) noexcept;

/// Sum ring-buffer leases required by this subtree (see DeviceNestingValidator).
int countDeviceTreeRingLeases(const DeviceSlot& root) noexcept;

/// Estimate compiled subgraph steps for this subtree (≈ 3 per node).
int estimateDeviceTreeSubgraphSteps(const DeviceSlot& root) noexcept;

/// Ring leases for a single type id (0 if none).
int ringLeasesForDeviceType(std::string_view typeId) noexcept;

} // namespace audioapp
