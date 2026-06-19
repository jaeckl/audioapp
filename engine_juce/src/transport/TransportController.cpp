#include "audioapp/transport/TransportController.hpp"

#include <cmath>

namespace audioapp {

void TransportController::reset() {
    bpm_.store(120, std::memory_order_release);
    playing_.store(false, std::memory_order_release);
    playheadBeats_.store(0.0, std::memory_order_release);
    loopEnabled_.store(true, std::memory_order_release);
    loopRegionStartBeat_.store(0.0, std::memory_order_release);
    loopRegionEndBeat_.store(16.0, std::memory_order_release);
}

bool TransportController::setBpm(int bpm) {
    if (bpm < 40 || bpm > 300) {
        return false;
    }
    bpm_.store(bpm, std::memory_order_release);
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
    const int bpm = bpm_.load(std::memory_order_acquire);
    double next = advancePlayheadBeats(current, numFrames, sampleRate, bpm);
    if (loopEnabled_.load(std::memory_order_acquire)) {
        const double startBeat = loopRegionStartBeat_.load(std::memory_order_acquire);
        const double endBeat = loopRegionEndBeat_.load(std::memory_order_acquire);
        const double regionLen = endBeat - startBeat;
        if (regionLen > 0.0 && next >= endBeat) {
            next = startBeat + std::fmod(next - startBeat, regionLen);
        }
    }
    playheadBeats_.store(next, std::memory_order_release);
}

void TransportController::setLoopEnabled(bool enabled) noexcept {
    loopEnabled_.store(enabled, std::memory_order_release);
}

bool TransportController::setLoopLengthBeats(double lengthBeats) noexcept {
    if (lengthBeats < 1.0) {
        return false;
    }
    loopRegionStartBeat_.store(0.0, std::memory_order_release);
    loopRegionEndBeat_.store(lengthBeats, std::memory_order_release);
    return true;
}

bool TransportController::setLoopRegion(double startBeat, double endBeat) noexcept {
    if (startBeat < 0.0 || endBeat - startBeat < 1.0) {
        return false;
    }
    loopRegionStartBeat_.store(startBeat, std::memory_order_release);
    loopRegionEndBeat_.store(endBeat, std::memory_order_release);
    return true;
}

} // namespace audioapp
