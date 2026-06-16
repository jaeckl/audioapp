#pragma once

namespace audioapp {

/// Adds a sine tone into [inOut] (accumulates). [phase] advances for continuity.
void addSineBlock(float* inOut,
                  int numSamples,
                  double sampleRate,
                  float frequencyHz,
                  float& phase,
                  float gain) noexcept;

} // namespace audioapp
