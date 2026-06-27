#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class BitcrusherProcessor : public DeviceProcessor {
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;

private:
    float phase_ = 0.0f;
    float heldL_ = 0.0f;
    float heldR_ = 0.0f;
};

} // namespace audioapp