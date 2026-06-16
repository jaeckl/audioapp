#include "audioapp/SampleBank.hpp"

#include "audioapp/SampleTypes.hpp"
#include "audioapp/WavLoader.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

constexpr double kPi = 3.14159265358979323846;

std::vector<float> renderTone(double frequencyHz,
                              double sampleRate,
                              double durationSec,
                              double decaySec,
                              float gain) {
    const int frames = static_cast<int>(std::ceil(durationSec * sampleRate));
    std::vector<float> pcm(static_cast<size_t>(frames), 0.0f);
    for (int i = 0; i < frames; ++i) {
        const double t = static_cast<double>(i) / sampleRate;
        const double envelope = std::exp(-t / decaySec);
        pcm[static_cast<size_t>(i)] =
            static_cast<float>(std::sin(2.0 * kPi * frequencyHz * t) * envelope * gain);
    }
    return pcm;
}

std::vector<float> renderNoiseBurst(double sampleRate, double durationSec, float gain) {
    const int frames = static_cast<int>(std::ceil(durationSec * sampleRate));
    std::vector<float> pcm(static_cast<size_t>(frames), 0.0f);
    for (int i = 0; i < frames; ++i) {
        const double t = static_cast<double>(i) / sampleRate;
        const double envelope = std::exp(-t / 0.04);
        const float noise = ((i * 1103515245 + 12345) & 0x7fffffff) / static_cast<float>(0x7fffffff) -
                            0.5f;
        pcm[static_cast<size_t>(i)] = static_cast<float>(noise * envelope * gain);
    }
    return pcm;
}

SampleBank::Sample makeSample(const char* id,
                              const char* name,
                              std::vector<float> pcm,
                              double sampleRate) {
    SampleBank::Sample sample;
    sample.id = id;
    sample.name = name;
    sample.source = "bundled";
    sample.pcm = std::move(pcm);
    sample.sampleRate = sampleRate;
    sample.peaks = SampleBank::computePeaks(sample.pcm.data(), static_cast<int>(sample.pcm.size()),
                                            SampleBank::kPeakBinCount);
    return sample;
}

} // namespace

SampleBank::Sample SampleBank::makeBundledKick() {
    constexpr double sr = 48000.0;
    const int frames = static_cast<int>(sr * 0.35);
    std::vector<float> pcm(static_cast<size_t>(frames), 0.0f);
    double phase = 0.0;
    double freq = 140.0;
    for (int i = 0; i < frames; ++i) {
        const double t = static_cast<double>(i) / sr;
        freq = 40.0 + (140.0 - 40.0) * std::exp(-t / 0.08);
        phase += 2.0 * kPi * freq / sr;
        const double envelope = std::exp(-t / 0.22);
        pcm[static_cast<size_t>(i)] = static_cast<float>(std::sin(phase) * envelope * 0.9);
    }
    return makeSample("sample_kick", "Kick", std::move(pcm), sr);
}

SampleBank::Sample SampleBank::makeBundledSnare() {
    constexpr double sr = 48000.0;
    auto tone = renderTone(180.0, sr, 0.12, 0.05, 0.35);
    auto noise = renderNoiseBurst(sr, 0.25, 0.55);
    const int frames = std::max(static_cast<int>(tone.size()), static_cast<int>(noise.size()));
    std::vector<float> pcm(static_cast<size_t>(frames), 0.0f);
    for (int i = 0; i < frames; ++i) {
        const float t = i < static_cast<int>(tone.size()) ? tone[static_cast<size_t>(i)] : 0.0f;
        const float n = i < static_cast<int>(noise.size()) ? noise[static_cast<size_t>(i)] : 0.0f;
        pcm[static_cast<size_t>(i)] = t + n;
    }
    return makeSample("sample_snare", "Snare", std::move(pcm), sr);
}

SampleBank::Sample SampleBank::makeBundledHat() {
    constexpr double sr = 48000.0;
    auto noise = renderNoiseBurst(sr, 0.08, 0.35);
    for (auto& sample : noise) {
        sample *= 0.6f;
    }
    return makeSample("sample_hat", "Hi-Hat", std::move(noise), sr);
}

SampleBank::Sample SampleBank::makeBundledClap() {
    constexpr double sr = 48000.0;
    std::vector<float> pcm;
    for (int burst = 0; burst < 3; ++burst) {
        const int offset = burst * static_cast<int>(0.012 * sr);
        auto noise = renderNoiseBurst(sr, 0.18, 0.45f);
        if (pcm.size() < static_cast<size_t>(offset + noise.size())) {
            pcm.resize(static_cast<size_t>(offset + noise.size()), 0.0f);
        }
        for (size_t i = 0; i < noise.size(); ++i) {
            pcm[static_cast<size_t>(offset) + i] += noise[i];
        }
    }
    return makeSample("sample_clap", "Clap", std::move(pcm), sr);
}

void SampleBank::registerBundledDefaults() {
    std::lock_guard<std::mutex> lock(mutex_);
    samples_.erase(std::remove_if(samples_.begin(),
                                  samples_.end(),
                                  [](const Sample& sample) { return sample.source == "bundled"; }),
                   samples_.end());
    upsertSample(makeBundledKick());
    upsertSample(makeBundledSnare());
    upsertSample(makeBundledHat());
    upsertSample(makeBundledClap());
}

bool SampleBank::upsertSample(Sample sample) {
    for (auto& existing : samples_) {
        if (existing.id == sample.id) {
            existing = std::move(sample);
            return true;
        }
    }
    samples_.push_back(std::move(sample));
    return true;
}

bool SampleBank::loadFromWavBytes(const std::string& id,
                                  const std::string& name,
                                  const std::string& source,
                                  const std::vector<uint8_t>& wavBytes,
                                  int /*bpm*/) {
    WavPcmData decoded;
    if (!decodeWavMonoFloat(wavBytes, decoded) || decoded.mono.empty()) {
        return false;
    }

    Sample sample;
    sample.id = id;
    sample.name = name;
    sample.source = source;
    sample.pcm = std::move(decoded.mono);
    sample.sampleRate = decoded.sampleRate;
    sample.peaks = computePeaks(sample.pcm.data(), static_cast<int>(sample.pcm.size()), kPeakBinCount);

    std::lock_guard<std::mutex> lock(mutex_);
    return upsertSample(std::move(sample));
}

const SampleBank::Sample* SampleBank::findSample(const std::string& id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    for (const auto& sample : samples_) {
        if (sample.id == id) {
            return &sample;
        }
    }
    return nullptr;
}

std::vector<SampleBank::Sample> SampleBank::listSamples() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return samples_;
}

double SampleBank::beatsForSample(const std::string& id, int bpm) const {
    const auto* sample = findSample(id);
    if (sample == nullptr || sample->pcm.empty() || bpm <= 0) {
        return 4.0;
    }
    const double durationSec = static_cast<double>(sample->pcm.size()) / sample->sampleRate;
    return durationSec * static_cast<double>(bpm) / 60.0;
}

void SampleBank::clearImported() {
    std::lock_guard<std::mutex> lock(mutex_);
    samples_.erase(std::remove_if(samples_.begin(),
                                  samples_.end(),
                                  [](const Sample& sample) { return sample.source == "imported"; }),
                   samples_.end());
}

void SampleBank::restoreMetadata(const std::vector<SampleLibraryEntryState>& entries, int bpm) {
    std::lock_guard<std::mutex> lock(mutex_);
    for (const auto& entry : entries) {
        const bool exists = std::any_of(samples_.begin(), samples_.end(), [&](const Sample& sample) {
            return sample.id == entry.id;
        });
        if (exists) {
            continue;
        }
        Sample placeholder;
        placeholder.id = entry.id;
        placeholder.name = entry.name;
        placeholder.source = entry.source;
        placeholder.peaks = entry.waveformPeaks;
        placeholder.sampleRate = 48000.0;
        const double beats = entry.durationBeats > 0.0 ? entry.durationBeats : 4.0;
        const double durationSec = beats * 60.0 / static_cast<double>(std::max(bpm, 1));
        placeholder.pcm.resize(static_cast<size_t>(durationSec * placeholder.sampleRate), 0.0f);
        samples_.push_back(std::move(placeholder));
    }
}

std::vector<float> SampleBank::computePeaks(const float* pcm, int frameCount, int binCount) {
    if (frameCount <= 0 || binCount <= 0 || pcm == nullptr) {
        return {};
    }
    std::vector<float> peaks(static_cast<size_t>(binCount), 0.0f);
    const int framesPerBin = std::max(1, frameCount / binCount);
    for (int bin = 0; bin < binCount; ++bin) {
        const int start = bin * framesPerBin;
        const int end = std::min(frameCount, start + framesPerBin);
        float peak = 0.0f;
        for (int i = start; i < end; ++i) {
            peak = std::max(peak, std::abs(pcm[i]));
        }
        peaks[static_cast<size_t>(bin)] = peak;
    }
    const float maxPeak = *std::max_element(peaks.begin(), peaks.end());
    if (maxPeak > 0.0f) {
        for (auto& value : peaks) {
            value /= maxPeak;
        }
    }
    return peaks;
}

} // namespace audioapp
