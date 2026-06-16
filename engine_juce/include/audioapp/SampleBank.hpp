#pragma once

#include "audioapp/SampleTypes.hpp"

#include <mutex>
#include <optional>
#include <string>
#include <vector>

namespace audioapp {

class SampleBank {
public:
    static constexpr int kPeakBinCount = 48;

    struct Sample {
        std::string id;
        std::string name;
        std::string source;
        std::vector<float> pcm;
        double sampleRate = 48000.0;
        std::vector<float> peaks;
    };

    void registerBundledDefaults();
    bool loadFromWavBytes(const std::string& id,
                          const std::string& name,
                          const std::string& source,
                          const std::vector<uint8_t>& wavBytes,
                          int bpm);

    const Sample* findSample(const std::string& id) const;
    std::vector<Sample> listSamples() const;

    double beatsForSample(const std::string& id, int bpm) const;

    void clearImported();
    void restoreMetadata(const std::vector<SampleLibraryEntryState>& entries, int bpm);

    static std::vector<float> computePeaks(const float* pcm, int frameCount, int binCount);

private:
    mutable std::mutex mutex_;
    std::vector<Sample> samples_;

    bool upsertSample(Sample sample);
    static Sample makeBundledKick();
    static Sample makeBundledSnare();
    static Sample makeBundledHat();
    static Sample makeBundledClap();
};

} // namespace audioapp
