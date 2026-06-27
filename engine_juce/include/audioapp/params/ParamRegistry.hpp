#pragma once

#include <string>
#include <string_view>
#include <vector>
#include <span>
#include <unordered_map>

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/params/ParamDef.hpp"

namespace audioapp::params {

/// Registry that indexes per-device ParamDescriptor arrays and provides
/// O(1) lookup by global ParamId and O(log N) lookup by name.
class ParamRegistry {
public:
    /// Register a device type's parameter descriptors.
    /// @param typeId  canonical type string (e.g. "subtractive_synth")
    /// @param descriptors  span returned by IDeviceType::paramDescriptors()
    /// @return the assigned type index (0..31), or -1 if full.
    int registerDevice(std::string_view typeId,
                       std::span<const ParamDescriptor> descriptors);

    /// Look up a descriptor by global ParamId. Returns nullptr if not found.
    const ParamDescriptor* find(ParamId id) const;

    /// Look up a global ParamId by (typeId, stableName). Returns 0 if not found.
    ParamId findByName(std::string_view typeId, std::string_view name) const;

    /// Get the stable JSON key for a ParamId.
    std::string_view nameForId(ParamId id) const;

    /// Get all parameter descriptors for a device type.
    std::span<const ParamDescriptor> descriptorsFor(std::string_view typeId) const;

    /// Get the type index assigned to a device type. Returns -1 if unknown.
    int typeIndexFor(std::string_view typeId) const;

    /// Get the type ID string for a ParamId.
    std::string_view typeIdFor(ParamId id) const;

    /// Iterate all params for a device type.
    template<typename Fn>
    void forEachParam(std::string_view typeId, Fn&& fn) const {
        auto descs = descriptorsFor(typeId);
        int ti = typeIndexFor(typeId);
        if (ti < 0) return;
        for (const auto& d : descs) {
            fn(d, makeParamId(ti, d.localParamId));
        }
    }

private:
    struct DeviceBlock {
        std::string typeId;
        int typeIndex = -1;
        std::span<const ParamDescriptor> descriptors;
        std::unordered_map<std::string_view, ParamId> nameMap;
    };

    std::vector<DeviceBlock> blocks_;
    // Flat indexed array: index = (typeIndex * kMaxLocalParams + localParamId)
    // Maps ParamId -> pointer into descriptors
    static constexpr int kMaxLocalParams = 256;
    static constexpr int kTotalSlots = kMaxDeviceTypes * kMaxLocalParams;
    const ParamDescriptor* slotTable_[kTotalSlots] = {};
    std::string typeIdForSlot_[kMaxDeviceTypes];
};

} // namespace audioapp::params