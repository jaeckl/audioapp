#include "audioapp/params/ParamRegistry.hpp"

#include <cstddef>

namespace audioapp::params {

int ParamRegistry::registerDevice(std::string_view typeId,
                                   std::span<const ParamDescriptor> descriptors) {
    if (static_cast<int>(blocks_.size()) >= kMaxDeviceTypes)
        return -1;

    const int ti = static_cast<int>(blocks_.size());
    DeviceBlock& block = blocks_.emplace_back();
    block.typeId = typeId;
    block.typeIndex = ti;
    block.descriptors = descriptors;

    typeIdForSlot_[ti] = typeId;

    for (const auto& d : descriptors) {
        const auto pid = d.localParamId;
        if (pid < kMaxLocalParams) {
            const size_t idx = static_cast<size_t>(ti) * kMaxLocalParams + pid;
            slotTable_[idx] = &d;
        }
        block.nameMap[d.stableName] = makeParamId(ti, pid);
    }

    return ti;
}

const ParamDescriptor* ParamRegistry::find(ParamId id) const {
    const int ti = typeIndexFromId(id);
    if (ti < 0 || ti >= static_cast<int>(blocks_.size()))
        return nullptr;
    const uint16_t pid = localIdFromId(id);
    if (pid >= kMaxLocalParams)
        return nullptr;
    const size_t idx = static_cast<size_t>(ti) * kMaxLocalParams + pid;
    return slotTable_[idx];
}

ParamId ParamRegistry::findByName(std::string_view typeId, std::string_view name) const {
    for (const auto& block : blocks_) {
        if (block.typeId == typeId) {
            auto it = block.nameMap.find(name);
            if (it != block.nameMap.end())
                return it->second;
            return 0;
        }
    }
    return 0;
}

std::string_view ParamRegistry::nameForId(ParamId id) const {
    const auto* d = find(id);
    return d ? d->stableName : std::string_view{};
}

std::span<const ParamDescriptor> ParamRegistry::descriptorsFor(std::string_view typeId) const {
    for (const auto& block : blocks_) {
        if (block.typeId == typeId)
            return block.descriptors;
    }
    return {};
}

int ParamRegistry::typeIndexFor(std::string_view typeId) const {
    for (const auto& block : blocks_) {
        if (block.typeId == typeId)
            return block.typeIndex;
    }
    return -1;
}

std::string_view ParamRegistry::typeIdFor(ParamId id) const {
    const int ti = typeIndexFromId(id);
    if (ti < 0 || ti >= static_cast<int>(blocks_.size()))
        return {};
    return typeIdForSlot_[ti];
}

} // namespace audioapp::params