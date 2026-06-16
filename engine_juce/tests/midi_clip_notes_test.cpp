#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectJson.hpp"

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
    notes.push_back(audioapp::MidiNoteState{60, 0.0, 1.0, 100.0f});
    notes.push_back(audioapp::MidiNoteState{64, 1.0, 1.0, 100.0f});

    if (!project.setMidiClipNotes(clipId, notes)) {
        return EXIT_FAILURE;
    }

    const auto updated = project.snapshot();
    if (updated.tracks[0].midiClips[0].notes.size() != 2) {
        return EXIT_FAILURE;
    }

    const std::string args = R"({"clipId":"clip-1","notes":[{"pitch":72,"startBeat":2.0,"durationBeats":0.5,"velocity":100.0}]})";
    const auto parsed = audioapp::parseMidiNotesFromArgs(args);
    if (parsed.size() != 1 || parsed[0].pitch != 72) {
        return EXIT_FAILURE;
    }

    project.setPlaying(true);
    if (std::abs(project.activeOscillatorFrequencyHz() - 261.63f) > 1.0f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
