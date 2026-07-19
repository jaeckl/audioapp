#pragma once

#include "audioapp/SubtractiveSynthAlgorithm.hpp"

namespace audioapp {

/// SIMD unison oscillator bank (no hard-sync). Returns false when scalar fallback required.
bool renderOscBankNoSyncSimd(float shape,
                             float rootHz,
                             const float* phaseIncPerUnit,
                             int unisonCount,
                             float level,
                             float* phases,
                             bool* wrappedOut,
                             float& sumOut) noexcept;

} // namespace audioapp
