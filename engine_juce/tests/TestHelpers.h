#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>
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
    if (!audioapp::parseProjectFileJson(host.getProjectFileJson(), data, registry))
        return {};
    return data;
}

/// Parse project JSON string against a fresh DeviceRegistry and return ProjectFileData.
inline audioapp::ProjectFileData parseProjectJson(const std::string& json) noexcept
{
    audioapp::ProjectFileData data;
    auto registry = audioapp::DeviceRegistry::createBuiltIn();
    if (!audioapp::parseProjectFileJson(json, data, registry))
        return {};
    return data;
}

/// Parse project JSON into existing ProjectFileData with a fresh registry.
inline bool parseProjectJsonInto(const std::string& json, audioapp::ProjectFileData& data) noexcept
{
    auto registry = audioapp::DeviceRegistry::createBuiltIn();
    return audioapp::parseProjectFileJson(json, data, registry);
}

} // namespace audioapp::test
