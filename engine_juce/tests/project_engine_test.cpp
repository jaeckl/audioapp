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
    if (!project.setDeviceParameter(device.id, "frequency", 220.0f)) {
        return EXIT_FAILURE;
    }

    if (std::abs(project.activeOscillatorFrequencyHz() - 220.0f) > 0.01f) {
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

    project.setPlaying(true);
    if (!project.isPlaying()) {
        return EXIT_FAILURE;
    }
    if (std::abs(project.activeOscillatorFrequencyHz() - 261.63f) > 1.0f) {
        return EXIT_FAILURE;
    }
    project.setPlaying(false);

    return EXIT_SUCCESS;
}
