#pragma once

#include "audioapp/SubtractiveSynthAlgorithm.hpp"

namespace audioapp {

/// SIMD unison oscillator bank (no hard-sync). Returns false when scalar fallback required.
/// sampleRate selects morph-table mip (anti-alias).
bool renderOscBankNoSyncSimd(float shape,
                             float rootHz,
                             float sampleRate,
                             const float* phaseIncPerUnit,
                             int unisonCount,
                             float level,
                             float* phases,
                             bool* wrappedOut,
                             float& sumOut) noexcept;

} // namespace audioapp
