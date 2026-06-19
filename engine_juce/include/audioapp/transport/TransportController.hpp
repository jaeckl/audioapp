#pragma once

#include "audioapp/MidiClipPlayback.hpp"

#include <atomic>

namespace audioapp {

/// BPM, playhead, loop, and playing state shared by arrangement and audio paths.
class TransportController {
public:
    void reset();

    bool setBpm(int bpm);
    int bpm() const noexcept { return bpm_.load(std::memory_order_acquire); }

    void setPlaying(bool playing) noexcept;
    bool isPlaying() const noexcept;

    double playheadBeats() const noexcept;
    void setPlayheadBeats(double beats) noexcept;
    void resetPlayhead() noexcept;
    void advancePlayhead(int numFrames, double sampleRate) noexcept;

    void setLoopEnabled(bool enabled) noexcept;
    bool loopEnabled() const noexcept { return loopEnabled_.load(std::memory_order_acquire); }

    bool setLoopLengthBeats(double lengthBeats) noexcept;
    double loopLengthBeats() const noexcept { return loopRegionEndBeat_.load(std::memory_order_acquire) - loopRegionStartBeat_.load(std::memory_order_acquire); }

    bool setLoopRegion(double startBeat, double endBeat) noexcept;
    double loopRegionStartBeat() const noexcept { return loopRegionStartBeat_.load(std::memory_order_acquire); }
    double loopRegionEndBeat() const noexcept { return loopRegionEndBeat_.load(std::memory_order_acquire); }

private:
    std::atomic<int> bpm_{120};
    std::atomic<bool> playing_{false};
    std::atomic<double> playheadBeats_{0.0};
    std::atomic<bool> loopEnabled_{true};
    std::atomic<double> loopRegionStartBeat_{0.0};
    std::atomic<double> loopRegionEndBeat_{16.0};
};

} // namespace audioapp
