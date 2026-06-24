#include "audioapp/MidiClipPlayback.hpp"

#include <cmath>

namespace audioapp {

namespace {

bool isNoteActiveInLoop(double loopedBeat, const MidiNoteState& note) noexcept {
    return loopedBeat >= note.startBeat && loopedBeat < (note.startBeat + note.durationBeats);
}

} // namespace

int activeMidiPitchAtBeat(double playheadBeat, const MidiClipState& clip) noexcept {
    if (playheadBeat < clip.startBeat || playheadBeat >= clip.startBeat + clip.lengthBeats * 2.0) {
        return -1;
    }

    const double posInClip = playheadBeat - clip.startBeat;
    const double loopedBeat = std::fmod(posInClip, clip.lengthBeats);

    int activePitch = -1;
    for (const auto& note : clip.notes) {
        if (isNoteActiveInLoop(loopedBeat, note)) {
            activePitch = note.pitch;
        }
    }
    return activePitch;
}

double advancePlayheadBeats(double playheadBeat,
                            int numFrames,
                            double sampleRate,
                            int bpm) noexcept {
    if (sampleRate <= 0.0 || bpm <= 0) {
        return playheadBeat;
    }
    const double seconds = static_cast<double>(numFrames) / sampleRate;
    const double beats = seconds * (static_cast<double>(bpm) / 60.0);
    return playheadBeat + beats;
}

} // namespace audioapp
