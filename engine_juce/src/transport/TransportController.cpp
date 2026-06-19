#include "audioapp/transport/TransportController.hpp"

#include <cmath>

namespace audioapp {

void TransportController::reset() {
    bpm_ = 120;
    playing_.store(false, std::memory_order_release);
    playheadBeats_.store(0.0, std::memory_order_release);
    loopEnabled_ = true;
    loopRegionStartBeat_ = 0.0;
    loopRegionEndBeat_ = 16.0;
}

bool TransportController::setBpm(int bpm) {
    if (bpm < 40 || bpm > 300) {
        return false;
    }
    bpm_ = bpm;
    return true;
}

void TransportController::setPlaying(bool playing) noexcept {
    playing_.store(playing, std::memory_order_release);
}

bool TransportController::isPlaying() const noexcept {
    return playing_.load(std::memory_order_acquire);
}

double TransportController::playheadBeats() const noexcept {
    return playheadBeats_.load(std::memory_order_acquire);
}

void TransportController::setPlayheadBeats(double beats) noexcept {
    const double clamped = beats < 0.0 ? 0.0 : beats;
    playheadBeats_.store(clamped, std::memory_order_release);
}

void TransportController::resetPlayhead() noexcept {
    playheadBeats_.store(0.0, std::memory_order_release);
}

void TransportController::advancePlayhead(int numFrames, double sampleRate) noexcept {
    if (!playing_.load(std::memory_order_acquire)) {
        return;
    }
    const double current = playheadBeats_.load(std::memory_order_relaxed);
    double next = advancePlayheadBeats(current, numFrames, sampleRate, bpm_);
    if (loopEnabled_) {
        const double regionLen = loopRegionEndBeat_ - loopRegionStartBeat_;
        if (regionLen > 0.0 && next >= loopRegionEndBeat_) {
            next = loopRegionStartBeat_ +
                   std::fmod(next - loopRegionStartBeat_, regionLen);
        }
    }
    playheadBeats_.store(next, std::memory_order_release);
}

void TransportController::setLoopEnabled(bool enabled) noexcept {
    loopEnabled_ = enabled;
}

bool TransportController::setLoopLengthBeats(double lengthBeats) noexcept {
    if (lengthBeats < 1.0) {
        return false;
    }
    loopRegionStartBeat_ = 0.0;
    loopRegionEndBeat_ = lengthBeats;
    return true;
}

bool TransportController::setLoopRegion(double startBeat, double endBeat) noexcept {
    if (startBeat < 0.0 || endBeat - startBeat < 1.0) {
        return false;
    }
    loopRegionStartBeat_ = startBeat;
    loopRegionEndBeat_ = endBeat;
    return true;
}

} // namespace audioapp
