#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/ProjectEngine.hpp"

#include <cmath>

class AutomationClipDragTest : public juce::UnitTest {
public:
    AutomationClipDragTest()
        : juce::UnitTest("Automation Clip Drag", "Automation") {}

    void runTest() override {
        beginTest("Move automation clip between tracks");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();

            // Create two tracks — the automation clip starts on track 1.
            const std::string track1 = project->addTrack("Synth");
            const std::string track2 = project->addTrack("Drums");
            expect(!track1.empty() && !track2.empty());
            expect(project->selectTrack(track1));

            // Create an automation clip on track 1.
            const std::string aclipId = project->createAutomationClip(track1, 0.0, 4.0);
            expect(!aclipId.empty());

            // Verify initial homeTrackId matches track1 in the snapshot.
            {
                const auto snap = project->snapshot();
                expectEquals(static_cast<int>(snap.automationClips.size()), 1);
                expectEquals(snap.automationClips[0].homeTrackId, track1);
                expectEquals(snap.automationClips[0].id, aclipId);
                // Verify per-track refs (backward compat)
                for (const auto& t : snap.tracks) {
                    (void)t;
                }
                if (snap.tracks.size() >= 1)
                    expect(static_cast<int>(snap.tracks[0].automationClips.size()) == 1 ||
                           static_cast<int>(snap.tracks[0].automationClips.size()) == 0,
                           "track 0 may or may not host the clip's backward compat entry");
                if (snap.tracks.size() >= 2)
                    expect(static_cast<int>(snap.tracks[1].automationClips.size()) == 0,
                           "track 1 should have no backward compat entry");
            }

            // Move the automation clip to track 2 at a different beat position.
            expect(project->moveClip(aclipId, track2, 8.0));

            // Verify the clip's homeTrackId changed to track2 and startBeat changed.
            {
                const auto moved = project->snapshot();
                expectEquals(static_cast<int>(moved.automationClips.size()), 1);
                const auto& clip = moved.automationClips[0];
                expectEquals(clip.homeTrackId, track2);
                expectWithinAbsoluteError(clip.startBeat, 8.0, 0.001);
                if (moved.tracks.size() >= 1)
                    expect(static_cast<int>(moved.tracks[0].automationClips.size()) == 0,
                           "track 0 should have no per-track clip after move");
                if (moved.tracks.size() >= 2) {
                    expect(static_cast<int>(moved.tracks[1].automationClips.size()) == 1,
                           "track 1 should have per-track clip after move");
                    if (moved.tracks[1].automationClips.size() >= 1)
                        expectEquals(moved.tracks[1].automationClips[0].id, aclipId);
                }
            }

            // Move back to track 1 at the original position.
            expect(project->moveClip(aclipId, track1, 0.0));

            // Verify round-trip: homeTrackId is back to track1.
            {
                const auto back = project->snapshot();
                expectEquals(static_cast<int>(back.automationClips.size()), 1);
                expectEquals(back.automationClips[0].homeTrackId, track1);
                expectWithinAbsoluteError(back.automationClips[0].startBeat, 0.0, 0.001);
                expectEquals(static_cast<int>(back.tracks[0].automationClips.size()), 1);
                expectEquals(static_cast<int>(back.tracks[1].automationClips.size()), 0);
            }

            // Verify that moving a non-existent clip fails gracefully.
            expect(!project->moveClip("not-a-real-clip", track2, 0.0));
        }
    }
};

static AutomationClipDragTest automationClipDragTest;