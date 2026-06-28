#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/dsp/AudioBlock.hpp"
#include "audioapp/dsp/ProcessContext.hpp"

#include <string_view>

namespace audioapp {

class DeviceProcessor {
public:
    virtual void initParams(const DeviceVariantParams& params) noexcept {
        storedParams_ = params;
    }

    virtual void process(AudioBlock& block, ProcessContext& ctx) noexcept = 0;

    virtual DeviceNodeKind kind() const noexcept {
        return DeviceNodeKind::Unknown;
    }

    /// Optional realtime-safe control path for high-rate UI gestures.
    /// Implementations may update atomics here so the control thread does not
    /// rewrite storedParams_ while the audio thread is copying it.
    virtual bool setRealtimeParameter(std::string_view parameterId, float value) noexcept {
        (void)parameterId;
        (void)value;
        return false;
    }

    const DeviceVariantParams& storedParams() const noexcept { return storedParams_; }

    bool bypassed = false;
    int8_t meterSlot = -1;
    float gain = 1.0f;
    float pan = 0.5f;
    float outputMix = 1.0f;
    float outputWidth = 1.0f;

protected:
    DeviceProcessor() = default;
    ~DeviceProcessor() = default;
    DeviceProcessor(const DeviceProcessor&) = delete;
    DeviceProcessor& operator=(const DeviceProcessor&) = delete;

private:
    DeviceVariantParams storedParams_;
};

} // namespace audioapp