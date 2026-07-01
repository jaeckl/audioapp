#include "audioapp/playback/Clip.hpp"

#include <array>
#include <cstdlib>

namespace {

struct Note {
    int pitch;
    double startBeat;
    double durationBeats;
};

void require(bool condition) {
    if (!condition) std::abort();
}

} // namespace

int main() {
    using audioapp::playback::MidiClip;
    using audioapp::playback::MidiData;

    const std::array firstNotes{Note{60, 0.0, 1.0}};
    const std::array secondNotes{Note{67, 0.0, 1.0}};
    const MidiClip first{0.0, 4.0, 4.0, false, MidiData<Note>{firstNotes}};
    const MidiClip second{4.0, 4.0, 4.0, false, MidiData<Note>{secondNotes}};
    require(first.activePitchAt(0.5) == 60);
    require(first.activePitchAt(4.0) == -1); // half-open clip end
    require(second.activePitchAt(4.0) == 67);

    const std::array chordNotes{
        Note{48, 0.0, 0.5},
        Note{55, 10.0, 0.5},
        Note{60, 14.0, 1.0},
        Note{64, 14.0, 1.0},
        Note{67, 14.0, 1.0},
    };
    const MidiClip looped{0.0, 32.0, 16.0, true, MidiData<Note>{chordNotes}};
    require(looped.activePitchAt(10.25) == 55);
    require(looped.activePitchAt(14.25) == 67);
    require(looped.activePitchAt(16.25) == 48);
    require(looped.activePitchAt(30.25) == 67);

    const std::array<float, 4> samples{0.0f, 1.0f, 0.0f, -1.0f};
    const audioapp::playback::AudioClip audio{2.0, 8.0, 4.0, true};
    bool active = false;
    require(audio.progressAt(6.0, active) == 0.0 && active);

    return EXIT_SUCCESS;
}
