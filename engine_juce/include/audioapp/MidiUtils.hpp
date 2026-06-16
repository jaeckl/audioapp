#pragma once

#include <cmath>

namespace audioapp {

inline float midiNoteToHz(int noteNumber) noexcept {
    return 440.0f * std::pow(2.0f, static_cast<float>(noteNumber - 69) / 12.0f);
}

} // namespace audioapp
