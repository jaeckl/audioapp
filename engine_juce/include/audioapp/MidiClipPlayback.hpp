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

struct MidiClipState {
    std::string id;
    double startBeat = 0.0;
    double lengthBeats = 4.0;
    std::vector<MidiNoteState> notes;
};

int activeMidiPitchAtBeat(double playheadBeat, const MidiClipState& clip) noexcept;

double advancePlayheadBeats(double playheadBeat,
                            int numFrames,
                            double sampleRate,
                            int bpm) noexcept;

} // namespace audioapp
