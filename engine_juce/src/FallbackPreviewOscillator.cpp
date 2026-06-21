#include "audioapp/FallbackPreviewOscillator.hpp"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#include <cmath>
#include <cstring>

namespace audioapp {

void FallbackPreviewOscillator::reset() noexcept {
    allNotesOff();
    stealIndex_ = 0;
}

void FallbackPreviewOscillator::noteOn(int pitch, float velocity, double startBeat,
                                      double durationBeats) noexcept {
    // Look for an inactive voice first
    for (int i = 0; i < kPreviewMaxVoices; ++i) {
        if (!voices_[i].active.load(std::memory_order_relaxed)) {
            voices_[i].pitch = pitch;
            voices_[i].velocity = velocity;
            voices_[i].startBeat = startBeat;
            voices_[i].durationBeats = durationBeats;
            voices_[i].phase = 0.0;
            voices_[i].active.store(true, std::memory_order_release);
            return;
        }
    }

    // All voices active — steal the voice at stealIndex_ (round-robin)
    const int stolenIndex = stealIndex_;
    voices_[stolenIndex].pitch = pitch;
    voices_[stolenIndex].velocity = velocity;
    voices_[stolenIndex].startBeat = startBeat;
    voices_[stolenIndex].durationBeats = durationBeats;
    voices_[stolenIndex].phase = 0.0;
    voices_[stolenIndex].active.store(true, std::memory_order_release);

    stealIndex_ = (stealIndex_ + 1) % kPreviewMaxVoices;
}

void FallbackPreviewOscillator::noteOff(int pitch) noexcept {
    for (int i = 0; i < kPreviewMaxVoices; ++i) {
        if (voices_[i].active.load(std::memory_order_relaxed) && voices_[i].pitch == pitch) {
            voices_[i].active.store(false, std::memory_order_release);
            return;
        }
    }
}

void FallbackPreviewOscillator::allNotesOff() noexcept {
    for (int i = 0; i < kPreviewMaxVoices; ++i) {
        voices_[i].active.store(false, std::memory_order_release);
    }
}

void FallbackPreviewOscillator::processBlock(float* monoOut, int numFrames,
                                              double sampleRate,
                                              double /*playheadBeat*/) noexcept {
    if (monoOut == nullptr || numFrames <= 0) {
        return;
    }

    for (int frame = 0; frame < numFrames; ++frame) {
        float sample = 0.0f;
        for (int i = 0; i < kPreviewMaxVoices; ++i) {
            if (!voices_[i].active.load(std::memory_order_relaxed)) {
                continue;
            }

            const float freq = midiToHz(voices_[i].pitch);
            const float amp = voices_[i].velocity / 127.0f;
            sample += amp * std::sin(static_cast<float>(voices_[i].phase));

            voices_[i].phase += 2.0 * M_PI * freq / sampleRate;
            // Keep phase bounded to avoid precision drift
            if (voices_[i].phase > 2.0 * M_PI) {
                voices_[i].phase -= 2.0 * M_PI;
            }
        }
        monoOut[frame] += sample;
    }
}

} // namespace audioapp