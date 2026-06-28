#pragma once

#include "audioapp/ResonatorBank.hpp"
#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class ResonatorBankProcessor final : public DeviceProcessor {
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::ResonatorBank; }

private:
    ResonatorBankRuntime runtime_{};
};

} // namespace audioapp
