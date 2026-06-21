#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cmath>

class MidiClipNotesTest : public juce::UnitTest {
public:
    MidiClipNotesTest() : juce::UnitTest("MidiClipNotes", "Project") {}

    void runTest() override
    {
        auto project = std::make_unique<audioapp::ProjectEngine>();
        project->createProject();

        const std::string trackId = project->addTrack("Keys");
        project->createMidiClip(trackId, 0.0, 4.0);

        const auto snap = project->snapshot();
        expect(!snap.tracks.empty(), "should have tracks");
        expect(!snap.tracks[0].midiClips.empty(), "track should have MIDI clips");

        const std::string clipId = snap.tracks[0].midiClips[0].id;

        beginTest("set MIDI clip notes");
        {
            std::vector<audioapp::MidiNoteState> notes;
            notes.push_back(audioapp::MidiNoteState{60, 0.0, 1.0, 100.0f});
            notes.push_back(audioapp::MidiNoteState{64, 1.0, 1.0, 100.0f});

            expect(project->setMidiClipNotes(clipId, notes),
                   "should set MIDI clip notes");

            const auto updated = project->snapshot();
            expect(updated.tracks[0].midiClips[0].notes.size() == 2,
                   "clip should have 2 notes");
        }

        beginTest("parse MIDI notes from args");
        {
            const std::string args =
                R"({"clipId":"clip-1","notes":[{"pitch":72,"startBeat":2.0,"durationBeats":0.5,"velocity":100.0}]})";
            const auto parsed = audioapp::parseMidiNotesFromArgs(args);
            expect(parsed.size() == 1, "should parse one note");
            expectEquals(parsed[0].pitch, 72, "parsed note pitch should be 72");
        }

        beginTest("playback with added oscillator");
        {
            project->setPlaying(true);
            expect(project->selectTrack(trackId), "should select track");
            expect(!project->addDeviceToTrack(trackId, "simple_oscillator").empty(),
                   "should add oscillator");
            expectWithinAbsoluteError(project->activeOscillatorFrequencyHz(), 261.63f, 1.0f);
        }
    }
};

static MidiClipNotesTest midiClipNotesTest;