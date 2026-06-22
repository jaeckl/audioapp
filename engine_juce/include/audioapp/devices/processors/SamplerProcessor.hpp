#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/SamplerFilter.hpp"

namespace audioapp {

class SamplerProcessor : public DeviceProcessor {
    BiquadState samplerFilterStates_[kMaxInstrumentRegions]{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Sampler; }

    void setFilterStates(const BiquadState* src) noexcept {
        for (int i = 0; i < kMaxInstrumentRegions; ++i)
            samplerFilterStates_[i] = src[i];
    }
    void copyFilterStates(BiquadState* dst) const noexcept {
        for (int i = 0; i < kMaxInstrumentRegions; ++i)
            dst[i] = samplerFilterStates_[i];
    }
    BiquadState* filterStatesPtr() noexcept { return samplerFilterStates_; }
};

} // namespace audioapp