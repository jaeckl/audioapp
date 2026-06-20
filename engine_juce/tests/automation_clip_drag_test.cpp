#include "audioapp/ProjectEngine.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    audioapp::ProjectEngine project;
    project.createProject();

    // Create two tracks — the automation clip starts on track 1.
    const std::string track1 = project.addTrack("Synth");
    const std::string track2 = project.addTrack("Drums");
    if (track1.empty() || track2.empty()) {
        return EXIT_FAILURE;
    }
    if (!project.selectTrack(track1)) {
        return EXIT_FAILURE;
    }

    // Create an automation clip on track 1.
    const std::string aclipId = project.createAutomationClip(track1, 0.0, 4.0);
    if (aclipId.empty()) {
        return EXIT_FAILURE;
    }

    // Verify initial homeTrackId matches track1 in the snapshot.
    {
        const auto snap = project.snapshot();
        if (snap.automationClips.size() != 1) {
            return EXIT_FAILURE;
        }
        if (snap.automationClips[0].homeTrackId != track1) {
            return EXIT_FAILURE;
        }
        if (snap.automationClips[0].id != aclipId) {
            return EXIT_FAILURE;
        }
        // The clip should appear on track1's per-track list but not on track2's.
        if (snap.tracks[0].automationClips.size() != 1) {
            return EXIT_FAILURE;
        }
        if (snap.tracks[1].automationClips.size() != 0) {
            return EXIT_FAILURE;
        }
    }

    // Move the automation clip to track 2 at a different beat position.
    if (!project.moveClip(aclipId, track2, 8.0)) {
        return EXIT_FAILURE;
    }

    // Verify the clip's homeTrackId changed to track2 and startBeat changed.
    {
        const auto moved = project.snapshot();
        if (moved.automationClips.size() != 1) {
            return EXIT_FAILURE;
        }
        const auto& clip = moved.automationClips[0];
        if (clip.homeTrackId != track2) {
            return EXIT_FAILURE;
        }
        if (std::abs(clip.startBeat - 8.0) > 0.001) {
            return EXIT_FAILURE;
        }
        // The clip should appear on track2's per-track list and not on track1's.
        if (moved.tracks[0].automationClips.size() != 0) {
            return EXIT_FAILURE;
        }
        if (moved.tracks[1].automationClips.size() != 1) {
            return EXIT_FAILURE;
        }
        if (moved.tracks[1].automationClips[0].id != aclipId) {
            return EXIT_FAILURE;
        }
    }

    // Move back to track 1 at the original position.
    if (!project.moveClip(aclipId, track1, 0.0)) {
        return EXIT_FAILURE;
    }

    // Verify round-trip: homeTrackId is back to track1.
    {
        const auto back = project.snapshot();
        if (back.automationClips.size() != 1) {
            return EXIT_FAILURE;
        }
        if (back.automationClips[0].homeTrackId != track1) {
            return EXIT_FAILURE;
        }
        if (std::abs(back.automationClips[0].startBeat - 0.0) > 0.001) {
            return EXIT_FAILURE;
        }
        // Per-track lists updated accordingly.
        if (back.tracks[0].automationClips.size() != 1) {
            return EXIT_FAILURE;
        }
        if (back.tracks[1].automationClips.size() != 0) {
            return EXIT_FAILURE;
        }
    }

    // Verify that moving a non-existent clip fails gracefully.
    if (project.moveClip("not-a-real-clip", track2, 0.0)) {
        return EXIT_FAILURE;
    }

    // Verify that calling moveClip with an empty targetTrackId preserves
    // the existing homeTrackId (only updates startBeat).
    {
        if (!project.moveClip(aclipId, "", 12.0)) {
            return EXIT_FAILURE;
        }
        const auto snap = project.snapshot();
        // The clip should still be on track1 (homeTrackId unchanged).
        if (snap.automationClips[0].homeTrackId != track1) {
            return EXIT_FAILURE;
        }
        if (std::abs(snap.automationClips[0].startBeat - 12.0) > 0.001) {
            return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}