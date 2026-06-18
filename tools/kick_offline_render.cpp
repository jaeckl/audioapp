// Render kick baseline for A/B vs snare. Build with snare_offline_render.cpp deps.
#include "audioapp/KickGenerator.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <vector>

namespace {

constexpr double kSampleRate = 48000.0;
constexpr int kFrames = static_cast<int>(0.6 * kSampleRate);

void writeWav(const std::string& path, const std::vector<float>& samples) {
    std::ofstream out(path, std::ios::binary);
    if (!out) throw std::runtime_error("cannot open " + path);
    const uint32_t dataBytes = static_cast<uint32_t>(samples.size() * sizeof(float));
    const uint16_t channels = 1;
    const uint32_t sampleRate = static_cast<uint32_t>(kSampleRate);
    const uint16_t bits = 32;
    const uint32_t byteRate = sampleRate * channels * (bits / 8);
    const uint16_t blockAlign = channels * (bits / 8);
    out.write("RIFF", 4);
    uint32_t riffSize = 36 + dataBytes;
    out.write(reinterpret_cast<const char*>(&riffSize), 4);
    out.write("WAVE", 4);
    out.write("fmt ", 4);
    uint32_t fmtSize = 16;
    out.write(reinterpret_cast<const char*>(&fmtSize), 4);
    uint16_t format = 3;
    out.write(reinterpret_cast<const char*>(&format), 2);
    out.write(reinterpret_cast<const char*>(&channels), 2);
    out.write(reinterpret_cast<const char*>(&sampleRate), 4);
    out.write(reinterpret_cast<const char*>(&byteRate), 4);
    out.write(reinterpret_cast<const char*>(&blockAlign), 2);
    out.write(reinterpret_cast<const char*>(&bits), 2);
    out.write("data", 4);
    out.write(reinterpret_cast<const char*>(&dataBytes), 4);
    out.write(reinterpret_cast<const char*>(samples.data()), static_cast<std::streamsize>(dataBytes));
}

} // namespace

int main() {
    audioapp::KickGeneratorParams params{};
    params.gain = 1.0f;
    audioapp::KickVoiceRuntime voice{};
    audioapp::triggerKickVoice(voice, 36, 100.0f);

    std::vector<float> out(static_cast<size_t>(kFrames), 0.0f);
    for (int i = 0; i < kFrames; ++i) {
        voice.elapsedSec = static_cast<double>(i) / kSampleRate;
        out[static_cast<size_t>(i)] =
            audioapp::kickGeneratorSample(voice, params, kSampleRate, 1.0f);
    }
    writeWav("build/kick_baseline.wav", out);
    float peak = 0.0f;
    for (float s : out) peak = std::max(peak, std::abs(s));
    std::cout << "kick_baseline peak=" << peak << '\n';
    return 0;
}
