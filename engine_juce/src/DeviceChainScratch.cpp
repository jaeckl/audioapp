#include "audioapp/DeviceChainScratch.hpp"

#include <algorithm>

namespace audioapp {

DeviceChainScratchGuard::DeviceChainScratchGuard(DeviceChainScratch& scratch,
                                                 int numFrames) noexcept
    : scratch_(scratch),
      numFrames_(std::clamp(numFrames, 0, kScratchFrames))
{
    if (scratch_.scratchNestDepth >= DeviceChainScratch::kMaxScratchNestDepth ||
        numFrames_ <= 0) {
        return;
    }
    savedDepth_ = scratch_.scratchNestDepth;
    auto& frame = scratch_.nestFrames[savedDepth_];
    const size_t bytes = static_cast<size_t>(numFrames_) * sizeof(float);
    std::memcpy(frame.perFrameGain, scratch_.perFrameGain, bytes);
    std::memcpy(frame.perFramePan, scratch_.perFramePan, bytes);
    std::memcpy(frame.tempStereoL, scratch_.tempStereoL, bytes);
    std::memcpy(frame.tempStereoR, scratch_.tempStereoR, bytes);
    ++scratch_.scratchNestDepth;
}

DeviceChainScratchGuard::~DeviceChainScratchGuard() noexcept {
    if (savedDepth_ < 0) return;
    --scratch_.scratchNestDepth;
    const auto& frame = scratch_.nestFrames[savedDepth_];
    const size_t bytes = static_cast<size_t>(numFrames_) * sizeof(float);
    std::memcpy(scratch_.perFrameGain, frame.perFrameGain, bytes);
    std::memcpy(scratch_.perFramePan, frame.perFramePan, bytes);
    std::memcpy(scratch_.tempStereoL, frame.tempStereoL, bytes);
    std::memcpy(scratch_.tempStereoR, frame.tempStereoR, bytes);
}

} // namespace audioapp
