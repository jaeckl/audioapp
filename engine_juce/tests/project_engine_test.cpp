#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/ProjectEngine.hpp"

#include <cmath>

class ProjectEngineTest : public juce::UnitTest {
public:
    ProjectEngineTest() : juce::UnitTest("ProjectEngine", "Project") {}

    void runTest() override
    {
        beginTest("add track, select, set parameter");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();

            const std::string trackId = project->addTrack("Drums");
            expect(!trackId.empty(), "should add track");

            expect(project->selectTrack(trackId), "should select existing track");

            const auto snap = project->snapshot();
            expect(snap.tracks.size() == 1, "should have one track");
            expect(!snap.tracks[0].devices.empty(), "track should have default devices");

            const auto& device = snap.tracks[0].devices[0];
            expect(!device.id.empty(), "first device should have an id");

            expect(project->setDeviceParameter(device.id, "gain", 0.5f),
                   "should set device parameter");

            const auto snapAfterGain = project->snapshot();
            expectWithinAbsoluteError(snapAfterGain.tracks[0].devices[0].gain, 0.5f, 0.01f);
        }

        beginTest("select missing track fails");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            expect(!project->selectTrack("missing"),
                   "selecting missing track should fail");
        }

        beginTest("create and move MIDI clip");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();

            const std::string trackId = project->addTrack("Drums");
            const std::string clipId = project->createMidiClip(trackId, 0.0, 4.0);
            expect(!clipId.empty(), "should create MIDI clip");

            const auto snapWithClip = project->snapshot();
            expect(!snapWithClip.tracks[0].midiClips.empty(),
                   "track should have MIDI clips");

            const std::string track2Id = project->addTrack("Bass");
            expect(!track2Id.empty(), "should add second track");

            expect(project->moveClip(clipId, track2Id, 8.0),
                   "should move clip to second track");

            const auto moved = project->snapshot();
            expect(moved.tracks[0].midiClips.size() == 0,
                   "first track should have no clips after move");
            expect(moved.tracks[1].midiClips.size() == 1,
                   "second track should have one clip after move");
            expectWithinAbsoluteError(moved.tracks[1].midiClips[0].startBeat, 8.0, 0.001);
        }

        beginTest("playback state");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            project->setPlaying(true);
            expect(project->isPlaying(), "should be playing after setPlaying(true)");
            project->setPlaying(false);
            expect(!project->isPlaying(), "should not be playing after setPlaying(false)");
        }
    }
};

static ProjectEngineTest projectEngineTest;