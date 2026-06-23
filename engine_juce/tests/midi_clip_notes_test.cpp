#include <juce_core/juce_core.h>
#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cmath>

class MidiClipNotesTest : public juce::UnitTest {
public:
    MidiClipNotesTest() : juce::UnitTest("MidiClipNotes", "Project") {}

    void runTest() override
    {
        beginTest("parse MIDI notes from args");
        {
            const std::string args =
                R"({"clipId":"clip-1","notes":[{"pitch":72,"startBeat":2.0,"durationBeats":0.5,"velocity":100.0}]})";
            const auto parsed = audioapp::parseMidiNotesFromArgs(args);
            expect(parsed.size() == 1, "should parse one note");
            expectEquals(parsed[0].pitch, 72, "parsed note pitch should be 72");
        }

        beginTest("parse empty args returns empty");
        {
            const auto parsed = audioapp::parseMidiNotesFromArgs("{}");
            expect(parsed.empty(), "empty args should produce no notes");
        }

        beginTest("not playing returns last synced idle frequency");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            const std::string trackId = project->addTrack("Keys");
            project->addDeviceToTrack(trackId, "simple_oscillator");
            // Not playing → returns idle oscillator frequency (440 default)
            expectWithinAbsoluteError(
                project->activeOscillatorFrequencyHz(), 440.0f, 0.1f,
                "not-playing should return oscillator default 440");
        }

        beginTest("playing with oscillator and default seed C4 note");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            const std::string trackId = project->addTrack("Keys");
            project->createMidiClip(trackId, 0.0, 4.0);
            project->addDeviceToTrack(trackId, "simple_oscillator");
            project->setPlaying(true);
            // createMidiClip always adds a C4 seed note (pitch=60) at beat 0
            expectWithinAbsoluteError(
                project->activeOscillatorFrequencyHz(), 261.63f, 1.0f,
                "playing with seed C4 note should give 261.63 Hz");
        }

        beginTest("active frequency tracks MIDI note pitch");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            const std::string trackId = project->addTrack("Keys");
            const std::string clipId = project->createMidiClip(trackId, 0.0, 4.0);
            project->addDeviceToTrack(trackId, "simple_oscillator");

            // Replace seed C4 with A4 (pitch=69 → 440 Hz)
            std::vector<audioapp::MidiNoteState> notes;
            notes.push_back({69, 0.0, 4.0, 100.0f});
            project->setMidiClipNotes(clipId, notes);

            project->setPlaying(true);
            expectWithinAbsoluteError(
                project->activeOscillatorFrequencyHz(), 440.0f, 1.0f,
                "A4 (pitch=69) should be 440 Hz");
        }

        beginTest("active frequency without oscillator returns 0 when playing");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            project->addTrack("Keys");
            project->setPlaying(true);
            expectWithinAbsoluteError(
                project->activeOscillatorFrequencyHz(), 0.0f, 0.1f);
        }

        beginTest("clip notes round-trip through snapshot");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            const std::string trackId = project->addTrack("Keys");
            const std::string clipId = project->createMidiClip(trackId, 0.0, 4.0);

            // Replace default seed note with two custom notes
            std::vector<audioapp::MidiNoteState> notes;
            notes.push_back({60, 0.0, 1.0, 100.0f});
            notes.push_back({72, 2.0, 0.5, 80.0f});

            expect(project->setMidiClipNotes(clipId, notes),
                   "should set MIDI clip notes");

            const auto snap = project->snapshot();
            expect(!snap.tracks.empty(), "snapshot should have tracks");
            if (snap.tracks.empty()) return;
            expect(!snap.tracks[0].midiClips.empty(), "snapshot should have clips");
            if (snap.tracks[0].midiClips.empty()) return;

            const auto& clip = snap.tracks[0].midiClips[0];
            expect(clip.notes.size() >= 2, "clip should have 2 notes");
            if (clip.notes.size() < 2) return;

            expectEquals(clip.notes[0].pitch, 60, "first note pitch");
            expectEquals(clip.notes[1].pitch, 72, "second note pitch");
            expectWithinAbsoluteError(clip.notes[0].velocity, 100.0f, 0.1f);
        }
    }
};

static MidiClipNotesTest midiClipNotesTest;