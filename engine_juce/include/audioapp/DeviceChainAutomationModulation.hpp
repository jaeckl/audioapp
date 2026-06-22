#pragma once

#include <cstdint>
#include <variant>

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"

namespace audioapp::DeviceChainAutomationModulation {

void applyModulation(OscillatorParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(SamplerParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(TrackGainParams&, float, uint16_t) noexcept;
void applyModulation(DelayParamsPlayback&, float, uint16_t) noexcept;
void applyModulation(ReverbParamsPlayback&, float, uint16_t) noexcept;
void applyModulation(ChorusParamsPlayback&, float, uint16_t) noexcept;
void applyModulation(PhaserParamsPlayback&, float, uint16_t) noexcept;
void applyModulation(FilterParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(FourBandEqParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(FrequencyShifterParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(SubtractiveSynthParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(KickGeneratorParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(SnareGeneratorParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(ClapGeneratorParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(CymbalGeneratorParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(CrashGeneratorParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(GateParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(CompressorParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(ExpanderParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(LimiterParams& p, float modAmount, uint16_t localParamId) noexcept;
void applyModulation(PhaseModSynthParams& p, float modAmount, uint16_t localParamId) noexcept;

void applyDspModulationAtFrame(DeviceVariantParams& params,
                               DeviceNodeKind kind,
                               int lfoFrame,
                               int framesToProcess,
                               const float* lfoValues,
                               int lfoCount,
                               const ModulationEdgePlayback* modEdges,
                               int modEdgeCount) noexcept;

DeviceVariantParams dspParamsAtFrame(const DeviceNodePlayback& node,
                                     int deviceIndex,
                                     double beat,
                                     int lfoFrame,
                                     int framesToProcess,
                                     const AutomationClipPlayback* automationClips,
                                     int automationClipCount,
                                     const float* lfoValues,
                                     int lfoCount,
                                     const ModulationEdgePlayback* modEdges,
                                     int modEdgeCount);

bool nodeNeedsSubBlocks(const DeviceNodePlayback& node,
                        int deviceIndex,
                        const AutomationClipPlayback* clips,
                        int clipCount,
                        const ModulationEdgePlayback* modEdges,
                        int modEdgeCount) noexcept;

bool nodeUsesDspAutomationSubBlocks(const DeviceNodePlayback& node,
                                    int deviceIndex,
                                    const AutomationClipPlayback* clips,
                                    int clipCount) noexcept;

bool nodeHasDspModulation(uint16_t deviceIndex,
                          const ModulationEdgePlayback* modEdges,
                          int modEdgeCount) noexcept;

} // namespace audioapp::DeviceChainAutomationModulation