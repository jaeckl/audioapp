#include "audioapp/transport/TransportController.hpp"

#include <cmath>

namespace audioapp {

void TransportController::reset() {
    bpm_ = 120;
    playing_.store(false, std::memory_order_release);
    playheadBeats_.store(0.0, std::memory_order_release);
    loopEnabled_ = true;
    loopLengthBeats_ = 16.0;
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
    if (loopEnabled_ && loopLengthBeats_ > 0.0 && next >= loopLengthBeats_) {
        next = std::fmod(next, loopLengthBeats_);
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
    loopLengthBeats_ = lengthBeats;
    return true;
}

} // namespace audioapp
