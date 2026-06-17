#include "audioapp/MidiClipPlayback.hpp"
#include "audioapp/ProjectEngine.hpp"
#include "audioapp/TimelineClipTypes.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    audioapp::ProjectEngine project;
    project.createProject();

    const std::string trackId = project.addTrack("Keys");
    project.createMidiClip(trackId, 0.0, 4.0);

    const auto snap = project.snapshot();
    if (snap.tracks.empty() || snap.tracks[0].midiClips.empty()) {
        return EXIT_FAILURE;
    }

    const std::string clipId = snap.tracks[0].midiClips[0].id;

    std::vector<audioapp::MidiNoteState> notes;
    notes.push_back(audioapp::MidiNoteState{60, 0.0, 4.0, 100.0f});
    notes.push_back(audioapp::MidiNoteState{64, 3.0, 1.0, 100.0f});
    if (!project.setMidiClipNotes(clipId, notes)) {
        return EXIT_FAILURE;
    }

    if (!project.setClipLength(clipId, 2.0)) {
        return EXIT_FAILURE;
    }

    const auto shortened = project.snapshot();
    if (std::abs(shortened.tracks[0].midiClips[0].lengthBeats - 2.0) > 0.001) {
        return EXIT_FAILURE;
    }
    if (shortened.tracks[0].midiClips[0].notes.size() != 2) {
        return EXIT_FAILURE;
    }

    audioapp::MidiClipState clipState;
    clipState.startBeat = 0.0;
    clipState.lengthBeats = 2.0;
    clipState.notes = shortened.tracks[0].midiClips[0].notes;
    if (audioapp::activeMidiPitchAtBeat(1.5, clipState) != 60) {
        return EXIT_FAILURE;
    }
    if (audioapp::activeMidiPitchAtBeat(2.5, clipState) != -1) {
        return EXIT_FAILURE;
    }

    if (!project.setClipLength(clipId, 0.1)) {
        return EXIT_FAILURE;
    }
    const auto clamped = project.snapshot();
    if (std::abs(clamped.tracks[0].midiClips[0].lengthBeats - audioapp::kMinClipLengthBeats) > 0.001) {
        return EXIT_FAILURE;
    }

    project.setPlaying(true);
    project.addDeviceToTrack(trackId, "simple_oscillator");
    project.setPlayheadBeats(1.5);
    if (std::abs(project.activeOscillatorFrequencyHz() - 261.63f) > 1.0f) {
        return EXIT_FAILURE;
    }
    project.setPlayheadBeats(2.5);
    if (project.activeOscillatorFrequencyHz() > 0.0f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
