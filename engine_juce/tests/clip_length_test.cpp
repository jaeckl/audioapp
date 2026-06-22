#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/MidiClipPlayback.hpp"
#include "audioapp/ProjectEngine.hpp"
#include "audioapp/TimelineClipTypes.hpp"

#include <cmath>

class ClipLengthTest : public juce::UnitTest {
public:
    ClipLengthTest() : juce::UnitTest("ClipLength", "Project") {}

    void runTest() override
    {
        beginTest("Setup and basic snapshot checks");
        
        auto project = std::make_unique<audioapp::ProjectEngine>();
        project->createProject();

        const std::string trackId = project->addTrack("Keys");
        project->createMidiClip(trackId, 0.0, 4.0);

        const auto snap = project->snapshot();
        expect(!snap.tracks.empty(), "should have tracks");
        if (snap.tracks.empty()) return;
        expect(!snap.tracks[0].midiClips.empty(), "track should have MIDI clips");
        if (snap.tracks[0].midiClips.empty()) return;

        const std::string clipId = snap.tracks[0].midiClips[0].id;

        beginTest("set clip notes and shorten length");
        {
            std::vector<audioapp::MidiNoteState> notes;
            notes.push_back(audioapp::MidiNoteState{60, 0.0, 4.0, 100.0f});
            notes.push_back(audioapp::MidiNoteState{64, 3.0, 1.0, 100.0f});
            expect(project->setMidiClipNotes(clipId, notes),
                   "should set clip notes");

            expect(project->setClipLength(clipId, 2.0),
                   "should set clip length to 2.0");

            const auto shortened = project->snapshot();
            expectWithinAbsoluteError(shortened.tracks[0].midiClips[0].lengthBeats, 2.0, 0.001);
            expect(shortened.tracks[0].midiClips[0].notes.size() == 2,
                   "notes should be preserved after shortening");
        }

        beginTest("activeMidiPitchAtBeat with shortened clip");
        {
            const auto shortened = project->snapshot();
            audioapp::MidiClipState clipState;
            clipState.startBeat = 0.0;
            clipState.lengthBeats = 2.0;
            clipState.notes = shortened.tracks[0].midiClips[0].notes;

            expectEquals(audioapp::activeMidiPitchAtBeat(1.5, clipState), 60,
                         "pitch at 1.5 should be 60");
            expectEquals(audioapp::activeMidiPitchAtBeat(2.5, clipState), -1,
                         "pitch at 2.5 should be -1 (beyond shortened length)");
        }

        beginTest("clip length clamped to minimum");
        {
            expect(project->setClipLength(clipId, 0.1),
                   "should set clip length to 0.1");

            const auto clamped = project->snapshot();
            expectWithinAbsoluteError(clamped.tracks[0].midiClips[0].lengthBeats,
                                      audioapp::kMinClipLengthBeats, 0.001,
                                      "clip length should be clamped to minimum");
        }

        beginTest("set automation clip length");
        {
            auto automationProject = std::make_unique<audioapp::ProjectEngine>();
            automationProject->createProject();

            const std::string automationTrackId = automationProject->addTrack("Keys");
            const std::string automationClipId =
                automationProject->createAutomationClip(automationTrackId, 0.0, 4.0);
            automationProject->assignAutomationTarget(automationClipId, "dev1", "gain");

            expect(automationProject->setClipLength(automationClipId, 8.0),
                   "setClipLength on automation clip returns true");

            const auto automationSnap = automationProject->snapshot();
            expect(!automationSnap.automationClips.empty());
            if (!automationSnap.automationClips.empty()) {
                expectWithinAbsoluteError(automationSnap.automationClips[0].lengthBeats,
                                          8.0, 0.001);
            }
        }

        beginTest("automation clip length clamped to minimum");
        {
            auto automationProject = std::make_unique<audioapp::ProjectEngine>();
            automationProject->createProject();

            const std::string automationTrackId = automationProject->addTrack("Keys");
            const std::string automationClipId =
                automationProject->createAutomationClip(automationTrackId, 0.0, 4.0);

            expect(automationProject->setClipLength(automationClipId, 0.001),
                   "setClipLength on automation clip returns true");

            const auto automationSnap = automationProject->snapshot();
            expect(!automationSnap.automationClips.empty());
            if (!automationSnap.automationClips.empty()) {
                expectWithinAbsoluteError(automationSnap.automationClips[0].lengthBeats,
                                          0.01, 0.001,
                                          "automation clip length clamped to 0.01");
            }
        }

        beginTest("set sample clip length");
        {
            auto sampleProject = std::make_unique<audioapp::ProjectEngine>();
            sampleProject->createProject();

            const std::string sampleTrackId = sampleProject->addTrack("Keys");
            sampleProject->createSampleClip(sampleTrackId, "sample-1", 0.0, 4.0);

            const auto sampleSnap = sampleProject->snapshot();
            if (sampleSnap.tracks.empty() || sampleSnap.tracks[0].sampleClips.empty()) return;
            const std::string sampleClipId = sampleSnap.tracks[0].sampleClips[0].id;

            expect(sampleProject->setClipLength(sampleClipId, 6.0),
                   "setClipLength on sample clip returns true");

            const auto updated = sampleProject->snapshot();
            expect(!updated.tracks.empty() && !updated.tracks[0].sampleClips.empty());
            if (!updated.tracks.empty() && !updated.tracks[0].sampleClips.empty()) {
                expectWithinAbsoluteError(updated.tracks[0].sampleClips[0].lengthBeats,
                                          6.0, 0.001);
            }
        }

        beginTest("unknown clip id returns false");
        {
            auto unknownProject = std::make_unique<audioapp::ProjectEngine>();
            unknownProject->createProject();

            expect(!unknownProject->setClipLength("nonexistent-clip", 4.0),
                   "setClipLength on unknown id returns false");
        }
    }
};

static ClipLengthTest clipLengthTest;