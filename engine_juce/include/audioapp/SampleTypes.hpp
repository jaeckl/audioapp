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
