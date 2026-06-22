#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class OscillatorProcessor : public DeviceProcessor {
    float oscillatorPhase_ = 0.0f;
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Oscillator; }

    /// Accessors for back-to-back persistence across callbacks.
    float phase() const noexcept { return oscillatorPhase_; }
    void setPhase(float p) noexcept { oscillatorPhase_ = p; }
};

} // namespace audioapp