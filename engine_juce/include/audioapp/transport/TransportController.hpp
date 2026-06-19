#pragma once

#include "audioapp/MidiClipPlayback.hpp"

#include <atomic>

namespace audioapp {

/// BPM, playhead, loop, and playing state shared by arrangement and audio paths.
class TransportController {
public:
    void reset();

    bool setBpm(int bpm);
    int bpm() const noexcept { return bpm_; }

    void setPlaying(bool playing) noexcept;
    bool isPlaying() const noexcept;

    double playheadBeats() const noexcept;
    void setPlayheadBeats(double beats) noexcept;
    void resetPlayhead() noexcept;
    void advancePlayhead(int numFrames, double sampleRate) noexcept;

    void setLoopEnabled(bool enabled) noexcept;
    bool loopEnabled() const noexcept { return loopEnabled_; }

    bool setLoopLengthBeats(double lengthBeats) noexcept;
    double loopLengthBeats() const noexcept { return loopRegionEndBeat_ - loopRegionStartBeat_; }

    bool setLoopRegion(double startBeat, double endBeat) noexcept;
    double loopRegionStartBeat() const noexcept { return loopRegionStartBeat_; }
    double loopRegionEndBeat() const noexcept { return loopRegionEndBeat_; }

private:
    int bpm_ = 120;
    std::atomic<bool> playing_{false};
    std::atomic<double> playheadBeats_{0.0};
    bool loopEnabled_ = true;
    double loopRegionStartBeat_ = 0.0;
    double loopRegionEndBeat_ = 16.0;
};

} // namespace audioapp
