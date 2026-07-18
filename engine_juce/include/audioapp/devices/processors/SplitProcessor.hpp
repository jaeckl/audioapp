#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"

#include <memory>

namespace audioapp {

/// LR or Mid-Side split container. Encodes the incoming stereo signal into
/// two independent branch signals, runs each branch's device chain, then
/// decodes back to LR. Branch0 is processed in place on the AudioBlock's own
/// channels (it needs no dedicated buffer); only branch1 needs a scratch pair.
class SplitProcessor final : public DeviceProcessor {
    struct BranchRuntime {
        std::unique_ptr<ProcessorArena> arena;
        CompiledDeviceExecutionOrder executionOrder{};
    };

    std::shared_ptr<const SplitPlayback> playback_;
    BranchRuntime branches_[2];
    CompiledDeviceSubgraphSchedule schedule_{};
    float scratchL1_[kScratchFrames]{};
    float scratchR1_[kScratchFrames]{};

    void runBranch(int branchIndex, float* left, float* right, int numSamples,
                   ProcessContext& ctx) noexcept;

public:
    void initParams(const DeviceVariantParams& params) noexcept override;
    bool updateNestedDevice(const DeviceNodePlayback& node,
                            bool paramsChanged = true) noexcept override;
    bool setNestedCompiledParameter(uint64_t processorNodeId,
                                    uint16_t parameterId,
                                    float value,
                                    ParameterUpdateRate rate,
                                    float startValue) noexcept override;
    bool setNestedResolvedAsset(uint64_t processorNodeId,
                                const ResolvedAssetUpdate& update) noexcept override;
    bool readNestedEffectiveParameter(uint64_t processorNodeId,
                                     uint16_t parameterId,
                                     float& value,
                                     float* automationBase = nullptr) const noexcept override;
    void bindCompiledParameterSpans(const AutomationClipPlayback* clips,
                                    int clipCount,
                                    const ModulationEdgePlayback* edges,
                                    int edgeCount) noexcept override;
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    void resetPlaybackState() noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Split; }
};

} // namespace audioapp
