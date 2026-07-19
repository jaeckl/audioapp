#pragma once

#include <string>
#include <string_view>

namespace audioapp {

enum class NestingErrorCode {
    None = 0,
    BranchDeviceCap,
    PadDeviceCap,
    TrackDeviceCap,
    SubgraphStepOverflow,
    RingLeaseExhausted,
    UnknownParent,
    UnknownType,
};

struct NestingCapacityLimits {
    int maxDevicesPerNestBranch = 8;
    int maxDevicesPerPad = 4;
    int maxDevicesPerTrack = 24;
    int maxCompiledSubgraphSteps = 512;
    int maxRingLeases = 6;
};

/// Soft branch / FX-list cap shared by chain, split, MB, spectral, synth FX.
inline constexpr int kMaxDevicesPerNestBranch = 8;

struct NestingError {
    NestingErrorCode code = NestingErrorCode::None;
    std::string message;
    std::string parentDeviceId;
    std::string deviceType;
    int limit = 0;
    int attempted = 0;

    bool ok() const noexcept { return code == NestingErrorCode::None; }
};

inline std::string_view nestingErrorBridgeCode(NestingErrorCode code) noexcept {
    switch (code) {
        case NestingErrorCode::None: return {};
        case NestingErrorCode::BranchDeviceCap: return "branch_device_cap";
        case NestingErrorCode::PadDeviceCap: return "pad_device_cap";
        case NestingErrorCode::TrackDeviceCap: return "track_device_cap";
        case NestingErrorCode::SubgraphStepOverflow: return "subgraph_step_overflow";
        case NestingErrorCode::RingLeaseExhausted: return "ring_lease_exhausted";
        case NestingErrorCode::UnknownParent: return "unknown_parent";
        case NestingErrorCode::UnknownType: return "unknown_type";
    }
    return "unknown_type";
}

inline NestingError makeNestingError(NestingErrorCode code, std::string message,
                                     std::string parentDeviceId = {},
                                     std::string deviceType = {}, int limit = 0,
                                     int attempted = 0) {
    NestingError err;
    err.code = code;
    err.message = std::move(message);
    err.parentDeviceId = std::move(parentDeviceId);
    err.deviceType = std::move(deviceType);
    err.limit = limit;
    err.attempted = attempted;
    return err;
}

} // namespace audioapp
