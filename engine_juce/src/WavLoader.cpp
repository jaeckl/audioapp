#include "audioapp/WavLoader.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>

namespace audioapp {

namespace {

struct WavInfo {
    uint16_t audioFormat = 0;
    uint16_t numChannels = 0;
    uint32_t sampleRate = 0;
    uint16_t bitsPerSample = 0;
    const uint8_t* data = nullptr;
    size_t dataSize = 0;
};

bool isChunkId(const uint8_t* id, const char (&text)[5]) noexcept {
    return id != nullptr && std::memcmp(id, text, 4) == 0;
}

bool readU32LE(const uint8_t* bytes, uint32_t& out) noexcept {
    if (bytes == nullptr) return false;
    out = static_cast<uint32_t>(bytes[0]) |
          (static_cast<uint32_t>(bytes[1]) << 8) |
          (static_cast<uint32_t>(bytes[2]) << 16) |
          (static_cast<uint32_t>(bytes[3]) << 24);
    return true;
}

bool readU16LE(const uint8_t* bytes, uint16_t& out) noexcept {
    if (bytes == nullptr) return false;
    out = static_cast<uint16_t>(bytes[0]) |
          static_cast<uint16_t>(static_cast<uint16_t>(bytes[1]) << 8);
    return true;
}

uint32_t readU32LEUnchecked(const uint8_t* bytes) noexcept {
    uint32_t out = 0;
    readU32LE(bytes, out);
    return out;
}

uint16_t readU16LEUnchecked(const uint8_t* bytes) noexcept {
    uint16_t out = 0;
    readU16LE(bytes, out);
    return out;
}

float clampSample(float value) noexcept {
    if (!std::isfinite(value)) return 0.0f;
    return std::clamp(value, -1.0f, 1.0f);
}

bool parseWav(const std::vector<uint8_t>& bytes, WavInfo& out) noexcept {
    out = {};
    if (bytes.size() < 12) return false;
    if (!isChunkId(bytes.data(), "RIFF") || !isChunkId(bytes.data() + 8, "WAVE")) return false;

    size_t offset = 12;
    while (offset + 8 <= bytes.size()) {
        const uint8_t* chunkId = bytes.data() + offset;
        uint32_t chunkSize32 = 0;
        if (!readU32LE(bytes.data() + offset + 4, chunkSize32)) return false;
        const size_t chunkSize = static_cast<size_t>(chunkSize32);
        const size_t chunkDataOffset = offset + 8;
        if (chunkDataOffset > bytes.size() || chunkSize > bytes.size() - chunkDataOffset) {
            break;
        }

        const uint8_t* chunkData = bytes.data() + chunkDataOffset;
        if (isChunkId(chunkId, "fmt ") && chunkSize >= 16) {
            readU16LE(chunkData, out.audioFormat);
            readU16LE(chunkData + 2, out.numChannels);
            readU32LE(chunkData + 4, out.sampleRate);
            readU16LE(chunkData + 14, out.bitsPerSample);

            if (out.audioFormat == 0xfffe && chunkSize >= 40) {
                const uint16_t subFormat = readU16LEUnchecked(chunkData + 24);
                if (subFormat == 1 || subFormat == 3) {
                    out.audioFormat = subFormat;
                }
            }
        } else if (isChunkId(chunkId, "data")) {
            if (out.data == nullptr) {
                out.data = chunkData;
                out.dataSize = chunkSize;
            }
        }

        const size_t nextOffset = chunkDataOffset + chunkSize + (chunkSize & 1u);
        if (nextOffset <= offset) break;
        offset = nextOffset;
    }

    return out.numChannels > 0 && out.sampleRate > 0 && out.bitsPerSample > 0 &&
           out.data != nullptr && out.dataSize > 0;
}

bool decodeSample(const uint8_t* bytes,
                  uint16_t audioFormat,
                  uint16_t bitsPerSample,
                  float& out) noexcept {
    if (bytes == nullptr) return false;

    if (audioFormat == 1) {
        if (bitsPerSample == 8) {
            out = (static_cast<float>(bytes[0]) - 128.0f) / 128.0f;
            return true;
        }
        if (bitsPerSample == 16) {
            const uint16_t rawU = readU16LEUnchecked(bytes);
            const auto raw = static_cast<int16_t>(rawU);
            out = static_cast<float>(raw) / 32768.0f;
            return true;
        }
        if (bitsPerSample == 24) {
            int32_t raw = static_cast<int32_t>(bytes[0]) |
                          (static_cast<int32_t>(bytes[1]) << 8) |
                          (static_cast<int32_t>(bytes[2]) << 16);
            if ((raw & 0x00800000) != 0) {
                raw |= ~0x00ffffff;
            }
            out = static_cast<float>(raw) / 8388608.0f;
            return true;
        }
        if (bitsPerSample == 32) {
            const uint32_t rawU = readU32LEUnchecked(bytes);
            const auto raw = static_cast<int32_t>(rawU);
            out = static_cast<float>(static_cast<double>(raw) / 2147483648.0);
            return true;
        }
        return false;
    }

    if (audioFormat == 3) {
        if (bitsPerSample == 32) {
            float value = 0.0f;
            std::memcpy(&value, bytes, sizeof(value));
            out = clampSample(value);
            return true;
        }
        if (bitsPerSample == 64) {
            double value = 0.0;
            std::memcpy(&value, bytes, sizeof(value));
            out = clampSample(static_cast<float>(value));
            return true;
        }
        return false;
    }

    return false;
}

} // namespace

bool decodeWavMonoFloat(const std::vector<uint8_t>& bytes, WavPcmData& out) {
    out = {};

    WavInfo wav;
    if (!parseWav(bytes, wav)) {
        return false;
    }

    const size_t bytesPerSample = wav.bitsPerSample / 8;
    if (bytesPerSample == 0) {
        return false;
    }

    const size_t frameCount = wav.dataSize / (bytesPerSample * wav.numChannels);
    if (frameCount == 0) {
        return false;
    }

    out.sampleRate = static_cast<double>(wav.sampleRate);
    out.mono.resize(frameCount, 0.0f);

    for (size_t frame = 0; frame < frameCount; ++frame) {
        float mixed = 0.0f;
        for (uint16_t channel = 0; channel < wav.numChannels; ++channel) {
            const size_t sampleOffset =
                (frame * wav.numChannels + static_cast<size_t>(channel)) * bytesPerSample;
            if (sampleOffset + bytesPerSample > wav.dataSize) {
                return false;
            }
            float value = 0.0f;
            if (!decodeSample(wav.data + sampleOffset, wav.audioFormat, wav.bitsPerSample, value)) {
                return false;
            }
            mixed += value;
        }
        out.mono[frame] = clampSample(mixed / static_cast<float>(wav.numChannels));
    }

    return true;
}

} // namespace audioapp
