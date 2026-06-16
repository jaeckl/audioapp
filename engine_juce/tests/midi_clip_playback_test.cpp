#include "audioapp/MidiClipPlayback.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    audioapp::MidiClipState clip;
    clip.id = "clip-1";
    clip.startBeat = 0.0;
    clip.lengthBeats = 4.0;
    clip.notes.push_back(audioapp::MidiNoteState{60, 0.0, 1.0, 100.0f});

    if (audioapp::activeMidiPitchAtBeat(0.0, clip) != 60) {
        return EXIT_FAILURE;
    }
    if (audioapp::activeMidiPitchAtBeat(0.5, clip) != 60) {
        return EXIT_FAILURE;
    }
    if (audioapp::activeMidiPitchAtBeat(1.0, clip) != -1) {
        return EXIT_FAILURE;
    }
    if (audioapp::activeMidiPitchAtBeat(4.5, clip) != 60) {
        return EXIT_FAILURE;
    }
    if (audioapp::activeMidiPitchAtBeat(8.0, clip) != -1) {
        return EXIT_FAILURE;
    }

    const double advanced = audioapp::advancePlayheadBeats(0.0, 48000, 48000.0, 120);
    if (std::abs(advanced - 1.0) > 0.001) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
