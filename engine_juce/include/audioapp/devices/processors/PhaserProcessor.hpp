#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class PhaserProcessor : public DeviceProcessor {
    float lfoPhase_ = 0.0f;
    float phaserStateL_[12] = {};
    float phaserStateR_[12] = {};
    uint32_t randomState_ = 0x5a17c9e3u;
    float randomL_ = 0.0f;
    float randomR_ = 0.0f;

    float nextRandom() noexcept;

public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Phaser; }

    // No external runtime to copy — ring buffer lives in scratch arena
};

} // namespace audioapp
