#include "audioapp/ProjectEngine.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    audioapp::ProjectEngine project;
    project.createProject();

    const std::string trackId = project.addTrack("Drums");
    if (trackId.empty()) {
        return EXIT_FAILURE;
    }

    if (!project.selectTrack(trackId)) {
        return EXIT_FAILURE;
    }

    const auto snap = project.snapshot();
    if (snap.tracks.size() != 1 || snap.tracks[0].devices.empty()) {
        return EXIT_FAILURE;
    }

    const auto& device = snap.tracks[0].devices[0];
    if (device.type != "track_gain") {
        return EXIT_FAILURE;
    }

    if (!project.setDeviceParameter(device.id, "gain", 0.5f)) {
        return EXIT_FAILURE;
    }

    const auto snapAfterGain = project.snapshot();
    if (std::abs(snapAfterGain.tracks[0].devices[0].gain - 0.5f) > 0.01f) {
        return EXIT_FAILURE;
    }

    if (project.selectTrack("missing")) {
        return EXIT_FAILURE;
    }

    const std::string clipId = project.createMidiClip(trackId, 0.0, 4.0);
    if (clipId.empty()) {
        return EXIT_FAILURE;
    }

    const auto snapWithClip = project.snapshot();
    if (snapWithClip.tracks[0].midiClips.empty()) {
        return EXIT_FAILURE;
    }

    const std::string track2Id = project.addTrack("Bass");
    if (track2Id.empty()) {
        return EXIT_FAILURE;
    }

    if (!project.moveClip(clipId, track2Id, 8.0)) {
        return EXIT_FAILURE;
    }

    const auto moved = project.snapshot();
    if (moved.tracks[0].midiClips.size() != 0 || moved.tracks[1].midiClips.size() != 1) {
        return EXIT_FAILURE;
    }
    if (std::abs(moved.tracks[1].midiClips[0].startBeat - 8.0) > 0.001) {
        return EXIT_FAILURE;
    }

    project.setPlaying(true);
    if (!project.isPlaying()) {
        return EXIT_FAILURE;
    }
    project.setPlaying(false);

    return EXIT_SUCCESS;
}
