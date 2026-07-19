#pragma once

#include "audioapp/GranularAlgorithm.hpp"

namespace audioapp {

/// SIMD 4-wide grain window + PCM lerp. Returns false → use scalar.
/// For each active grain lane: phases[i] in [0,1), positions are float sample indices.
bool renderGranularGrainBankSimd(const float* pcm,
                                 int frameCount,
                                 const float* phases,
                                 const float* positions,
                                 const float* pans,
                                 int grainCount,
                                 float amp,
                                 float& leftOut,
                                 float& rightOut,
                                 bool stereoSpread) noexcept;

} // namespace audioapp
