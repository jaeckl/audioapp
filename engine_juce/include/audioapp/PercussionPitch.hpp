#pragma once

#include <algorithm>
#include <cmath>

namespace audioapp {

inline float percussionPitchRatio(float normalizedPitch,
                                  int midiPitch,
                                  int referencePitch,
                                  float keyTrack) noexcept {
    const float baseSemitones =
        (std::clamp(normalizedPitch, 0.0f, 1.0f) - 0.5f) * 48.0f;
    const float keySemitones = keyTrack >= 0.5f
        ? static_cast<float>(midiPitch - referencePitch)
        : 0.0f;
    return std::pow(2.0f, (baseSemitones + keySemitones) / 12.0f);
}

} // namespace audioapp
