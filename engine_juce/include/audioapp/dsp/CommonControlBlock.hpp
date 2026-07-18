#pragma once

#include <cstdint>

namespace audioapp {

enum class CommonControlMode : uint8_t {
    Constant,
    Ramp,
    Dynamic,
};

/// Block-local execution descriptor for the universal device-strip controls.
/// Constant and one-block ramp modes avoid materializing per-frame arrays;
/// automation and modulation use preallocated dynamic buffers.
struct CommonControlBlock {
    CommonControlMode gainMode = CommonControlMode::Constant;
    CommonControlMode panMode = CommonControlMode::Constant;
    float gainStart = 1.0f;
    float gainEnd = 1.0f;
    float panStart = 0.5f;
    float panEnd = 0.5f;
    const float* gainValues = nullptr;
    const float* panValues = nullptr;
    int numFrames = 0;

    float gainAt(int frame) const noexcept {
        if (gainMode == CommonControlMode::Dynamic && gainValues != nullptr)
            return gainValues[frame];
        if (gainMode == CommonControlMode::Ramp && numFrames > 0)
            return gainStart + (gainEnd - gainStart) *
                (static_cast<float>(frame + 1) / static_cast<float>(numFrames));
        return gainEnd;
    }

    float panAt(int frame) const noexcept {
        if (panMode == CommonControlMode::Dynamic && panValues != nullptr)
            return panValues[frame];
        if (panMode == CommonControlMode::Ramp && numFrames > 0)
            return panStart + (panEnd - panStart) *
                (static_cast<float>(frame + 1) / static_cast<float>(numFrames));
        return panEnd;
    }
};

} // namespace audioapp
