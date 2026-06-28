#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/WavetableSynthAlgorithm.hpp"
#include "audioapp/WavetableBank.hpp"

namespace audioapp {

class WavetableSynthProcessor : public DeviceProcessor {
    WavetableSynthRuntime runtime_{};
public:
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::WavetableSynth; }

    WavetableSynthRuntime* runtimePtr() noexcept { return &runtime_; }
    void setWavetableIndex(int idx) noexcept { runtime_.wavetableIndex = idx; }
    int wavetableIndex() const noexcept { return runtime_.wavetableIndex; }
};

} // namespace audioapp
