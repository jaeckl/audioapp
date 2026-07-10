#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class ChorusProcessor : public DeviceProcessor {
    float* bufferLeft_ = nullptr;
    float* bufferRight_ = nullptr;
    int writeIndex_ = 0;
    float lfoPhase_ = 0.0f;
    static constexpr int kMaxVoices = 4;
    float wanderState_ = 0.0f;
    float wanderTarget_ = 0.0f;
    int wanderCounter_ = 0;
    uint32_t rngState_ = 0x71A5C3E9u;
    float lowPassState_[2]{};
    float highPassState_[2]{};
    float highPassInput_[2]{};

    bool ensureBuffers(ProcessContext& ctx) noexcept;

public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    void resetPlaybackState() noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Chorus; }

    // No external runtime to copy — ring buffer lives in scratch arena
};

} // namespace audioapp
