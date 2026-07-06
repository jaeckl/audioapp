#pragma once

#include <string>
#include <vector>

namespace audioapp {

struct MidiNoteState {
    int pitch = 60;
    double startBeat = 0.0;
    double durationBeats = 1.0;
    float velocity = 100.0f;
};

struct MidiClipTakeState {
    std::string id;
    std::string name;
    double startBeatOffset = 0.0;
    double lengthBeats = 4.0;
    std::vector<MidiNoteState> notes;
};

struct MidiClipTakeRegionState {
    double startBeat = 0.0;
    double endBeat = 4.0;
    std::string takeId;
    double sourceStart = 0.0;
    bool holdPrevious = true;
};

struct MidiClipState {
    std::string id;
    double startBeat = 0.0;
    double lengthBeats = 4.0;
    double naturalLengthBeats = 4.0;
    bool loopContent = false;
    int editorScaleRoot = 0;
    std::string editorScaleId = "major";
    bool editorScaleHighlight = false;
    bool editorScaleSnap = false;
    std::string editorChordQuality = "off";
    std::vector<MidiNoteState> notes;
    std::vector<MidiClipTakeState> takes;
    std::vector<MidiClipTakeRegionState> activeTakeRegions;
    bool compFlattened = false;
};

int activeMidiPitchAtBeat(double playheadBeat, const MidiClipState& clip) noexcept;

double advancePlayheadBeats(double playheadBeat,
                            int numFrames,
                            double sampleRate,
                            int bpm) noexcept;

} // namespace audioapp
