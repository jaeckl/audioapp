#pragma once

#include <cstdint>
#include <vector>

namespace audioapp {

struct WavPcmData {
    std::vector<float> mono;
    double sampleRate = 48000.0;
};

bool decodeWavMonoFloat(const std::vector<uint8_t>& bytes, WavPcmData& out);

} // namespace audioapp
