#pragma once

#include "audioapp/devices/DeviceSlot.hpp"

#include <string>
#include <vector>

namespace audioapp {

struct MidiNote {
    int pitch = 60;
    double startBeat = 0.0;
    double durationBeats = 1.0;
    float velocity = 100.0f;
};

struct MidiClip {
    std::string id;
    double startBeat = 0.0;
    double lengthBeats = 4.0;
    std::vector<MidiNote> notes;
};

struct SampleClip {
    std::string id;
    std::string sampleId;
    double startBeat = 0.0;
    double lengthBeats = 4.0;
    /// Length of the waveform's source region in beats. Set at clip creation
    /// to the source sample's natural duration; never modified by resize.
    /// The arranger view uses this to render the waveform at its natural
    /// density and either clip it (when shortening) or leave trailing empty
    /// space (when lengthening).
    double naturalLengthBeats = 4.0;
};

struct AutomationPoint {
    double beat = 0.0;
    float value = 0.0f;
};

struct AutomationClip {
    std::string id;
    /// Track the clip is rendered on in the arrangement view. Set at create
    /// time and never changes — independent of `deviceId` (the device may
    /// live on any track, including this one).
    std::string homeTrackId;
    double startBeat = 0.0;
    double lengthBeats = 4.0;
    std::string deviceId;
    std::string paramId;
    std::vector<AutomationPoint> points;
};

struct Track {
    std::string id;
    std::string name;
    std::string iconKey;
    bool isGroup = false;
    std::string parentGroupId;
    std::vector<DeviceSlot> devices;
    std::vector<MidiClip> midiClips;
    std::vector<SampleClip> sampleClips;
    // Note: automation clips were moved to AutomationClipStore (project-global)
    // so a single clip can target any device on any track. They are no
    // longer nested per-track.
};

} // namespace audioapp
