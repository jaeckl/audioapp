#pragma once

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/model/TrackModel.hpp"

#include <string>

namespace audioapp {

/// Resolve a string paramId to a localParamId for a given device kind.
uint16_t paramIdFromString(const char* name, DeviceNodeKind kind) noexcept;
/// Encode automation/mod targets for the audio thread (never raw per-kind ids).
uint16_t encodeAutomationParamId(const char* name,
                                 DeviceNodeKind kind,
                                 uint16_t rawPerKindId) noexcept;
/// Reverse: localParamId → stable name for a given device kind.
const char* paramIdToString(uint16_t localParamId, DeviceNodeKind kind) noexcept;

/// Param descriptor tables for each device kind.
const ParamDescriptor* paramDescriptorsForKind(DeviceNodeKind kind, int& countOut) noexcept;

/// Linear interpolation of automation envelope; beat is relative to clip start.
float evaluateAutomationEnvelope(const AutomationPointPlayback* points,
                                 int pointCount,
                                 float beatInClip) noexcept;

/// Apply an absolute automation value (0..1) to device params for block-rate DSP.
void applyAutomationValue(DeviceVariantParams& params,
                          DeviceNodeKind kind,
                          uint16_t localParamId,
                          float value) noexcept;

bool automationClipPlaybackFromClip(const AutomationClip& clip,
                                    AutomationClipPlayback& out) noexcept;

/// Maps global beat to clip-local beat; returns false when outside audible span.
bool automationBeatInClip(const AutomationClipPlayback& clip,
                          double beat,
                          float& beatInClipOut) noexcept;

/// True when [clips] contains a non-gain/pan automation target for [deviceIndex].
bool nodeHasDspAutomation(uint16_t deviceIndex,
                          const AutomationClipPlayback* clips,
                          int clipCount) noexcept;

/// Apply all active automation clips at [beat] (absolute timeline beats).
void applyDspAutomationAtBeat(DeviceVariantParams& params,
                              DeviceNodeKind kind,
                              uint16_t deviceIndex,
                              double beat,
                              const AutomationClipPlayback* clips,
                              int clipCount) noexcept;

} // namespace audioapp