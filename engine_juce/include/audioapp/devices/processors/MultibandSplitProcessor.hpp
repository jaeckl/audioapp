#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"
#include "audioapp/devices/instances/MultibandSplitModel.hpp"

#include <juce_dsp/juce_dsp.h>

#include <memory>

namespace audioapp {

struct DeviceChainScratchArena;

/// Cascaded Linkwitz-Riley multiband split (juce::dsp::LinkwitzRileyFilter).
/// Bands processed sequentially with ProcessContext scratch buffers.
class MultibandSplitProcessor final : public DeviceProcessor {
    struct BandRuntime {
        std::unique_ptr<ProcessorArena> arena;
        CompiledDeviceExecutionOrder executionOrder{};
    };

    std::shared_ptr<const MultibandSplitPlayback> playback_;
    BandRuntime bands_[kMaxMbBands];
    CompiledDeviceSubgraphSchedule schedule_{};
    float workL_[kScratchFrames]{};
    float workR_[kScratchFrames]{};
    float* bandL_ = nullptr;
    float* bandR_ = nullptr;
    float* outL_ = nullptr;
    float* outR_ = nullptr;
    DeviceChainScratchArena* bufferArena_ = nullptr;
    juce::dsp::LinkwitzRileyFilter<float> xoL_[3];
    juce::dsp::LinkwitzRileyFilter<float> xoR_[3];
    double lastSr_ = 0.0;

    bool ensureBuffers(ProcessContext& ctx) noexcept;
    void prepareFilters(double sampleRate) noexcept;
    void runBand(int bandIndex, float* left, float* right, int numSamples,
                 ProcessContext& ctx) noexcept;
    void accumulateBand(float* left, float* right, float gain, float* outL, float* outR,
                        int numSamples, float& peak) noexcept;

public:
    ~MultibandSplitProcessor() override;
    void initParams(const DeviceVariantParams& params) noexcept override;
    bool updateNestedDevice(const DeviceNodePlayback& node,
                            bool paramsChanged = true) noexcept override;
    bool setNestedCompiledParameter(uint64_t processorNodeId, uint16_t parameterId,
                                    float value, ParameterUpdateRate rate,
                                    float startValue) noexcept override;
    bool setNestedResolvedAsset(uint64_t processorNodeId,
                                const ResolvedAssetUpdate& update) noexcept override;
    bool readNestedEffectiveParameter(uint64_t processorNodeId, uint16_t parameterId,
                                      float& value,
                                      float* automationBase = nullptr) const noexcept override;
    void bindCompiledParameterSpans(const AutomationClipPlayback* clips, int clipCount,
                                    const ModulationEdgePlayback* edges,
                                    int edgeCount) noexcept override;
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    void resetPlaybackState() noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::MultibandSplit; }
};

} // namespace audioapp
