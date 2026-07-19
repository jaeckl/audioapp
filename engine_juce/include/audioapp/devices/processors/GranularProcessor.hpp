#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/GranularAlgorithm.hpp"

namespace audioapp {

class GranularProcessor final : public DeviceProcessor {
    GranularFormantFilterState formantState_{};

public:
    void process(AudioBlock&, ProcessContext&) noexcept override;
    void resetPlaybackState() noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Granular; }
};

} // namespace audioapp
