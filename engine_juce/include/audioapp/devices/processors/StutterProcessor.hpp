#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class StutterProcessor final : public DeviceProcessor {
    float* bufferLeft_ = nullptr;
    float* bufferRight_ = nullptr;
    int writeIndex_ = 0;
    int capturedWriteIndex_ = 0;
    int repeatPhase_ = 0;
    int repeatCounter_ = 0;
    bool wasTriggered_ = false;
    float tailPeak_ = 0.0f;

    bool ensureBuffers(ProcessContext& ctx) noexcept;
    void captureNow() noexcept;
    static float envelopeFor(int phase, int activeSamples, int fadeSamples) noexcept;

public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Stutter; }
    void resetPlaybackState() noexcept override;
    bool hasActiveTail() const noexcept override { return tailPeak_ > 1.0e-5f; }
};

} // namespace audioapp
