#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class TremoloProcessor : public DeviceProcessor {
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;

private:
    float lfoPhase_ = 0.0f;
};

} // namespace audioapp