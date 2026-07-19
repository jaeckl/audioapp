#include "audioapp/devices/DeviceTreeWalk.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/ChainModel.hpp"
#include "audioapp/devices/instances/DrumMachineModel.hpp"
#include "audioapp/devices/instances/MultibandSplitModel.hpp"
#include "audioapp/devices/instances/SpectralLoudSplitModel.hpp"
#include "audioapp/devices/instances/SplitModel.hpp"
#include "audioapp/DeviceSubgraph.hpp"

namespace audioapp {
namespace {

template <typename SlotT, typename Fn>
void walkImpl(SlotT& slot, Fn&& visitor) {
    visitor(slot);

    if (slot.config.typeId == device_types::kChain) {
        for (auto& child : std::get<ChainModel>(slot.config.instance).devices)
            if (child) walkImpl(*child, visitor);
    } else if (slot.config.typeId == device_types::kDrumMachine) {
        for (auto& pad : std::get<DrumMachineModel>(slot.config.instance).pads)
            for (auto& child : pad.devices)
                if (child) walkImpl(*child, visitor);
    } else if (device_types::isSplitType(slot.config.typeId)) {
        auto& split = std::get<SplitModel>(slot.config.instance);
        for (auto& child : split.branch0)
            if (child) walkImpl(*child, visitor);
        for (auto& child : split.branch1)
            if (child) walkImpl(*child, visitor);
    } else if (device_types::isMultibandSplitType(slot.config.typeId)) {
        auto& mb = std::get<MultibandSplitModel>(slot.config.instance);
        for (int b = 0; b < mb.bandCount && b < kMaxMbBands; ++b)
            for (auto& child : mb.bands[b])
                if (child) walkImpl(*child, visitor);
    } else if (device_types::isSpectralLoudSplitType(slot.config.typeId)) {
        auto& sl = std::get<SpectralLoudSplitModel>(slot.config.instance);
        for (auto& child : sl.preFxDevices)
            if (child) walkImpl(*child, visitor);
        for (auto& child : sl.postFxDevices)
            if (child) walkImpl(*child, visitor);
        for (int b = 0; b < kSpectralLoudBands; ++b)
            for (auto& child : sl.bands[b])
                if (child) walkImpl(*child, visitor);
    }

    for (auto& child : slot.noteFxDevices)
        if (child) walkImpl(*child, visitor);
    for (auto& child : slot.audioFxDevices)
        if (child) walkImpl(*child, visitor);
}

} // namespace

void walkDeviceTree(DeviceSlot& root, const std::function<void(DeviceSlot&)>& visitor) {
    walkImpl(root, visitor);
}

void walkDeviceTree(const DeviceSlot& root,
                    const std::function<void(const DeviceSlot&)>& visitor) {
    walkImpl(root, visitor);
}

void collectDeviceTreeIds(const DeviceSlot& root, std::vector<std::string>& ids) {
    walkDeviceTree(root, [&](const DeviceSlot& slot) { ids.push_back(slot.id); });
}

int countDeviceTreeSlots(const DeviceSlot& root) noexcept {
    int count = 0;
    walkDeviceTree(root, [&](const DeviceSlot&) { ++count; });
    return count;
}

int ringLeasesForDeviceType(std::string_view typeId) noexcept {
    using namespace device_types;
    if (typeId == kDelay || typeId == kReverb || typeId == kChorus || typeId == kStutter)
        return 1;
    if (typeId == kSpectralLoudSplit) return 1;
    if (isMultibandSplitType(typeId)) return 2; // band + out buffers
    return 0;
}

int countDeviceTreeRingLeases(const DeviceSlot& root) noexcept {
    int leases = 0;
    walkDeviceTree(root, [&](const DeviceSlot& slot) {
        leases += ringLeasesForDeviceType(slot.config.typeId);
    });
    return leases;
}

int estimateDeviceTreeSubgraphSteps(const DeviceSlot& root) noexcept {
    // Each device contributes InputAdapter + DeviceProcessor + OutputAdapter.
    constexpr int kStepsPerNode = 3;
    return countDeviceTreeSlots(root) * kStepsPerNode;
}

} // namespace audioapp
