#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class DistortionProcessor : public DeviceProcessor {
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;

private:
    float lpStateL_ = 0.0f;
    float lpStateR_ = 0.0f;
};

} // namespace audioapp