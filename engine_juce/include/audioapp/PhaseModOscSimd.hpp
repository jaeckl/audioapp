#pragma once

#include "audioapp/PhaseModSynthAlgorithm.hpp"

namespace audioapp {

/// SIMD unison bank for one operator step: advance phases, add mod, morph wave * level.
/// phases/incs/modPhases/out are length unisonCount (1..4). Returns false → scalar fallback.
bool renderPhaseModUnisonOpSimd(float shape,
                                float level,
                                float opHz,
                                const float* phaseIncs,
                                float* phases,
                                const float* modPhases,
                                int unisonCount,
                                float* outSamples) noexcept;

} // namespace audioapp
