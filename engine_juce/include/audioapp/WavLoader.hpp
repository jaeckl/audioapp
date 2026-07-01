#pragma once

#include <cstdint>
#include <vector>

namespace audioapp {

struct WavPcmData {
    std::vector<float> mono;
    double sampleRate = 48000.0;
};

struct WavStereoPcmData {
    std::vector<float> left;
    std::vector<float> right;
    double sampleRate = 48000.0;
};

bool decodeWavMonoFloat(const std::vector<uint8_t>& bytes, WavPcmData& out);
bool decodeWavStereoFloat(const std::vector<uint8_t>& bytes, WavStereoPcmData& out);

std::vector<uint8_t> encodeStereoWavFloat32(const float* left,
                                            const float* right,
                                            int frameCount,
                                            double sampleRate);

} // namespace audioapp
