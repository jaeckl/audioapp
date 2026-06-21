#pragma once

#include <atomic>
#include <cmath>
#include <cstdint>

namespace audioapp {

static constexpr int kPreviewMaxVoices = 8;

struct PreviewVoiceState {
    std::atomic<bool> active{false};
    int pitch = 60;
    float velocity = 100.0f;
    double startBeat = 0.0;
    double durationBeats = 1.0;
    double phase = 0.0;
};

/// Polyphonic fallback sine oscillator for MIDI preview playback.
/// 8 voices with round-robin voice stealing. No JUCE dependency.
class FallbackPreviewOscillator {
public:
    void reset() noexcept;
    void noteOn(int pitch, float velocity, double startBeat, double durationBeats) noexcept;
    void noteOff(int pitch) noexcept;
    void allNotesOff() noexcept;
    void processBlock(float* monoOut, int numFrames, double sampleRate, double playheadBeat) noexcept;

private:
    PreviewVoiceState voices_[kPreviewMaxVoices];
    int stealIndex_ = 0;

    static float midiToHz(int pitch) noexcept {
        return 440.0f * std::pow(2.0f, (pitch - 69) / 12.0f);
    }
};

} // namespace audioapp