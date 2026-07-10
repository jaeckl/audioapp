#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include <array>

namespace audioapp {

class DelayProcessor : public DeviceProcessor {
    float* bufferLeft_ = nullptr;
    float* bufferRight_ = nullptr;
    int writeIndex_ = 0;
    float lfoPhase_ = 0.0f;
    float tailPeak_ = 0.0f;

    // Four serial Schroeder all-pass stages per channel. Kept inside the
    // processor so blur is allocation-free on the audio thread.
    static constexpr int kDiffusionStages = 4;
    static constexpr int kDiffusionBufferSize = 1024;
    float diffusion_[2][kDiffusionStages][kDiffusionBufferSize]{};
    int diffusionIndices_[2][kDiffusionStages]{};
    float lowPassState_[2]{};
    float highPassState_[2]{};
    float highPassInput_[2]{};
    float duckEnvelope_ = 0.0f;

    bool ensureBuffers(ProcessContext& ctx) noexcept;
    float processAllPass(float input, int channel, int stage,
                         int delaySamples, float coefficient) noexcept;

public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Delay; }
    void resetPlaybackState() noexcept override;
    bool hasActiveTail() const noexcept override { return tailPeak_ > 1.0e-5f; }

    // No external runtime to copy — ring buffer lives in scratch arena
};

} // namespace audioapp
