#pragma once

#include <string>

namespace audioapp {

/// Shared timeline placement for arrangement clips (MIDI, audio, automation).
enum class ClipContentKind { Midi, Sample, Automation };

struct ClipTimelineSpan {
    std::string id;
    double startBeat = 0.0;
    double lengthBeats = 4.0;
    ClipContentKind kind = ClipContentKind::Midi;
};

constexpr double kMinClipLengthBeats = 0.25;

/// Which clip span [setClipLength] updates. Arrangement resize only changes
/// timeline span; editor range slider uses Content for naturalLengthBeats.
enum class ClipLengthTarget { Arrangement, Content };

inline ClipLengthTarget clipLengthTargetFromString(const std::string& value) {
    return value == "content" ? ClipLengthTarget::Content : ClipLengthTarget::Arrangement;
}

} // namespace audioapp
