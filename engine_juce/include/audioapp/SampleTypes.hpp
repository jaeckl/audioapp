#pragma once

#include <string>
#include <vector>

namespace audioapp {

struct SampleClipTakeState {
    std::string id;
    std::string sampleId;
    std::string name;
    double startBeatOffset = 0.0;
    double lengthBeats = 4.0;
};

struct SampleClipTakeRegionState {
    double startBeat = 0.0;
    double endBeat = 4.0;
    std::string takeId;
    double sourceStart = 0.0;
};

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
    std::vector<SampleClipTakeState> takes;
    std::vector<SampleClipTakeRegionState> activeTakeRegions;
};

struct SampleLibraryEntryState {
    std::string id;
    std::string name;
    std::string source;
    double durationBeats = 4.0;
    std::vector<float> waveformPeaks;
};

} // namespace audioapp
