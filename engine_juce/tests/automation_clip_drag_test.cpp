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
            }

            // Move back to track 1 at the original position.
            expect(project->moveClip(aclipId, track1, 0.0));

            // Verify round-trip: homeTrackId is back to track1.
            {
                const auto back = project->snapshot();
                expectEquals(static_cast<int>(back.automationClips.size()), 1);
                expectEquals(back.automationClips[0].homeTrackId, track1);
                expectWithinAbsoluteError(back.automationClips[0].startBeat, 0.0, 0.001);
            }

            // Verify that moving a non-existent clip fails gracefully.
            expect(!project->moveClip("not-a-real-clip", track2, 0.0));
        }
    }
};

static AutomationClipDragTest automationClipDragTest;