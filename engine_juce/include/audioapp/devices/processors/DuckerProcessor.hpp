#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"
#include "audioapp/DynamicsProcessor.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceSubgraph.hpp"

#include <memory>

namespace audioapp {

class DuckerProcessor : public DeviceProcessor {
public:
    void initParams(const DeviceVariantParams& params) noexcept override;
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    void resetPlaybackState() noexcept override;
    bool updateNestedDevice(const DeviceNodePlayback& node,
                            bool paramsChanged = true) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Ducker; }

private:
    void rebuildSidechainFx(const DuckerParams& params) noexcept;

    DynamicsRuntime runtime_{};
    std::shared_ptr<const ChainPlayback> sidechainFx_;
    std::unique_ptr<ProcessorArena> arena_;
    CompiledDeviceSubgraphSchedule schedule_{};
    CompiledDeviceExecutionOrder executionOrder_{};
    float keyL_[kScratchFrames]{};
    float keyR_[kScratchFrames]{};
};

} // namespace audioapp
