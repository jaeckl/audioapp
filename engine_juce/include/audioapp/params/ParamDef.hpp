#pragma once

#include <cstdint>

namespace audioapp::params {

/// Globally unique parameter identifier.
/// Layout: (deviceTypeIndex << 16) | localParamId
using ParamId = uint32_t;

/// Maximum device types addressable.
inline constexpr int kMaxDeviceTypes = 32;
inline constexpr int kTypeIndexBits = 5;

/// Extract device type index from a ParamId.
inline constexpr int typeIndexFromId(ParamId id) noexcept {
    return static_cast<int>(id >> 16);
}

/// Extract local param ID from a ParamId.
inline constexpr uint16_t localIdFromId(ParamId id) noexcept {
    return static_cast<uint16_t>(id & 0xFFFF);
}

/// Build a ParamId from parts.
inline constexpr ParamId makeParamId(int typeIndex, uint16_t localId) noexcept {
    return (static_cast<ParamId>(typeIndex) << 16) | localId;
}

/// Convenience macro to declare a param enum + makeParamId helper.
/// Usage:
///   AUDIOAPP_PARAM_ENUM(Filter, 8, Cutoff, Resonance, Mode)
///   // defines FilterParam enum { Cutoff, Resonance, Mode }
///   // and makeFilterId(FilterParam::Cutoff) -> (8<<16)|0
#define AUDIOAPP_PARAM_ENUM(TypeName, TypeIndex, ...) \
    enum class TypeName##Param : uint16_t { __VA_ARGS__ }; \
    inline constexpr params::ParamId make##TypeName##Id(TypeName##Param p) noexcept { \
        return params::makeParamId(TypeIndex, static_cast<uint16_t>(p)); \
    } \
    static_assert(true)

} // namespace audioapp::params