#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <limits>
#include <string>
#include <vector>

#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"

namespace audioapp::test {

/// Root-mean-square of a range within a float vector.
inline float rms(const std::vector<float>& samples, int start, int count) noexcept
{
    double acc = 0.0;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i)
        acc += static_cast<double>(samples[static_cast<size_t>(i)]) *
               static_cast<double>(samples[static_cast<size_t>(i)]);
    return end > start ? static_cast<float>(std::sqrt(acc / static_cast<double>(end - start))) : 0.0f;
}

/// Peak absolute value of a range within a float vector.
inline float peak(const std::vector<float>& samples, int start, int count) noexcept
{
    float p = 0.0f;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i)
        p = std::max(p, std::abs(samples[static_cast<size_t>(i)]));
    return p;
}

/// Peak absolute value of a raw float buffer (mono).
inline float peakAbs(const float* buffer, int count) noexcept
{
    float p = 0.0f;
    for (int i = 0; i < count; ++i)
        p = std::max(p, std::abs(buffer[i]));
    return p;
}

/// Peak absolute value of paired left/right float buffers (stereo).
inline float peakAbsStereo(const float* left, const float* right, int count) noexcept
{
    float p = 0.0f;
    for (int i = 0; i < count; ++i)
        p = std::max(p, std::max(std::abs(left[i]), std::abs(right[i])));
    return p;
}

/// High-frequency energy via first-difference within a range.
inline float highFrequencyEnergy(const std::vector<float>& samples, int start, int count) noexcept
{
    float energy = 0.0f;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start + 1; i < end; ++i) {
        const float diff = samples[static_cast<size_t>(i)] - samples[static_cast<size_t>(i - 1)];
        energy += diff * diff;
    }
    return energy;
}

/// Full RMS of the entire vector.
inline float fullRms(const std::vector<float>& samples) noexcept
{
    if (samples.empty()) return 0.0f;
    return rms(samples, 0, static_cast<int>(samples.size()));
}

/// Ratio of max RMS to min RMS across evenly-spaced windows.
/// Returns 1.0 if the signal has no measurable variation.
inline float rmsVariationRatio(const std::vector<float>& block, int numWindows) noexcept
{
    if (block.empty() || numWindows < 2) return 1.0f;
    const int windowFrames = static_cast<int>(block.size()) / numWindows;
    float maxRms = 0.0f;
    float minRms = std::numeric_limits<float>::infinity();
    for (int w = 0; w < numWindows; ++w) {
        const int start = w * windowFrames;
        const float r = rms(block, start, windowFrames);
        if (r <= 0.0f) continue;
        maxRms = std::max(maxRms, r);
        minRms = std::min(minRms, r);
    }
    return maxRms > 0.0f && minRms < std::numeric_limits<float>::infinity()
        ? maxRms / minRms : 1.0f;
}

/// Per-window RMS values for analysis.
inline std::vector<float> windowRMS(const std::vector<float>& samples, int numWindows) noexcept
{
    std::vector<float> result(static_cast<size_t>(numWindows), 0.0f);
    const int windowFrames = static_cast<int>(samples.size()) / numWindows;
    for (int w = 0; w < numWindows; ++w)
        result[static_cast<size_t>(w)] = rms(samples, w * windowFrames, windowFrames);
    return result;
}

/// Double-difference high-frequency energy (emphasises HF more aggressively).
inline float highBandEnergy(const std::vector<float>& samples, int start, int count) noexcept
{
    if (count < 4) return 0.0f;
    float energy = 0.0f;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start + 2; i < end; ++i) {
        const float a = samples[static_cast<size_t>(i)]     - samples[static_cast<size_t>(i - 1)];
        const float b = samples[static_cast<size_t>(i - 1)] - samples[static_cast<size_t>(i - 2)];
        const float hf = a - b;
        energy += hf * hf;
    }
    return energy;
}

/// Average HF energy per window.
inline float averageHFPerWindow(const std::vector<float>& block, int numWindows) noexcept
{
    const int windowFrames = static_cast<int>(block.size()) / numWindows;
    double total = 0.0;
    for (int w = 0; w < numWindows; ++w) {
        const int start = w * windowFrames;
        total += static_cast<double>(highFrequencyEnergy(block, start, windowFrames));
    }
    return static_cast<float>(total / static_cast<double>(numWindows));
}

/// Check if any sample in the buffer has non-zero value.
inline bool hasNonZeroSample(const std::vector<float>& buffer, float threshold = 1.0e-5f) noexcept
{
    for (float sample : buffer)
        if (std::fabs(sample) > threshold)
            return true;
    return false;
}

/// Check whether a device ID appears in a JSON snapshot string.
inline bool snapshotContainsDevice(const std::string& json, const std::string& deviceId) noexcept
{
    return json.find('"' + deviceId + '"') != std::string::npos;
}

/// Detect whether filter modulation caused HF energy variation across windows.
inline bool filterSweepDetected(const std::vector<float>& block, int windows, float minRatio = 2.0f) noexcept
{
    const int windowFrames = static_cast<int>(block.size()) / windows;
    if (windowFrames <= 1) return false;
    float brightest = 0.0f;
    float darkest = std::numeric_limits<float>::infinity();
    for (int w = 0; w < windows; ++w) {
        const int start = w * windowFrames;
        const float hf = highFrequencyEnergy(block, start, windowFrames);
        if (hf <= 0.0f) return false;
        brightest = std::max(brightest, hf);
        darkest = std::min(darkest, hf);
    }
    if (darkest <= 0.0f) return false;
    return brightest / darkest >= minRatio;
}

/// Parse project JSON from an EngineHost and return ProjectFileData.
inline audioapp::ProjectFileData readProjectData(const audioapp::EngineHost& host) noexcept
{
    audioapp::ProjectFileData data;
    auto registry = audioapp::DeviceRegistry::createBuiltIn();
    auto modTypes = audioapp::createDefaultModulatorTypes();
    if (!audioapp::parseProjectFileJson(host.getProjectFileJson(), data, registry, modTypes))
        return {};
    return data;
}

/// Parse project JSON string against a fresh DeviceRegistry and return ProjectFileData.
inline audioapp::ProjectFileData parseProjectJson(const std::string& json) noexcept
{
    audioapp::ProjectFileData data;
    auto registry = audioapp::DeviceRegistry::createBuiltIn();
    auto modTypes = audioapp::createDefaultModulatorTypes();
    if (!audioapp::parseProjectFileJson(json, data, registry, modTypes))
        return {};
    return data;
}

/// Parse project JSON into existing ProjectFileData with a fresh registry.
inline bool parseProjectJsonInto(const std::string& json, audioapp::ProjectFileData& data) noexcept
{
    auto registry = audioapp::DeviceRegistry::createBuiltIn();
    auto modTypes = audioapp::createDefaultModulatorTypes();
    return audioapp::parseProjectFileJson(json, data, registry, modTypes);
}

// =======================================================================
// Golden fingerprint helpers
// =======================================================================
//
// The engine render is NOT sample-exact across runs due to unordered
// iteration and pointer-based ordering.  Instead of comparing raw samples,
// we store **aggregate metrics** (peak, RMS, RMS-variation-ratio) that are
// empirically stable across runs.
//
// Regeneration: cmake -DAUDIOAPP_REGENERATE_GOLDEN=ON

/// Golden fingerprint with robust aggregate metrics.
struct AudioFingerprint {
    uint64_t frameCount = 0;
    float peak = 0.0f;
    float rms = 0.0f;
    float rmsVariationRatio = 0.0f; ///< max/min window-RMS ratio
};

/// Path to the golden file directory.
inline std::string goldenDir() noexcept
{
#ifdef AUDIOAPP_GOLDEN_DIR
    return AUDIOAPP_GOLDEN_DIR;
#else
    return "tests/golden";
#endif
}

/// Full path for a golden file name.
inline std::string goldenPath(const char* name) noexcept
{
    return goldenDir() + "/" + name;
}

/// Strip directory prefix from a golden file name (for display).
inline std::string stripGoldenPrefix(const char* name) noexcept
{
    const std::string s(name);
    auto pos = s.rfind('/');
    return (pos != std::string::npos) ? s.substr(pos + 1) : s;
}

/// Compute an AudioFingerprint from a render buffer.
inline AudioFingerprint computeFingerprint(const std::vector<float>& samples) noexcept
{
    AudioFingerprint fp;
    fp.frameCount = static_cast<uint64_t>(samples.size());
    if (samples.empty()) return fp;
    fp.peak = peakAbs(samples.data(), static_cast<int>(samples.size()));
    fp.rms = fullRms(samples);
    fp.rmsVariationRatio = rmsVariationRatio(samples, 8);
    return fp;
}

/// Write a fingerprint golden file.
inline bool writeGolden(const char* name, const AudioFingerprint& fp) noexcept
{
    const std::string path = goldenPath(name);
    std::FILE* f = std::fopen(path.c_str(), "wb");
    if (!f) { std::fprintf(stderr, "  GOLDEN WRITE FAILED: %s\n", path.c_str()); return false; }
    bool ok = (std::fwrite(&fp, sizeof(fp), 1, f) == 1);
    std::fclose(f);
    return ok;
}

/// Compare two fingerprints.
/// Uses loose tolerances (2x relative) for non-deterministic engine renders.
inline bool matchesGoldenFingerprint(const char* name,
                                     const AudioFingerprint& got) noexcept
{
    const std::string path = goldenPath(name);
    std::FILE* f = std::fopen(path.c_str(), "rb");
    if (!f) { std::fprintf(stderr, "  GOLDEN MISSING: %s\n", path.c_str()); return false; }

    AudioFingerprint expected;
    if (std::fread(&expected, sizeof(expected), 1, f) != 1) {
        std::fclose(f); std::fprintf(stderr, "  GOLDEN CORRUPT: %s\n", path.c_str()); return false;
    }
    std::fclose(f);

    if (expected.frameCount != got.frameCount) {
        std::fprintf(stderr, "  GOLDEN SIZE: %s expected=%llu actual=%llu\n",
                     path.c_str(),
                     static_cast<unsigned long long>(expected.frameCount),
                     static_cast<unsigned long long>(got.frameCount));
        return false;
    }

    const auto sn = stripGoldenPrefix(name);
    bool ok = true;

    // Peak: 2x relative tolerance
    const float peakRat = (expected.peak > 1.0e-8f) ? std::abs(expected.peak - got.peak) / expected.peak : 0.0f;
    if (peakRat > 2.0f) {
        std::fprintf(stderr, "  GOLDEN PEAK: %s expected=%.6f got=%.6f ratio=%.3f\n", sn.c_str(), expected.peak, got.peak, peakRat);
        ok = false;
    }

    // RMS: 2x relative tolerance
    const float rmsRat = (expected.rms > 1.0e-8f) ? std::abs(expected.rms - got.rms) / expected.rms : 0.0f;
    if (rmsRat > 2.0f) {
        std::fprintf(stderr, "  GOLDEN RMS: %s expected=%.6f got=%.6f ratio=%.3f\n", sn.c_str(), expected.rms, got.rms, rmsRat);
        ok = false;
    }

    // RMS-variation-ratio: 2x relative tolerance
    const float varRat = (expected.rmsVariationRatio > 1.0e-8f) ? std::abs(expected.rmsVariationRatio - got.rmsVariationRatio) / expected.rmsVariationRatio : 0.0f;
    if (varRat > 2.0f) {
        std::fprintf(stderr, "  GOLDEN RMS_VAR_RATIO: %s expected=%.4f got=%.4f ratio=%.3f\n",
                     sn.c_str(), expected.rmsVariationRatio, got.rmsVariationRatio, varRat);
        ok = false;
    }

    return ok;
}

/// Render from the host, compute fingerprint, and compare against golden.
/// If AUDIOAPP_REGENERATE_GOLDEN is defined, writes the golden file instead.
inline bool checkRenderGolden(const char* name,
                              audioapp::EngineHost& host,
                              double lengthBeats,
                              double sampleRate,
                              float /*unused*/ = 0.0f) noexcept
{
    host.setPlaying(true);
    const std::vector<float> block = host.renderOffline(lengthBeats, sampleRate);

    if (block.size() < 48000) {
        std::fprintf(stderr, "  RENDER TOO SHORT: %s got=%zu\n", name, block.size());
        return false;
    }

    const AudioFingerprint fp = computeFingerprint(block);

#ifdef AUDIOAPP_REGENERATE_GOLDEN
    if (writeGolden(name, fp)) {
        std::fprintf(stderr, "  GOLDEN REGENERATED: %s (%llu samples, peak=%.4f rms=%.4f varRatio=%.4f)\n",
                     name,
                     static_cast<unsigned long long>(fp.frameCount),
                     fp.peak, fp.rms, fp.rmsVariationRatio);
        return true;
    }
    std::fprintf(stderr, "  GOLDEN WRITE FAILED: %s\n", name);
    return false;
#else
    return matchesGoldenFingerprint(name, fp);
#endif
}

} // namespace audioapp::test