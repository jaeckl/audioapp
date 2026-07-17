#pragma once
#include "audioapp/dsp/DeviceProcessor.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"
#include <memory>
namespace audioapp { class ChainProcessor final:public DeviceProcessor { std::shared_ptr<const ChainPlayback> playback_; std::unique_ptr<ProcessorArena> arena_; CompiledDeviceSubgraphSchedule schedule_{}; CompiledDeviceExecutionOrder executionOrder_{}; float dryL_[kScratchFrames]{},dryR_[kScratchFrames]{}; public:void initParams(const DeviceVariantParams&) noexcept override;bool updateNestedDevice(const DeviceNodePlayback&,bool paramsChanged=true) noexcept override;bool setNestedCompiledParameter(uint64_t,uint16_t,float) noexcept override;void process(AudioBlock&,ProcessContext&) noexcept override;void resetPlaybackState() noexcept override;DeviceNodeKind kind()const noexcept override{return DeviceNodeKind::Chain;} }; }
