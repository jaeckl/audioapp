#pragma once

#include <algorithm>
#include <cmath>

namespace audioapp {

template<typename NoteRange>
inline double midiNotesContentLengthBeats(const NoteRange& notes, double fallback) noexcept {
    double end = 0.0;
    for (const auto& note : notes) {
        end = std::max(end, note.startBeat + note.durationBeats);
    }
    return end > 0.0 ? end : fallback;
}

/// Loop wrap period for a MIDI clip. Uses frozen naturalLengthBeats, but
/// clamps to the actual note extent when notes do not fill that window
/// (avoids silent beats before the wrap on extended clips).
template<typename NoteRange>
inline double midiClipLoopContentLengthBeats(const NoteRange& notes,
                                               double naturalLengthBeats,
                                               double clipLengthBeats) noexcept {
    const double noteEnd = midiNotesContentLengthBeats(notes, 0.0);
    if (naturalLengthBeats > 0.0) {
        if (noteEnd > 0.0 && noteEnd < naturalLengthBeats) {
            return noteEnd;
        }
        return naturalLengthBeats;
    }
    if (noteEnd > 0.0) {
        return noteEnd;
    }
    return clipLengthBeats;
}

template<typename NoteRange>
inline double midiClipOneShotContentLengthBeats(const NoteRange& notes,
                                                double naturalLengthBeats,
                                                double clipLengthBeats) noexcept {
    const double fallback = naturalLengthBeats > 0.0 ? naturalLengthBeats : clipLengthBeats;
    return midiNotesContentLengthBeats(notes, fallback);
}

inline double beatWithinClipContent(double beat,
                                    double clipStartBeat,
                                    double clipLengthBeats,
                                    double contentLengthBeats,
                                    bool loopContent) noexcept {
    if (beat < clipStartBeat || beat >= clipStartBeat + clipLengthBeats) {
        return -1.0;
    }
    const double pos = beat - clipStartBeat;
    if (!loopContent) {
        if (contentLengthBeats > 0.0 && pos >= contentLengthBeats) {
            return -1.0;
        }
        return pos;
    }
    if (contentLengthBeats <= 0.0) {
        return pos;
    }
    return std::fmod(pos, contentLengthBeats);
}

inline bool isMidiNoteActiveInClip(double beat,
                                   double clipStartBeat,
                                   double clipLengthBeats,
                                   double contentLengthBeats,
                                   bool loopContent,
                                   double noteStartBeat,
                                   double noteDurationBeats) noexcept {
    const double inContent = beatWithinClipContent(
        beat, clipStartBeat, clipLengthBeats, contentLengthBeats, loopContent);
    if (inContent < 0.0) {
        return false;
    }
    return inContent >= noteStartBeat
        && inContent < noteStartBeat + noteDurationBeats;
}

inline double sampleContentProgress(double beat,
                                    double clipStartBeat,
                                    double clipLengthBeats,
                                    double contentLengthBeats,
                                    bool loopContent,
                                    bool& activeOut) noexcept {
    activeOut = false;
    const double inContent = beatWithinClipContent(
        beat, clipStartBeat, clipLengthBeats, contentLengthBeats, loopContent);
    if (inContent < 0.0 || contentLengthBeats <= 0.0) {
        return 0.0;
    }
    activeOut = true;
    return inContent / contentLengthBeats;
}

/// Returns true when a render block may contain audible clip notes.
/// Used to avoid skipping whole blocks for looped clips.
inline bool blockMayContainLoopedClipNotes(double blockStartBeat,
                                           double blockEndBeat,
                                           double clipStartBeat,
                                           double clipLengthBeats,
                                           double contentLengthBeats,
                                           bool loopContent,
                                           double noteStartBeat,
                                           double noteDurationBeats,
                                           double releaseBeats) noexcept {
    const double clipEnd = clipStartBeat + clipLengthBeats;
    if (blockEndBeat <= clipStartBeat || blockStartBeat >= clipEnd) {
        return false;
    }
    if (loopContent && contentLengthBeats > 0.0) {
        return true;
    }
    const double noteStart = clipStartBeat + noteStartBeat;
    const double noteEnd = noteStart + noteDurationBeats + releaseBeats;
    const double contentEnd = clipStartBeat + contentLengthBeats;
    const double audibleEnd = std::min(noteEnd, contentEnd + releaseBeats);
    return !(blockEndBeat < noteStart || blockStartBeat >= audibleEnd);
}

} // namespace audioapp
