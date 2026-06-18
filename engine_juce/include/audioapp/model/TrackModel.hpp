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
};

struct Track {
    std::string id;
    std::string name;
    std::vector<DeviceSlot> devices;
    std::vector<MidiClip> midiClips;
    std::vector<SampleClip> sampleClips;
};

} // namespace audioapp
