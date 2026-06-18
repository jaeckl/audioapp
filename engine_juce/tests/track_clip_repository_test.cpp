#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/model/ClipRepository.hpp"
#include "audioapp/model/TrackRepository.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
    audioapp::TrackRepository trackRepo;
    audioapp::ClipRepository clipRepo{trackRepo};

    const std::string trackA = trackRepo.addTrack("A", registry);
    const std::string trackB = trackRepo.addTrack("B", registry);
    if (trackA.empty() || trackB.empty()) {
        return EXIT_FAILURE;
    }

    const std::string clipId = clipRepo.createMidiClip(trackA, 0.0, 4.0);
    if (clipId.empty()) {
        return EXIT_FAILURE;
    }

    if (!clipRepo.moveClip(clipId, trackB, 8.0)) {
        return EXIT_FAILURE;
    }

    const audioapp::Track* source = trackRepo.findTrack(trackA);
    const audioapp::Track* target = trackRepo.findTrack(trackB);
    if (source == nullptr || target == nullptr) {
        return EXIT_FAILURE;
    }
    if (!source->midiClips.empty() || target->midiClips.size() != 1) {
        return EXIT_FAILURE;
    }
    if (std::abs(target->midiClips[0].startBeat - 8.0) > 0.001) {
        return EXIT_FAILURE;
    }

    if (!clipRepo.duplicateClip(clipId)) {
        return EXIT_FAILURE;
    }
    if (target->midiClips.size() != 2) {
        return EXIT_FAILURE;
    }
    if (std::abs(target->midiClips[1].startBeat - 12.0) > 0.001) {
        return EXIT_FAILURE;
    }

    if (!clipRepo.setClipLength(clipId, 2.0)) {
        return EXIT_FAILURE;
    }
    if (std::abs(target->midiClips[0].lengthBeats - 2.0) > 0.001) {
        return EXIT_FAILURE;
    }

    if (!clipRepo.deleteClip(target->midiClips[1].id)) {
        return EXIT_FAILURE;
    }
    if (target->midiClips.size() != 1) {
        return EXIT_FAILURE;
    }

    if (clipRepo.moveClip("missing", trackA, 0.0)) {
        return EXIT_FAILURE;
    }

    trackRepo.recomputeIdCounters();
    clipRepo.recomputeIdCounters();
    const std::string clip2 = clipRepo.createMidiClip(trackA, 1.0, 4.0);
    if (clip2.find("clip-") != 0) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
