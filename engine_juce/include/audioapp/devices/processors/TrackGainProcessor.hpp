#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class TrackGainProcessor : public DeviceProcessor {
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::TrackGain; }
};

} // namespace audioapp