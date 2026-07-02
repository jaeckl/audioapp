#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class DelayProcessor : public DeviceProcessor {
    float* bufferLeft_ = nullptr;
    float* bufferRight_ = nullptr;
    int writeIndex_ = 0;
    float lfoPhase_ = 0.0f;
    float tailPeak_ = 0.0f;

    bool ensureBuffers(ProcessContext& ctx) noexcept;

public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Delay; }
    void resetPlaybackState() noexcept override;
    bool hasActiveTail() const noexcept override { return tailPeak_ > 1.0e-5f; }

    // No external runtime to copy — ring buffer lives in scratch arena
};

} // namespace audioapp
