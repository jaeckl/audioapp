#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class AnalysisProcessor final : public DeviceProcessor {
public:
    explicit AnalysisProcessor(DeviceNodeKind kind) noexcept : kind_(kind) {}
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return kind_; }
private:
    DeviceNodeKind kind_;
    float loudness_ = -70.0f;
    int samplesUntilSpectrum_ = 0;
};

}
