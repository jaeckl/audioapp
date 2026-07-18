#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceSubgraph.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/dsp/AudioBlock.hpp"
#include "audioapp/dsp/ProcessContext.hpp"

#include <string_view>
#include <array>
#include <atomic>
#include <cmath>
#include <limits>

namespace audioapp {

// Must cover the largest registered device parameter set. This is fixed-size
// realtime storage: no callback allocation and no silent eviction.
inline constexpr size_t kMaxCompiledParametersPerProcessor = 128;

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

    /// Apply a pre-resolved parameter handle. Common strip values are physical
    /// values; DSP values are normalized through the same evaluator used by
    /// automation. Called only by the audio thread at a block boundary.
    bool setCompiledParameter(uint16_t parameterId, float value,
                              ParameterUpdateRate rate = ParameterUpdateRate::Smoothed,
                              float startValue = std::numeric_limits<float>::quiet_NaN()) noexcept {
        if (unpackParamKind(parameterId) == ParamKind::Common) {
            switch (unpackParamId(parameterId)) {
            case 0: gain = value; publishEffectiveParameter(parameterId, value); return true;
            case 1: pan = value; publishEffectiveParameter(parameterId, value); return true;
            case 2: bypassed = value >= 0.5f; publishEffectiveParameter(parameterId, value); return true;
            case 3: outputMix = value; publishEffectiveParameter(parameterId, value); return true;
            case 4: outputWidth = value; publishEffectiveParameter(parameterId, value); return true;
            default: return false;
            }
        }
        if (rate == ParameterUpdateRate::Discrete ||
            rate == ParameterUpdateRate::Block) {
            for (auto& state : compiledParameterStates_)
                if (state.active && state.parameterId == parameterId)
                    state.active = false;
            applyAutomationValue(storedParams_, kind(), parameterId, value);
            publishEffectiveParameter(parameterId, value);
            return true;
        }
        CompiledParameterState* state = nullptr;
        for (auto& candidate : compiledParameterStates_) {
            if (candidate.active && candidate.parameterId == parameterId) {
                state = &candidate;
                break;
            }
            if (!candidate.active && state == nullptr) state = &candidate;
        }
        if (state == nullptr) return false;
        if (!state->active) {
            state->active = true;
            state->parameterId = parameterId;
            state->current = std::isfinite(startValue) ? startValue : value;
        }
        state->target = value;
        state->rate = rate;
        applyAutomationValue(storedParams_, kind(), parameterId, value);
        publishEffectiveParameter(parameterId, state->current);
        return true;
    }

    void applyCompiledParameterSmoothing(DeviceVariantParams& params,
                                         int numFrames,
                                         double sampleRate) noexcept {
        const float frames = static_cast<float>(std::max(numFrames, 1));
        const float rate = static_cast<float>(std::max(sampleRate, 1.0));
        for (auto& state : compiledParameterStates_) {
            if (!state.active) continue;
            float coefficient = 1.0f;
            if (state.rate == ParameterUpdateRate::Smoothed)
                coefficient = 1.0f - std::exp(-frames / (rate * 0.010f));
            else if (state.rate == ParameterUpdateRate::ControlRate)
                coefficient = 1.0f - std::exp(-frames / (rate * 0.003f));
            state.current += (state.target - state.current) * coefficient;
            if (std::abs(state.target - state.current) < 1.0e-6f)
                state.current = state.target;
            applyAutomationValue(params, kind(), state.parameterId, state.current);
            publishEffectiveParameter(state.parameterId, state.current);
        }
    }

    bool readEffectiveParameter(uint16_t parameterId, float& value) const noexcept {
        for (const auto& slot : effectiveParameterSlots_) {
            if (slot.parameterId.load(std::memory_order_acquire) != parameterId)
                continue;
            value = slot.value.load(std::memory_order_acquire);
            return true;
        }
        return false;
    }

    /// Publish the normalized value after base, automation, and modulation
    /// have been combined. The monitor is observational and never feeds DSP.
    void publishFinalEffectiveParameter(uint16_t parameterId, float value) noexcept {
        publishEffectiveParameter(parameterId, std::clamp(value, 0.0f, 1.0f));
    }

    virtual bool readNestedEffectiveParameter(uint64_t processorNodeId,
                                              uint16_t parameterId,
                                              float& value) const noexcept {
        (void)processorNodeId;
        (void)parameterId;
        (void)value;
        return false;
    }

    virtual bool setNestedCompiledParameter(uint64_t processorNodeId,
                                            uint16_t parameterId,
                                            float value,
                                            ParameterUpdateRate rate = ParameterUpdateRate::Smoothed,
                                            float startValue = std::numeric_limits<float>::quiet_NaN()) noexcept {
        (void)processorNodeId;
        (void)parameterId;
        (void)value;
        (void)rate;
        (void)startValue;
        return false;
    }

    virtual void bindCompiledParameterSpans(
        const AutomationClipPlayback* clips, int clipCount,
        const ModulationEdgePlayback* edges, int edgeCount) noexcept {
        automationSpanOffset = automationSpanCount = 0;
        modulationSpanOffset = modulationSpanCount = 0;
        for (int index = 0; index < clipCount; ++index) {
            if (clips[index].targetNodeId != stableProcessorNodeId) continue;
            if (automationSpanCount == 0)
                automationSpanOffset = static_cast<uint8_t>(index);
            ++automationSpanCount;
        }
        for (int index = 0; index < edgeCount; ++index) {
            if (edges[index].targetNodeId != stableProcessorNodeId) continue;
            if (modulationSpanCount == 0)
                modulationSpanOffset = static_cast<uint8_t>(index);
            ++modulationSpanCount;
        }
    }

    virtual bool updateDrumPadParameter(int note, DrumPadParameter parameter,
                                        float value) noexcept {
        (void)note;
        (void)parameter;
        (void)value;
        return false;
    }

    bool applyResolvedAsset(const ResolvedAssetUpdate& update) noexcept {
        if (update.kind == DeviceNodeKind::Sampler) {
            auto* params = std::get_if<SamplerParams>(&storedParams_);
            if (params == nullptr) return false;
            params->samplerPcm = update.sampler.samplerPcm;
            params->samplerFrameCount = update.sampler.samplerFrameCount;
            params->samplerPcmSampleRate = update.sampler.samplerPcmSampleRate;
            params->trimStartFrame = update.sampler.trimStartFrame;
            params->trimEndFrame = update.sampler.trimEndFrame;
            params->regionStartFrame = update.sampler.regionStartFrame;
            params->regionEndFrame = update.sampler.regionEndFrame;
            return true;
        }
        if (update.kind == DeviceNodeKind::Granular) {
            auto* params = std::get_if<GranularParams>(&storedParams_);
            if (params == nullptr) return false;
            params->pcm = update.granular.pcm;
            params->frameCount = update.granular.frameCount;
            params->pcmRate = update.granular.pcmRate;
            return true;
        }
        if (update.kind == DeviceNodeKind::WavetableSynth)
            return setResolvedWavetableIndex(update.wavetableIndex);
        return false;
    }

    virtual bool setNestedResolvedAsset(uint64_t processorNodeId,
                                        const ResolvedAssetUpdate& update) noexcept {
        (void)processorNodeId;
        (void)update;
        return false;
    }

    virtual bool setResolvedWavetableIndex(int index) noexcept {
        (void)index;
        return false;
    }

    void applyPlaybackNode(const DeviceNodePlayback& node) noexcept {
        for (auto& state : compiledParameterStates_) state.active = false;
        for (auto& slot : effectiveParameterSlots_)
            slot.parameterId.store(0xffff, std::memory_order_relaxed);
        deviceId_ = node.deviceId;
        stableProcessorNodeId = stableDeviceSubgraphNodeId(
            node.deviceId, DeviceSubgraphNodeRole::DeviceProcessor);
        stableOutputNodeId = stableDeviceSubgraphNodeId(
            node.deviceId, DeviceSubgraphNodeRole::OutputAdapter);
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
    uint64_t stableOutputNodeId = 0;
    uint8_t automationSpanOffset = 0;
    uint8_t automationSpanCount = 0;
    uint8_t modulationSpanOffset = 0;
    uint8_t modulationSpanCount = 0;

protected:
    DeviceProcessor() = default;
    DeviceProcessor(const DeviceProcessor&) = delete;
    DeviceProcessor& operator=(const DeviceProcessor&) = delete;

    const std::string& deviceId() const noexcept { return deviceId_; }

private:
    struct CompiledParameterState {
        uint16_t parameterId = 0;
        float current = 0.0f;
        float target = 0.0f;
        ParameterUpdateRate rate = ParameterUpdateRate::Smoothed;
        bool active = false;
    };
    struct EffectiveParameterSlot {
        std::atomic<uint16_t> parameterId{0xffff};
        std::atomic<float> value{0.0f};
    };
    void publishEffectiveParameter(uint16_t parameterId, float value) noexcept {
        EffectiveParameterSlot* empty = nullptr;
        for (auto& slot : effectiveParameterSlots_) {
            const auto existing = slot.parameterId.load(std::memory_order_relaxed);
            if (existing == parameterId) {
                slot.value.store(value, std::memory_order_release);
                return;
            }
            if (existing == 0xffff && empty == nullptr) empty = &slot;
        }
        if (empty != nullptr) {
            empty->value.store(value, std::memory_order_relaxed);
            empty->parameterId.store(parameterId, std::memory_order_release);
        }
    }

    std::string deviceId_;
    DeviceVariantParams storedParams_;
    std::array<CompiledParameterState,
               kMaxCompiledParametersPerProcessor> compiledParameterStates_{};
    std::array<EffectiveParameterSlot,
               kMaxCompiledParametersPerProcessor> effectiveParameterSlots_{};
};

} // namespace audioapp
