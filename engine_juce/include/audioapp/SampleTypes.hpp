#pragma once

#include <string>
#include <vector>

namespace audioapp {

struct SampleClipState {
    std::string id;
    std::string sampleId;
    std::string sampleName;
    double startBeat = 0.0;
    double lengthBeats = 4.0;
    /// Length of the waveform's source region in beats. Set at clip creation;
    /// never modified by resize. See [SampleClip::naturalLengthBeats].
    double naturalLengthBeats = 4.0;
    bool loopContent = false;
    float sourceStart = 0.0f;
    float sourceEnd = 1.0f;
    float gain = 1.0f;
    float fadeIn = 0.0f;
    float fadeOut = 0.0f;
    float fadeInCurve = 0.5f;
    float fadeOutCurve = 0.5f;
    bool reversed = false;
    bool warpRepitch = false;
    std::vector<float> sliceMarkers;
    std::vector<float> waveformPeaks;
};

struct SampleLibraryEntryState {
    std::string id;
    std::string name;
    std::string source;
    double durationBeats = 4.0;
    std::vector<float> waveformPeaks;
};

} // namespace audioapp
