#pragma once

#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"
#include <memory>
#include <vector>

namespace audioapp {

class DrumMachineProcessor final : public DeviceProcessor {
    struct PadRuntime {
        int note = 0;
        int padIndex = 0;
        bool tailActive = false;
        std::unique_ptr<ProcessorArena> arena;
    };
    std::vector<PadRuntime> pads_;
    std::shared_ptr<const DrumMachinePlayback> playback_;
    float padLeft_[kScratchFrames]{};
    float padRight_[kScratchFrames]{};
    MidiPlaybackNote routedNotes_[kMaxInstrumentRegions]{};
public:
    void initParams(const DeviceVariantParams& params) noexcept override;
    void process(AudioBlock&, ProcessContext&) noexcept override;
    void resetPlaybackState() noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::DrumMachine; }
};

} // namespace audioapp
