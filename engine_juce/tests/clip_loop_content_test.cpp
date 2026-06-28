#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/MidiClipPlayback.hpp"
#include "audioapp/ProjectEngine.hpp"

class ClipLoopContentTest : public juce::UnitTest {
public:
    ClipLoopContentTest() : juce::UnitTest("ClipLoopContent", "Project") {}

    void runTest() override
    {
        beginTest("setClipLoopContent toggles snapshot field");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();

            const std::string trackId = project->addTrack("Keys");
            project->createMidiClip(trackId, 0.0, 8.0);

            const auto snap = project->snapshot();
            expect(!snap.tracks.empty(), "should have tracks");
            if (snap.tracks.empty()) return;
            expect(!snap.tracks[0].midiClips.empty(), "track should have MIDI clips");
            if (snap.tracks[0].midiClips.empty()) return;

            const std::string clipId = snap.tracks[0].midiClips[0].id;
            expect(!snap.tracks[0].midiClips[0].loopContent,
                   "loop content defaults to false");

            expect(project->setClipLoopContent(clipId, true),
                   "setClipLoopContent should succeed");
            expect(project->snapshot().tracks[0].midiClips[0].loopContent,
                   "loop content should be true in snapshot");

            expect(project->setClipLoopContent(clipId, false),
                   "disable loop should succeed");
            expect(!project->snapshot().tracks[0].midiClips[0].loopContent,
                   "loop content should be false again");
        }

        beginTest("looping repeats MIDI content inside longer clip");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();

            const std::string trackId = project->addTrack("Keys");
            project->createMidiClip(trackId, 0.0, 8.0);

            const std::string clipId = project->snapshot().tracks[0].midiClips[0].id;
            std::vector<audioapp::MidiNoteState> notes;
            notes.push_back(audioapp::MidiNoteState{60, 0.0, 4.0, 100.0f});
            expect(project->setMidiClipNotes(clipId, notes), "set notes");
            expect(project->setClipLoopContent(clipId, true), "enable loop");

            audioapp::MidiClipState clipState = project->snapshot().tracks[0].midiClips[0];
            expectEquals(audioapp::activeMidiPitchAtBeat(6.0, clipState), 60,
                         "beat 6 should wrap to active C4 when loop enabled");
            expectEquals(audioapp::activeMidiPitchAtBeat(5.0, clipState), 60,
                         "beat 5 should wrap when loop enabled");
            clipState.loopContent = false;
            expectEquals(audioapp::activeMidiPitchAtBeat(5.0, clipState), -1,
                         "beat 5 should be silent when loop disabled");
        }

        beginTest("extended clip loops at note extent not frozen natural tail");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();

            const std::string trackId = project->addTrack("Keys");
            project->createMidiClip(trackId, 0.0, 16.0);

            const std::string clipId = project->snapshot().tracks[0].midiClips[0].id;
            std::vector<audioapp::MidiNoteState> notes;
            notes.push_back(audioapp::MidiNoteState{60, 0.0, 4.0, 100.0f});
            notes.push_back(audioapp::MidiNoteState{60, 4.0, 4.0, 100.0f});
            expect(project->setMidiClipNotes(clipId, notes), "set two-bar notes");
            expect(project->setClipLength(clipId, 20.0), "extend to five bars");
            expect(project->setClipLoopContent(clipId, true), "enable loop");

            audioapp::MidiClipState clipState = project->snapshot().tracks[0].midiClips[0];
            expectEquals(clipState.naturalLengthBeats, 8.0,
                         "natural length follows saved note extent");
            expectEquals(audioapp::activeMidiPitchAtBeat(12.0, clipState), 60,
                         "beat 12 should repeat bar-1 content when loop enabled");
            expectEquals(audioapp::activeMidiPitchAtBeat(16.0, clipState), 60,
                         "beat 16 should repeat bar-1 content when loop enabled");
        }

        beginTest("loopContent round-trips through project file JSON");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            const std::string trackId = project->addTrack("Keys");
            project->createMidiClip(trackId, 0.0, 4.0);
            const std::string clipId = project->snapshot().tracks[0].midiClips[0].id;
            expect(project->setClipLoopContent(clipId, true), "enable midi loop");

            const auto fileData = project->toProjectFileData();
            auto loaded = std::make_unique<audioapp::ProjectEngine>();
            expect(loaded->loadFromProjectFileData(fileData), "reload project");
            expect(loaded->snapshot().tracks[0].midiClips[0].loopContent,
                   "midi loopContent survives save/load");
        }

        beginTest("unknown clip id returns false");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            expect(!project->setClipLoopContent("missing-clip", true),
                   "unknown clip should fail");
        }
    }
};

static ClipLoopContentTest clipLoopContentTest;
