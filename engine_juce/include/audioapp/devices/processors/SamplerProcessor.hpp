#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/SamplerFilter.hpp"

namespace audioapp {

class SamplerProcessor : public DeviceProcessor {
    struct VoiceState {
        bool active = false;
        int noteIndex = -1;
        int pitch = 0;
        double clipStartBeat = 0.0;
        double noteStartBeat = 0.0;
        BiquadState filter{};
    };
    VoiceState voices_[kMaxInstrumentRegions]{};
    int activeVoiceSlots_[kMaxInstrumentRegions]{};
    int activeVoiceCount_ = 0;
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Sampler; }

    void setFilterStates(const BiquadState* src) noexcept {
        for (int i = 0; i < kMaxInstrumentRegions; ++i)
            voices_[i].filter = src[i];
    }
    void copyFilterStates(BiquadState* dst) const noexcept {
        for (int i = 0; i < kMaxInstrumentRegions; ++i)
            dst[i] = voices_[i].filter;
    }
    void resetPlaybackState() noexcept override;
};

} // namespace audioapp
