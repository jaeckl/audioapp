#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class UtilityProcessor : public DeviceProcessor {
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    void resetPlaybackState() noexcept override { phase_ = 0.0f; }

private:
    float phase_ = 0.0f;
};

} // namespace audioapp
