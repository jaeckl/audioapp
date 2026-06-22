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
    /// Stereo pan in [-1, +1]. 0 = centered; alternates per voice on noteOn
    /// so the chord spreads across the stereo field instead of sitting in
    /// the dead center (which the user perceived as "monophonic and mono").
    float pan = 0.0f;
    /// Time (in seconds) since this voice was triggered. Used for envelope.
    double elapsedSec = 0.0;
    /// True after noteOff is called: the voice is in release and its
    /// envelope decays from its current value to zero over [releaseSec].
    bool inRelease = false;
};

/// Short envelope (seconds) so a sustained preview note doesn't click at
/// the start/end. ~5ms attack, ~30ms release is enough to take the edge off
/// the bare sine without making short notes feel mushy.
static constexpr double kPreviewAttackSec = 0.005;
static constexpr double kPreviewReleaseSec = 0.030;

/// Polyphonic fallback sine oscillator for MIDI preview playback.
/// 8 voices with round-robin voice stealing, alternating L/R pan so the
/// chord sounds stereo instead of mono-summed. No JUCE dependency.
class FallbackPreviewOscillator {
public:
    void reset() noexcept;
    void noteOn(int pitch, float velocity, double startBeat, double durationBeats) noexcept;
    void noteOff(int pitch) noexcept;
    void allNotesOff() noexcept;
    void processBlock(float* monoOut, int numFrames,
                       double sampleRate, double playheadBeat) noexcept;
    /// Stereo version: writes per-voice panned output directly to left/right.
    /// Used when the preview output path is stereo (e.g. Android AAudio
    /// stereo stream).
    void processBlockStereo(float* leftOut, float* rightOut, int numFrames,
                            double sampleRate, double playheadBeat) noexcept;

private:
    PreviewVoiceState voices_[kPreviewMaxVoices];
    int stealIndex_ = 0;

    static float midiToHz(int pitch) noexcept {
        return 440.0f * std::pow(2.0f, (pitch - 69) / 12.0f);
    }

    /// Equal-power pan law: pan in [-1,+1] -> (gainL, gainR).
    static void panGains(float pan, float& gainL, float& gainR) noexcept {
        const float theta = (pan + 1.0f) * 0.7853981633974483f; // pi/4
        gainL = std::cos(theta);
        gainR = std::sin(theta);
    }
};

} // namespace audioapp