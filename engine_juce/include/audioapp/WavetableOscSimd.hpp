#pragma once

#include "audioapp/WavetableSynthAlgorithm.hpp"

namespace audioapp {

/// SIMD unison wavetable bank. Same frameIndex for all lanes; phases advance in parallel.
/// Returns false when scalar fallback required (no SIMD, bad args).
bool renderWavetableUnisonBankSimd(const float* table,
                                   int frameCount,
                                   int frameLength,
                                   float frameIndex,
                                   float rootHz,
                                   const float* unisonHzRatio,
                                   int unisonCount,
                                   float invSampleRate,
                                   float* phases,
                                   float& sumOut) noexcept;

} // namespace audioapp
