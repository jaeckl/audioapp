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

} // namespace audioapp
