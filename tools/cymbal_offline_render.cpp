#include "audioapp/CymbalGenerator.hpp"
#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <vector>

namespace {

constexpr double kSampleRate = 48000.0;
constexpr int kMidiPitch = 60; // C4
constexpr double kDurationSec = 2.0;

void writeWav(const std::string& path, const std::vector<float>& samples) {
    std::ofstream out(path, std::ios::binary);
    if (!out) {
        throw std::runtime_error("cannot open " + path);
    }
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
    audioapp::CymbalGeneratorParams params{};
    params.gain = 1.0f;
    params.cymbalModel = 0.0f; // Closed
    params.cymbalColor = 0.68f;
    params.cymbalWidth = 0.35f;
    params.cymbalDecay = 0.50f;
    params.cymbalVelocity = 1.0f;

    audioapp::CymbalVoiceRuntime voice{};
    audioapp::triggerCymbalVoice(voice, kMidiPitch, 100.0f);

    const int frames = static_cast<int>(kDurationSec * kSampleRate);
    std::vector<float> mono(static_cast<size_t>(frames), 0.0f);

    for (int i = 0; i < frames; ++i) {
        voice.elapsedSec = static_cast<double>(i) / kSampleRate;
        const float left =
            audioapp::cymbalGeneratorSampleL(voice, params, kSampleRate, 1.0f);
        const float right =
            audioapp::cymbalGeneratorSampleR(voice, params, kSampleRate, 1.0f);
        mono[static_cast<size_t>(i)] = (left + right) * 0.5f;
        if (voice.active == 0) {
            break;
        }
    }

    writeWav("build/cymbal_generator_render.wav", mono);

    float peak = 0.0f;
    for (float s : mono) {
        peak = std::max(peak, std::abs(s));
    }
    std::cout << "cymbal_generator_render peak=" << peak << " frames=" << frames << '\n';
    return 0;
}
