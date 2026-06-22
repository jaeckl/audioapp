#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class ReverbProcessor : public DeviceProcessor {
    float* bufferLeft_ = nullptr;
    float* bufferRight_ = nullptr;
    int writeIndex_ = 0;
    float lfoPhase_ = 0.0f;
    float phaserStateL_[4] = {};
    float phaserStateR_[4] = {};

    bool ensureBuffers(ProcessContext& ctx) noexcept;

public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Reverb; }

    // No external runtime to copy — ring buffer lives in scratch arena
};

} // namespace audioapp