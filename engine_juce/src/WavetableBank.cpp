#include "audioapp/WavetableBank.hpp"
#include <cstring>
#include <algorithm>
#ifdef __ANDROID__
#include <android/log.h>
#define WT_LOG(...) __android_log_print(ANDROID_LOG_INFO, "audioapp_engine", __VA_ARGS__)
#else
#define WT_LOG(...) ((void)0)
#endif

namespace audioapp {

namespace {

struct WavHeader {
    char riff[4] = {'R', 'I', 'F', 'F'};
    uint32_t fileSize = 0;
    char wave[4] = {'W', 'A', 'V', 'E'};
    char fmtId[4] = {'f', 'm', 't', ' '};
    uint32_t fmtSize = 16;
    uint16_t audioFormat = 1; // PCM
    uint16_t numChannels = 1;
    uint32_t sampleRate = 48000;
    uint32_t byteRate = 48000 * 2;
    uint16_t blockAlign = 2;
    uint16_t bitsPerSample = 16;
    char dataId[4] = {'d', 'a', 't', 'a'};
    uint32_t dataSize = 0;
};

} // anonymous namespace

int WavetableBank::loadFromBytes(const std::string& name, const uint8_t* data, size_t dataSize) {
    if (data == nullptr || dataSize < sizeof(WavHeader)) return -1;

    // Parse RIFF header
    const auto* header = reinterpret_cast<const WavHeader*>(data);
    if (std::memcmp(header->riff, "RIFF", 4) != 0 ||
        std::memcmp(header->wave, "WAVE", 4) != 0) {
        return -1;
    }

    const uint16_t numChannels = header->numChannels;
    const uint32_t sampleRate = header->sampleRate;
    const uint16_t bitsPerSample = header->bitsPerSample;
    uint32_t dataSizeActual = header->dataSize;

    // Validate basic params
    if (numChannels == 0 || sampleRate == 0 || bitsPerSample == 0) return -1;
    if (dataSizeActual == 0 || dataSizeActual > dataSize - sizeof(WavHeader)) {
        dataSizeActual = static_cast<uint32_t>(dataSize - sizeof(WavHeader));
    }

    // Number of samples per channel
    const uint32_t bytesPerSample = bitsPerSample / 8;
    if (bytesPerSample == 0) return -1;
    const uint32_t totalSamples = dataSizeActual / bytesPerSample;
    const uint32_t framesPerChannel = totalSamples / numChannels;

    if (framesPerChannel == 0) return -1;

    const float* pcmData = nullptr;
    std::vector<float> convertedPcm;

    if (bitsPerSample == 16) {
        // Interpret as mono or stereo (stereo gets collapsed to mono)
        const auto* samples = reinterpret_cast<const int16_t*>(data + sizeof(WavHeader));
        convertedPcm.resize(framesPerChannel);
        if (numChannels == 1) {
            for (uint32_t i = 0; i < framesPerChannel; ++i) {
                convertedPcm[i] = static_cast<float>(samples[i]) / 32768.0f;
            }
        } else {
            // Collapse stereo to mono
            for (uint32_t i = 0; i < framesPerChannel; ++i) {
                float sum = 0.0f;
                for (uint16_t ch = 0; ch < numChannels; ++ch) {
                    sum += static_cast<float>(samples[i * numChannels + ch]) / 32768.0f;
                }
                convertedPcm[i] = sum / static_cast<float>(numChannels);
            }
        }
        pcmData = convertedPcm.data();
    } else if (bitsPerSample == 32) {
        const auto* samples = reinterpret_cast<const float*>(data + sizeof(WavHeader));
        convertedPcm.resize(framesPerChannel);
        if (numChannels == 1) {
            for (uint32_t i = 0; i < framesPerChannel; ++i) {
                convertedPcm[i] = std::clamp(samples[i], -1.0f, 1.0f);
            }
        } else {
            for (uint32_t i = 0; i < framesPerChannel; ++i) {
                float sum = 0.0f;
                for (uint16_t ch = 0; ch < numChannels; ++ch) {
                    sum += std::clamp(samples[i * numChannels + ch], -1.0f, 1.0f);
                }
                convertedPcm[i] = sum / static_cast<float>(numChannels);
            }
        }
        pcmData = convertedPcm.data();
    } else {
        return -1;
    }

    // Detect frame length: find first zero crossing that gives consistent period
    // Typically Serum/Vital wavetables have power-of-2 frame lengths (64, 128, 256, 512, 1024, 2048)
    // Try to detect by looking at number of zero crossings or sample count
    int frameLength = 0;
    int frameCount = 0;

    // Check for power-of-2 frame length
    static constexpr int kPossibleFrameLengths[] = {32, 64, 128, 256, 512, 1024, 2048};
    for (auto fl : kPossibleFrameLengths) {
        if (fl > 0 && framesPerChannel % fl == 0) {
            const int fc = static_cast<int>(framesPerChannel) / fl;
            if (fc >= 1 && fc <= 256) {
                frameLength = fl;
                frameCount = fc;
                break;
            }
        }
    }

    if (frameLength == 0) {
        // Fall back: treat entire file as single frame
        frameLength = static_cast<int>(framesPerChannel);
        frameCount = 1;
    }

    WT_LOG("loadFromBytes[%s] framesPerChannel=%u frameLength=%d frameCount=%d numChannels=%u bitsPerSample=%u sampleRate=%u",
           name.c_str(), framesPerChannel, frameLength, frameCount, numChannels, bitsPerSample, sampleRate);

    WavetableEntry entry;
    entry.name = name;
    entry.pcm = std::move(convertedPcm);
    entry.frameCount = frameCount;
    entry.frameLength = frameLength;
    entry.sampleRate = static_cast<float>(sampleRate);

    entries_.push_back(std::move(entry));
    WT_LOG("loadFromBytes[%s] OK, total entries=%zu", name.c_str(), entries_.size());
    return static_cast<int>(entries_.size()) - 1;
}

const WavetableEntry* WavetableBank::get(int index) const noexcept {
    if (index < 0 || index >= static_cast<int>(entries_.size())) return nullptr;
    return &entries_[static_cast<size_t>(index)];
}

int WavetableBank::findByName(const std::string& name) const noexcept {
    for (size_t i = 0; i < entries_.size(); ++i) {
        if (entries_[i].name == name) {
            WT_LOG("findByName[%s] -> %zu", name.c_str(), i);
            return static_cast<int>(i);
        }
    }
    WT_LOG("findByName[%s] -> NOT FOUND (entries=%zu)", name.c_str(), entries_.size());
    return -1;
}

} // namespace audioapp
