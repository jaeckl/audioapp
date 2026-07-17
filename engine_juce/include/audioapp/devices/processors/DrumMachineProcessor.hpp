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
        float gain = 1.0f;
        float pan = 0.5f;
        bool muted = false;
        bool solo = false;
        int chokeGroup = 0;
        std::unique_ptr<ProcessorArena> arena;
        CompiledDeviceExecutionOrder executionOrder{};
    };
    std::vector<PadRuntime> pads_;
    std::shared_ptr<const DrumMachinePlayback> playback_;
    CompiledDeviceSubgraphSchedule schedule_{};
    float padLeft_[kScratchFrames]{};
    float padRight_[kScratchFrames]{};
    MidiPlaybackNote routedNotes_[kMaxInstrumentRegions]{};
public:
    void initParams(const DeviceVariantParams& params) noexcept override;
    bool updateNestedDevice(const DeviceNodePlayback& node,
                            bool paramsChanged = true) noexcept override;
    bool setNestedCompiledParameter(uint64_t processorNodeId,
                                    uint16_t parameterId,
                                    float value,
                                    ParameterUpdateRate rate) noexcept override;
    bool readNestedEffectiveParameter(uint64_t processorNodeId,
                                      uint16_t parameterId,
                                      float& value) const noexcept override;
    void bindCompiledParameterSpans(const AutomationClipPlayback* clips,
                                    int clipCount,
                                    const ModulationEdgePlayback* edges,
                                    int edgeCount) noexcept override;
    bool updateDrumPadParameter(int note, std::string_view parameterId,
                                float value) noexcept override;
    void process(AudioBlock&, ProcessContext&) noexcept override;
    void resetPlaybackState() noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::DrumMachine; }
};

} // namespace audioapp
