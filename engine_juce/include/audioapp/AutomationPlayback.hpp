#pragma once

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/model/TrackModel.hpp"

#include <string>

namespace audioapp {

/// Linear interpolation of automation envelope; beat is relative to clip start.
float evaluateAutomationEnvelope(const AutomationPointPlayback* points,
                                 int pointCount,
                                 float beatInClip) noexcept;

/// Apply an absolute automation value (0..1) to device params for block-rate DSP.
void applyAutomationValue(DeviceVariantParams& params,
                          DeviceNodeKind kind,
                          const std::string& paramId,
                          float value) noexcept;

bool automationClipPlaybackFromClip(const AutomationClip& clip,
                                    AutomationClipPlayback& out) noexcept;

} // namespace audioapp
