#include "audioapp/WavLoader.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

bool readU32LE(const uint8_t* bytes, uint32_t& out) {
    if (bytes == nullptr) {
        return false;
    }
    out = static_cast<uint32_t>(bytes[0]) | (static_cast<uint32_t>(bytes[1]) << 8) |
          (static_cast<uint32_t>(bytes[2]) << 16) | (static_cast<uint32_t>(bytes[3]) << 24);
    return true;
}

bool readU16LE(const uint8_t* bytes, uint16_t& out) {
    if (bytes == nullptr) {
        return false;
    }
    out = static_cast<uint16_t>(bytes[0]) | (static_cast<uint16_t>(bytes[1]) << 8);
    return true;
}

} // namespace

bool decodeWavMonoFloat(const std::vector<uint8_t>& bytes, WavPcmData& out) {
    out = {};
    if (bytes.size() < 44) {
        return false;
    }
    if (std::memcmp(bytes.data(), "RIFF", 4) != 0 || std::memcmp(bytes.data() + 8, "WAVE", 4) != 0) {
        return false;
    }

    uint16_t audioFormat = 0;
    uint16_t numChannels = 0;
    uint32_t sampleRate = 0;
    uint16_t bitsPerSample = 0;
    const uint8_t* dataPtr = nullptr;
    uint32_t dataSize = 0;

    size_t offset = 12;
    while (offset + 8 <= bytes.size()) {
        const auto* chunkId = bytes.data() + offset;
        uint32_t chunkSize = 0;
        if (!readU32LE(bytes.data() + offset + 4, chunkSize) || offset + 8 + chunkSize > bytes.size()) {
            break;
        }
        const auto* chunkData = bytes.data() + offset + 8;
        if (std::memcmp(chunkId, "fmt ", 4) == 0 && chunkSize >= 16) {
            readU16LE(chunkData, audioFormat);
            readU16LE(chunkData + 2, numChannels);
            readU32LE(chunkData + 4, sampleRate);
            readU16LE(chunkData + 14, bitsPerSample);
        } else if (std::memcmp(chunkId, "data", 4) == 0) {
            dataPtr = chunkData;
            dataSize = chunkSize;
        }
        offset += 8 + chunkSize;
    }

    if (audioFormat != 1 || dataPtr == nullptr || dataSize == 0 || numChannels == 0 ||
        bitsPerSample == 0) {
        return false;
    }

    const size_t bytesPerSample = bitsPerSample / 8;
    const size_t frameCount = dataSize / (bytesPerSample * numChannels);
    if (frameCount == 0) {
        return false;
    }

    out.sampleRate = static_cast<double>(sampleRate);
    out.mono.resize(frameCount, 0.0f);

    for (size_t frame = 0; frame < frameCount; ++frame) {
        float mixed = 0.0f;
        for (uint16_t channel = 0; channel < numChannels; ++channel) {
            const size_t sampleOffset =
                frame * numChannels * bytesPerSample + static_cast<size_t>(channel) * bytesPerSample;
            if (sampleOffset + bytesPerSample > dataSize) {
                return false;
            }
            const auto* sampleBytes = dataPtr + sampleOffset;
            float value = 0.0f;
            if (bitsPerSample == 16) {
                int16_t raw = 0;
                std::memcpy(&raw, sampleBytes, sizeof(raw));
                value = static_cast<float>(raw) / 32768.0f;
            } else if (bitsPerSample == 8) {
                value = (static_cast<float>(sampleBytes[0]) - 128.0f) / 128.0f;
            } else {
                return false;
            }
            mixed += value;
        }
        out.mono[frame] = mixed / static_cast<float>(numChannels);
    }

    return true;
}

} // namespace audioapp
