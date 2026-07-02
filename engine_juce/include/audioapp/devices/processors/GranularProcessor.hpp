#pragma once
#include "audioapp/dsp/DeviceProcessor.hpp"
namespace audioapp { class GranularProcessor final:public DeviceProcessor {
 float z1_[2][3]{},z2_[2][3]{};
 public:void process(AudioBlock&,ProcessContext&) noexcept override;
 void resetPlaybackState() noexcept override; DeviceNodeKind kind()const noexcept override{return DeviceNodeKind::Granular;}
}; }
