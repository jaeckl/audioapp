#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class DeCracklerProcessor : public DeviceProcessor {
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;

private:
    float stateA_ = 0.0f;
    float stateB_ = 0.0f;
    float stateC_ = 0.0f;
    float prevL_ = 0.0f;
    float prevR_ = 0.0f;
    int repairLeft_ = 0;
    float repairStartL_ = 0.0f;
    float repairStartR_ = 0.0f;
    float repairEndL_ = 0.0f;
    float repairEndR_ = 0.0f;
    float z1L_[8] = {};
    float z2L_[8] = {};
    float z1R_[8] = {};
    float z2R_[8] = {};
};

} // namespace audioapp
