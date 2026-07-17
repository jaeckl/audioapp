#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceSubgraph.hpp"
#include "audioapp/dsp/AudioBlock.hpp"
#include "audioapp/dsp/ProcessContext.hpp"

#include <string_view>

namespace audioapp {

class DeviceProcessor {
public:
    virtual ~DeviceProcessor() = default;
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

    /// Update a processor owned by a container (drum machine/device chain)
    /// without rebuilding the container and discarding every child voice.
    virtual bool updateNestedDevice(const DeviceNodePlayback& node,
                                    bool paramsChanged = true) noexcept {
        (void)node;
        (void)paramsChanged;
        return false;
    }

    virtual bool updateDrumPadParameter(int note, std::string_view parameterId,
                                        float value) noexcept {
        (void)note;
        (void)parameterId;
        (void)value;
        return false;
    }

    void applyPlaybackNode(const DeviceNodePlayback& node) noexcept {
        deviceId_ = node.deviceId;
        stableProcessorNodeId = stableDeviceSubgraphNodeId(
            node.deviceId, DeviceSubgraphNodeRole::DeviceProcessor);
        executionPlan = compileDeviceExecutionPlan(node.kind);
        bypassed = node.bypassed;
        gain = node.gain;
        pan = node.pan;
        outputMix = node.outputMix;
        outputWidth = node.outputWidth;
        voicePolicy = node.voicePolicy;
        initParams(node.params);
    }

    /// Clear per-processor runtime state (voices, FX buffers, phases).
    /// Called when transport loops or playhead seeks backward.
    virtual void resetPlaybackState() noexcept {}

    /// True while an effect can still emit audio with silent input. Containers
    /// use this to sleep inactive internal chains without cutting delay/reverb tails.
    virtual bool hasActiveTail() const noexcept { return false; }

    /// Algorithmic delay at the exposed output port. Built-ins currently
    /// report zero; look-ahead devices override this before they are routed.
    virtual uint16_t reportedLatencySamples() const noexcept { return 0; }

    const DeviceVariantParams& storedParams() const noexcept { return storedParams_; }

    void configureExecutionPlan(DeviceNodeKind nodeKind) noexcept {
        executionPlan = compileDeviceExecutionPlan(nodeKind);
    }

    bool bypassed = false;
    int8_t meterSlot = -1;
    float gain = 1.0f;
    float pan = 0.5f;
    float outputMix = 1.0f;
    float outputWidth = 1.0f;
    // Audio-thread-owned values used to ramp common strip controls across a
    // block. Control commands only change the public targets above.
    float smoothedGain = 1.0f;
    float smoothedPan = 0.5f;
    float smoothedOutputMix = 1.0f;
    float smoothedOutputWidth = 1.0f;
    bool commonSmoothingReady = false;
    DeviceExecutionPlan executionPlan{};
    InstrumentVoicePolicy voicePolicy{};
    uint64_t stableProcessorNodeId = 0;

protected:
    DeviceProcessor() = default;
    DeviceProcessor(const DeviceProcessor&) = delete;
    DeviceProcessor& operator=(const DeviceProcessor&) = delete;

    const std::string& deviceId() const noexcept { return deviceId_; }

private:
    std::string deviceId_;
    DeviceVariantParams storedParams_;
};

} // namespace audioapp
