#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class ReverbProcessor final : public DeviceProcessor {
    static constexpr int kLineCount = 8;
    static constexpr int kPreDelayCapacity = 12001;
    static constexpr int kLineCapacity =
        (DeviceChainScratchArena::kBufferSize - kPreDelayCapacity) / 4;

    float* bufferLeft_ = nullptr;
    float* bufferRight_ = nullptr;
    int preWriteIndex_ = 0;
    int lineWriteIndex_[kLineCount] = {};
    float dampingState_[kLineCount] = {};
    float modulationPhase_[kLineCount] = {};
    float wetLowpassL_ = 0.0f;
    float wetLowpassR_ = 0.0f;
    float wetHighpassInputL_ = 0.0f;
    float wetHighpassInputR_ = 0.0f;
    float wetHighpassOutputL_ = 0.0f;
    float wetHighpassOutputR_ = 0.0f;
    float duckEnvelope_ = 0.0f;
    float tailPeak_ = 0.0f;

    bool ensureBuffers(ProcessContext& ctx) noexcept;
    float* lineBuffer(int line) noexcept;
    float readLine(int line, float delaySamples) noexcept;

public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Reverb; }
    void resetPlaybackState() noexcept override;
    bool hasActiveTail() const noexcept override { return tailPeak_ > 1.0e-5f; }
};

} // namespace audioapp
