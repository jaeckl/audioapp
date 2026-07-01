#include "audioapp/MidiClipPlayback.hpp"

#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/playback/Clip.hpp"

#include <cmath>

namespace audioapp {

int activeMidiPitchAtBeat(double playheadBeat, const MidiClipState& clip) noexcept {
    const double contentLength =
        clip.loopContent
            ? midiClipLoopContentLengthBeats(
                  clip.notes, clip.naturalLengthBeats, clip.lengthBeats)
            : midiClipOneShotContentLengthBeats(
                  clip.notes, clip.naturalLengthBeats, clip.lengthBeats);
    const playback::MidiClip<MidiNoteState> playable{
        clip.startBeat, clip.lengthBeats, contentLength, clip.loopContent,
        playback::MidiData<MidiNoteState>{clip.notes}};
    return playable.activePitchAt(playheadBeat);
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
