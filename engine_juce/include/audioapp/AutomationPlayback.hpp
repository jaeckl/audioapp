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
                          ParamId paramId,
                          float value) noexcept;

bool automationClipPlaybackFromClip(const AutomationClip& clip,
                                    AutomationClipPlayback& out) noexcept;

/// True when [clips] contains a non-gain/pan automation target for [deviceId].
bool nodeHasDspAutomation(const std::string& deviceId,
                          const AutomationClipPlayback* clips,
                          int clipCount) noexcept;

/// Apply all active automation clips at [beat] (absolute timeline beats).
void applyDspAutomationAtBeat(DeviceVariantParams& params,
                              DeviceNodeKind kind,
                              const std::string& deviceId,
                              double beat,
                              const AutomationClipPlayback* clips,
                              int clipCount) noexcept;

} // namespace audioapp