#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class ChorusProcessor : public DeviceProcessor {
    float* bufferLeft_ = nullptr;
    float* bufferRight_ = nullptr;
    int writeIndex_ = 0;
    float lfoPhase_ = 0.0f;

    bool ensureBuffers(ProcessContext& ctx) noexcept;

public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Chorus; }

    // No external runtime to copy — ring buffer lives in scratch arena
};

} // namespace audioapp