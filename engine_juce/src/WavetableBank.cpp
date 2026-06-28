#include "audioapp/WavetableBank.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <limits>
#include <string>
#include <vector>

#ifdef __ANDROID__
#include <android/log.h>
#define WT_LOG(...) __android_log_print(ANDROID_LOG_INFO, "audioapp_engine", __VA_ARGS__)
#else
#define WT_LOG(...) ((void)0)
#endif

namespace audioapp {

namespace {

constexpr int kSerumFrameLength = 2048;
constexpr int kMaxSerumFrames = 256;

struct WavInfo {
    uint16_t audioFormat = 0;
    uint16_t numChannels = 0;
    uint32_t sampleRate = 0;
    uint16_t bitsPerSample = 0;
    const uint8_t* data = nullptr;
    size_t dataSize = 0;
    const uint8_t* clm = nullptr;
    size_t clmSize = 0;
};

struct WavetableShape {
    int frameLength = 0;
    int frameCount = 0;
    const char* source = "unknown";
};

bool isChunkId(const uint8_t* id, const char (&text)[5]) noexcept {
    return id != nullptr && std::memcmp(id, text, 4) == 0;
}

bool readU16LE(const uint8_t* bytes, uint16_t& out) noexcept {
    if (bytes == nullptr) return false;
    out = static_cast<uint16_t>(bytes[0]) |
          static_cast<uint16_t>(static_cast<uint16_t>(bytes[1]) << 8);
    return true;
}

bool readU32LE(const uint8_t* bytes, uint32_t& out) noexcept {
    if (bytes == nullptr) return false;
    out = static_cast<uint32_t>(bytes[0]) |
          (static_cast<uint32_t>(bytes[1]) << 8) |
          (static_cast<uint32_t>(bytes[2]) << 16) |
          (static_cast<uint32_t>(bytes[3]) << 24);
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

bool isPowerOfTwo(int value) noexcept {
    return value > 0 && (value & (value - 1)) == 0;
}

bool validShape(int frameLength, int sampleCount, int maxFrames = kMaxSerumFrames) noexcept {
    if (frameLength <= 0 || sampleCount <= 0 || sampleCount % frameLength != 0) {
        return false;
    }
    const int frameCount = sampleCount / frameLength;
    return frameCount >= 1 && frameCount <= maxFrames;
}

bool parseWav(const uint8_t* data, size_t dataSize, WavInfo& out) noexcept {
    out = {};
    if (data == nullptr || dataSize < 12) return false;
    if (!isChunkId(data, "RIFF") || !isChunkId(data + 8, "WAVE")) return false;

    size_t offset = 12;
    while (offset + 8 <= dataSize) {
        const uint8_t* chunkId = data + offset;
        uint32_t chunkSize32 = 0;
        if (!readU32LE(data + offset + 4, chunkSize32)) return false;
        const size_t chunkSize = static_cast<size_t>(chunkSize32);
        const size_t chunkDataOffset = offset + 8;
        if (chunkDataOffset > dataSize || chunkSize > dataSize - chunkDataOffset) {
            break;
        }

        const uint8_t* chunkData = data + chunkDataOffset;
        if (isChunkId(chunkId, "fmt ") && chunkSize >= 16) {
            readU16LE(chunkData, out.audioFormat);
            readU16LE(chunkData + 2, out.numChannels);
            readU32LE(chunkData + 4, out.sampleRate);
            readU16LE(chunkData + 14, out.bitsPerSample);

            // WAVE_FORMAT_EXTENSIBLE: real sub-format is stored in the GUID.
            // 00000001-0000-0010-8000-00aa00389b71 = PCM
            // 00000003-0000-0010-8000-00aa00389b71 = IEEE float
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
        } else if (isChunkId(chunkId, "clm ")) {
            out.clm = chunkData;
            out.clmSize = chunkSize;
        }

        const size_t nextOffset = chunkDataOffset + chunkSize + (chunkSize & 1u);
        if (nextOffset <= offset) break;
        offset = nextOffset;
    }

    return out.numChannels > 0 && out.sampleRate > 0 && out.bitsPerSample > 0 &&
           out.data != nullptr && out.dataSize > 0;
}

float clampSample(float value) noexcept {
    if (!std::isfinite(value)) return 0.0f;
    return std::clamp(value, -1.0f, 1.0f);
}

bool decodeSample(const uint8_t* bytes,
                  uint16_t audioFormat,
                  uint16_t bitsPerSample,
                  float& out) noexcept {
    if (bytes == nullptr) return false;

    if (audioFormat == 1) { // PCM integer
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

    if (audioFormat == 3) { // IEEE float
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

int parseFirstIntAfterMarker(const uint8_t* bytes, size_t size, const char* marker) noexcept {
    if (bytes == nullptr || size == 0 || marker == nullptr) return 0;

    size_t start = 0;
    const size_t markerLen = std::strlen(marker);
    if (markerLen > 0 && size >= markerLen) {
        for (size_t i = 0; i + markerLen <= size; ++i) {
            if (std::memcmp(bytes + i, marker, markerLen) == 0) {
                start = i + markerLen;
                break;
            }
        }
    }

    for (size_t i = start; i < size; ++i) {
        if (!std::isdigit(static_cast<unsigned char>(bytes[i]))) continue;
        int value = 0;
        while (i < size && std::isdigit(static_cast<unsigned char>(bytes[i]))) {
            value = value * 10 + static_cast<int>(bytes[i] - '0');
            if (value > 65536) return 0;
            ++i;
        }
        return value;
    }
    return 0;
}

int serumFrameLengthFromClm(const uint8_t* clm, size_t clmSize) noexcept {
    if (clm == nullptr || clmSize == 0) return 0;

    // Serum-created files commonly contain text like:
    // <!>2048 01000000 wavetable (www.xferrecords.com)
    int value = parseFirstIntAfterMarker(clm, clmSize, "<!>");
    if (value > 0) return value;
    return parseFirstIntAfterMarker(clm, clmSize, "");
}

std::string basenameWithoutExtension(const std::string& name) {
    const size_t slash = name.find_last_of("/\\");
    const size_t begin = slash == std::string::npos ? 0 : slash + 1;
    const size_t dot = name.find_last_of('.');
    const size_t end = dot == std::string::npos || dot < begin ? name.size() : dot;
    return name.substr(begin, end - begin);
}

bool parseExplicitCountLengthFromName(const std::string& name,
                                      int sampleCount,
                                      WavetableShape& out) {
    const std::string base = basenameWithoutExtension(name);
    for (size_t x = 1; x + 1 < base.size(); ++x) {
        if (base[x] != 'x' && base[x] != 'X') continue;
        if (!std::isdigit(static_cast<unsigned char>(base[x - 1])) ||
            !std::isdigit(static_cast<unsigned char>(base[x + 1]))) {
            continue;
        }

        size_t left = x;
        while (left > 0 && std::isdigit(static_cast<unsigned char>(base[left - 1]))) {
            --left;
        }
        size_t right = x + 1;
        while (right < base.size() && std::isdigit(static_cast<unsigned char>(base[right]))) {
            ++right;
        }

        const int frameCount = std::stoi(base.substr(left, x - left));
        const int frameLength = std::stoi(base.substr(x + 1, right - (x + 1)));
        if (frameCount > 0 && frameLength > 0 && frameCount * frameLength == sampleCount &&
            frameCount <= kMaxSerumFrames) {
            out = {frameLength, frameCount, "filename-count-x-length"};
            return true;
        }
    }
    return false;
}

bool parseTrailingFrameCountFromName(const std::string& name,
                                     int sampleCount,
                                     WavetableShape& out) {
    const std::string base = basenameWithoutExtension(name);
    if (base.empty() || !std::isdigit(static_cast<unsigned char>(base.back()))) return false;

    size_t begin = base.size();
    while (begin > 0 && std::isdigit(static_cast<unsigned char>(base[begin - 1]))) {
        --begin;
    }
    if (begin == 0) return false;

    const char sep = base[begin - 1];
    if (sep != '_' && sep != '-') return false;

    const int frameCount = std::stoi(base.substr(begin));
    if (frameCount <= 0 || frameCount > kMaxSerumFrames || sampleCount % frameCount != 0) return false;

    const int frameLength = sampleCount / frameCount;
    if (frameLength < 32 || frameLength > kSerumFrameLength || !isPowerOfTwo(frameLength)) return false;

    out = {frameLength, frameCount, "filename-frame-count"};
    return true;
}

WavetableShape inferWavetableShape(const std::string& name,
                                   int sampleCount,
                                   const WavInfo& wav) noexcept {
    WavetableShape shape;

    const int clmFrameLength = serumFrameLengthFromClm(wav.clm, wav.clmSize);
    if (validShape(clmFrameLength, sampleCount)) {
        return {clmFrameLength, sampleCount / clmFrameLength, "clm"};
    }

    if (parseExplicitCountLengthFromName(name, sampleCount, shape)) {
        return shape;
    }

    // Supports small generated tables such as sine_64.wav = 64 frames.
    // This is intentionally restricted to power-of-two frame lengths <= 2048 so
    // random numbers in normal Serum filenames do not usually override Serum.
    if (parseTrailingFrameCountFromName(name, sampleCount, shape)) {
        return shape;
    }

    // Serum-style WAV convention: each frame is one 2048-sample cycle.
    if (validShape(kSerumFrameLength, sampleCount)) {
        return {kSerumFrameLength, sampleCount / kSerumFrameLength, "serum-2048"};
    }

    static constexpr int kFallbackFrameLengths[] = {1024, 512, 256, 128, 64, 32};
    for (const int frameLength : kFallbackFrameLengths) {
        if (validShape(frameLength, sampleCount)) {
            return {frameLength, sampleCount / frameLength, "fallback-power2"};
        }
    }

    return {sampleCount, 1, "single-frame"};
}

} // anonymous namespace

int WavetableBank::loadFromBytes(const std::string& name, const uint8_t* data, size_t dataSize) {
    WavInfo wav;
    if (!parseWav(data, dataSize, wav)) {
        WT_LOG("loadFromBytes[%s] invalid WAV", name.c_str());
        return -1;
    }

    const uint32_t bytesPerSample = static_cast<uint32_t>(wav.bitsPerSample / 8);
    if (bytesPerSample == 0 || wav.dataSize < bytesPerSample * static_cast<size_t>(wav.numChannels)) {
        return -1;
    }

    const size_t inputFrames = wav.dataSize / (static_cast<size_t>(bytesPerSample) * wav.numChannels);
    if (inputFrames == 0 || inputFrames > static_cast<size_t>(std::numeric_limits<int>::max())) {
        return -1;
    }

    std::vector<float> convertedPcm(inputFrames, 0.0f);
    for (size_t frame = 0; frame < inputFrames; ++frame) {
        float mixed = 0.0f;
        for (uint16_t channel = 0; channel < wav.numChannels; ++channel) {
            const size_t sampleOffset =
                (frame * wav.numChannels + static_cast<size_t>(channel)) * bytesPerSample;
            if (sampleOffset + bytesPerSample > wav.dataSize) {
                return -1;
            }
            float value = 0.0f;
            if (!decodeSample(wav.data + sampleOffset, wav.audioFormat, wav.bitsPerSample, value)) {
                WT_LOG("loadFromBytes[%s] unsupported WAV format audioFormat=%u bits=%u",
                       name.c_str(), wav.audioFormat, wav.bitsPerSample);
                return -1;
            }
            mixed += value;
        }
        convertedPcm[frame] = clampSample(mixed / static_cast<float>(wav.numChannels));
    }

    const auto shape = inferWavetableShape(name, static_cast<int>(inputFrames), wav);
    if (shape.frameLength <= 0 || shape.frameCount <= 0 ||
        shape.frameLength * shape.frameCount > static_cast<int>(convertedPcm.size())) {
        return -1;
    }

    convertedPcm.resize(static_cast<size_t>(shape.frameLength) * static_cast<size_t>(shape.frameCount));

    WT_LOG("loadFromBytes[%s] OK samples=%zu frameLength=%d frameCount=%d source=%s channels=%u bits=%u format=%u sampleRate=%u",
           name.c_str(), inputFrames, shape.frameLength, shape.frameCount, shape.source,
           wav.numChannels, wav.bitsPerSample, wav.audioFormat, wav.sampleRate);

    WavetableEntry entry;
    entry.name = name;
    entry.pcm = std::move(convertedPcm);
    entry.frameCount = shape.frameCount;
    entry.frameLength = shape.frameLength;
    entry.sampleRate = static_cast<float>(wav.sampleRate);

    entries_.push_back(std::move(entry));
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
