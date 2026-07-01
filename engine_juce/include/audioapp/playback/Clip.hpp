#pragma once

#include "audioapp/ClipContentPlayback.hpp"

#include <span>

namespace audioapp::playback {

struct ProcessRange {
    double startBeat = 0.0;
    double endBeat = 0.0;
};

/// Arrangement wrapper shared by every clip type. Content objects do not
/// know where they live, whether they are trimmed, or whether they loop.
class Clip {
public:
    Clip(double startBeat,
         double lengthBeats,
         double contentLengthBeats,
         bool loopContent) noexcept
        : startBeat_(startBeat),
          lengthBeats_(lengthBeats),
          contentLengthBeats_(contentLengthBeats),
          loopContent_(loopContent) {}

    double sourceBeatAt(double arrangementBeat) const noexcept {
        return beatWithinClipContent(arrangementBeat, startBeat_, lengthBeats_,
                                     contentLengthBeats_, loopContent_);
    }

    bool contains(double arrangementBeat) const noexcept {
        return sourceBeatAt(arrangementBeat) >= 0.0;
    }

    double startBeat() const noexcept { return startBeat_; }
    double lengthBeats() const noexcept { return lengthBeats_; }
    double contentLengthBeats() const noexcept { return contentLengthBeats_; }
    bool loops() const noexcept { return loopContent_; }

protected:
    double startBeat_ = 0.0;
    double lengthBeats_ = 0.0;
    double contentLengthBeats_ = 0.0;
    bool loopContent_ = false;
};

template <typename Note>
struct MidiData {
    std::span<const Note> notes;
};

template <typename Note>
class MidiClip final : public Clip {
public:
    MidiClip(double startBeat, double lengthBeats, double contentLengthBeats,
             bool loopContent, MidiData<Note> data) noexcept
        : Clip(startBeat, lengthBeats, contentLengthBeats, loopContent), data_(data) {}

    int activePitchAt(double arrangementBeat) const noexcept {
        const double sourceBeat = sourceBeatAt(arrangementBeat);
        if (sourceBeat < 0.0) return -1;
        int pitch = -1;
        for (const auto& note : data_.notes) {
            if (sourceBeat >= note.startBeat &&
                sourceBeat < note.startBeat + note.durationBeats) {
                pitch = note.pitch;
            }
        }
        return pitch;
    }

    const MidiData<Note>& data() const noexcept { return data_; }

private:
    MidiData<Note> data_;
};

struct AudioData {
    std::span<const float> samples;
    double sampleRate = 0.0;
};

class AudioClip final : public Clip {
public:
    using Clip::Clip;

    double progressAt(double arrangementBeat, bool& active) const noexcept {
        const double sourceBeat = sourceBeatAt(arrangementBeat);
        active = sourceBeat >= 0.0 && contentLengthBeats_ > 0.0;
        return active ? sourceBeat / contentLengthBeats_ : 0.0;
    }
};

template <typename Point>
struct AutomationData {
    std::span<const Point> points;
};

template <typename Point>
class AutomationClip final : public Clip {
public:
    AutomationClip(double startBeat, double lengthBeats, double contentLengthBeats,
                   bool loopContent, AutomationData<Point> data) noexcept
        : Clip(startBeat, lengthBeats, contentLengthBeats, loopContent), data_(data) {}

    const AutomationData<Point>& data() const noexcept { return data_; }

private:
    AutomationData<Point> data_;
};

} // namespace audioapp::playback
