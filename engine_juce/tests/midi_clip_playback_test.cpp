#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/MidiClipPlayback.hpp"

#include <cmath>

class MidiClipPlaybackTest : public juce::UnitTest {
public:
    MidiClipPlaybackTest() : juce::UnitTest("MidiClipPlayback", "Project") {}

    void runTest() override
    {
        audioapp::MidiClipState clip;
        clip.id = "clip-1";
        clip.startBeat = 0.0;
        clip.lengthBeats = 4.0;
        clip.notes.push_back(audioapp::MidiNoteState{60, 0.0, 1.0, 100.0f});

        beginTest("activeMidiPitchAtBeat");
        {
            expectEquals(audioapp::activeMidiPitchAtBeat(0.0, clip), 60,
                         "pitch at beat 0.0 should be 60");
            expectEquals(audioapp::activeMidiPitchAtBeat(0.5, clip), 60,
                         "pitch at beat 0.5 should be 60");
            expectEquals(audioapp::activeMidiPitchAtBeat(1.0, clip), -1,
                         "pitch at beat 1.0 should be -1 (note ended)");
            expectEquals(audioapp::activeMidiPitchAtBeat(4.5, clip), 60,
                         "pitch at beat 4.5 should wrap and return 60");
            expectEquals(audioapp::activeMidiPitchAtBeat(8.0, clip), -1,
                         "pitch at beat 8.0 should be -1 (beyond loop)");
        }

        beginTest("advancePlayheadBeats");
        {
            const double advanced = audioapp::advancePlayheadBeats(0.0, 48000, 48000.0, 120);
            expectWithinAbsoluteError(advanced, 1.0, 0.001);
        }
    }
};

static MidiClipPlaybackTest midiClipPlaybackTest;