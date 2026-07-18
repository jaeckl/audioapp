#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/WavetableSynthAlgorithm.hpp"
#include "audioapp/WavetableBank.hpp"

#include <atomic>
#include <string_view>

namespace audioapp {

class WavetableSynthProcessor : public DeviceProcessor {
    WavetableSynthRuntime runtime_{};
    std::atomic<float> realtimeWtPosition_{0.0f};
    std::atomic<bool> realtimeWtPositionValid_{false};

public:
    void initParams(const DeviceVariantParams& params) noexcept override;
    bool setRealtimeParameter(std::string_view parameterId, float value) noexcept override;
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::WavetableSynth; }

    WavetableSynthRuntime* runtimePtr() noexcept { return &runtime_; }
    void setWavetableIndex(int idx) noexcept { runtime_.wavetableIndex = idx; }
    bool setResolvedWavetableIndex(int idx) noexcept override {
        runtime_.wavetableIndex = idx;
        return true;
    }
    int wavetableIndex() const noexcept { return runtime_.wavetableIndex; }
    void resetPlaybackState() noexcept override;
};

} // namespace audioapp
