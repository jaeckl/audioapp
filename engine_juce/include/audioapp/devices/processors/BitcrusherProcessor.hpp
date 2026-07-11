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
    float filterL_ = 0.0f;
    float filterR_ = 0.0f;
    uint32_t randomState_ = 0x92d68ca2u;
};

} // namespace audioapp
