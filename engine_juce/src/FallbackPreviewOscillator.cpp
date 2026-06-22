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
    // Reuse a voice that's already playing this pitch (legato: the new note
    // is just a continuation of the held one). This prevents overlapping
    // same-pitch notes from stacking voices and getting cut off by the
    // matching noteOff.
    for (int i = 0; i < kPreviewMaxVoices; ++i) {
        if (voices_[i].active.load(std::memory_order_relaxed) &&
            voices_[i].pitch == pitch) {
            voices_[i].velocity = velocity;
            voices_[i].startBeat = startBeat;
            voices_[i].durationBeats = durationBeats;
            voices_[i].phase = 0.0;
            voices_[i].elapsedSec = 0.0;
            voices_[i].inRelease = false;
            return;
        }
    }

    // Pick the pan for this voice: alternate L/R between consecutive
    // noteOn calls so chords spread across the stereo field instead of
    // stacking dead-center. stealIndex_ doubles as the "next pan side"
    // counter and is bumped regardless of whether we stole or allocated.
    const int panSide = stealIndex_;
    const float pan = (panSide & 1) ? 0.55f : -0.55f;

    // Look for an inactive voice first
    for (int i = 0; i < kPreviewMaxVoices; ++i) {
        if (!voices_[i].active.load(std::memory_order_relaxed)) {
            voices_[i].pitch = pitch;
            voices_[i].velocity = velocity;
            voices_[i].startBeat = startBeat;
            voices_[i].durationBeats = durationBeats;
            voices_[i].phase = 0.0;
            voices_[i].pan = pan;
            voices_[i].elapsedSec = 0.0;
            voices_[i].inRelease = false;
            voices_[i].active.store(true, std::memory_order_release);
            stealIndex_ = (stealIndex_ + 1) % kPreviewMaxVoices;
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
    voices_[stolenIndex].pan = pan;
    voices_[stolenIndex].elapsedSec = 0.0;
    voices_[stolenIndex].inRelease = false;
    voices_[stolenIndex].active.store(true, std::memory_order_release);

    stealIndex_ = (stealIndex_ + 1) % kPreviewMaxVoices;
}

void FallbackPreviewOscillator::noteOff(int pitch) noexcept {
    // Release the FIRST voice with this pitch that's not already in
    // release. Releasing every voice (including ones that are already
    // releasing from a previous noteOff) would cut off the new attack
    // triggered by a re-note at the same pitch.
    for (int i = 0; i < kPreviewMaxVoices; ++i) {
        if (voices_[i].active.load(std::memory_order_relaxed) &&
            voices_[i].pitch == pitch && !voices_[i].inRelease) {
            // Move the voice into its release tail so the envelope can
            // ramp to zero instead of cutting off mid-sine (which clicks).
            voices_[i].inRelease = true;
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

    const double invSampleRate = 1.0 / sampleRate;

    for (int frame = 0; frame < numFrames; ++frame) {
        float sample = 0.0f;
        for (int i = 0; i < kPreviewMaxVoices; ++i) {
            if (!voices_[i].active.load(std::memory_order_relaxed)) {
                continue;
            }

            const float freq = midiToHz(voices_[i].pitch);
            const float amp = voices_[i].velocity / 127.0f;

            // Envelope: linear ramp on attack (0..attackSec) then sustain at 1.0;
            // when noteOff fires, ramp from current value down to 0 over releaseSec.
            float env = 1.0f;
            if (voices_[i].inRelease) {
                if (voices_[i].elapsedSec >= kPreviewReleaseSec) {
                    // Release finished — silence the voice.
                    voices_[i].active.store(false, std::memory_order_release);
                    continue;
                }
                env = 1.0f - static_cast<float>(voices_[i].elapsedSec / kPreviewReleaseSec);
                if (env < 0.0f) env = 0.0f;
            } else if (voices_[i].elapsedSec < kPreviewAttackSec) {
                env = static_cast<float>(voices_[i].elapsedSec / kPreviewAttackSec);
            }

            // Equal-power stereo sum to mono. Voices alternate pan so
            // a chord doesn't all cancel into dead-center. -6dB per voice
            // headroom prevents chord clipping (see processBlockStereo).
            float gainL, gainR;
            panGains(voices_[i].pan, gainL, gainR);
            constexpr float kVoiceHeadroom = 0.5f;
            const float s = amp * env * kVoiceHeadroom
                          * std::sin(static_cast<float>(voices_[i].phase));
            sample += s * (gainL + gainR) * 0.5f; // preserve perceived loudness

            voices_[i].phase += 2.0 * M_PI * freq / sampleRate;
            // Keep phase bounded to avoid precision drift
            if (voices_[i].phase > 2.0 * M_PI) {
                voices_[i].phase -= 2.0 * M_PI;
            }
            voices_[i].elapsedSec += invSampleRate;
        }
        monoOut[frame] += sample;
    }
}

void FallbackPreviewOscillator::processBlockStereo(float* leftOut, float* rightOut,
                                                   int numFrames,
                                                   double sampleRate,
                                                   double /*playheadBeat*/) noexcept {
    if (leftOut == nullptr || rightOut == nullptr || numFrames <= 0) {
        return;
    }

    const double invSampleRate = 1.0 / sampleRate;

    for (int frame = 0; frame < numFrames; ++frame) {
        float sampleL = 0.0f;
        float sampleR = 0.0f;
        for (int i = 0; i < kPreviewMaxVoices; ++i) {
            if (!voices_[i].active.load(std::memory_order_relaxed)) {
                continue;
            }

            const float freq = midiToHz(voices_[i].pitch);
            const float amp = voices_[i].velocity / 127.0f;

            float env = 1.0f;
            if (voices_[i].inRelease) {
                if (voices_[i].elapsedSec >= kPreviewReleaseSec) {
                    voices_[i].active.store(false, std::memory_order_release);
                    continue;
                }
                env = 1.0f - static_cast<float>(voices_[i].elapsedSec / kPreviewReleaseSec);
                if (env < 0.0f) env = 0.0f;
            } else if (voices_[i].elapsedSec < kPreviewAttackSec) {
                env = static_cast<float>(voices_[i].elapsedSec / kPreviewAttackSec);
            }

            float gainL, gainR;
            panGains(voices_[i].pan, gainL, gainR);
            // -6dB per voice headroom so an 8-voice chord doesn't clip the
            // output (single voice peaks ~0.35, 4-voice chord peaks ~1.0,
            // 8-voice chord clips slightly but rarely audible).
            constexpr float kVoiceHeadroom = 0.5f;
            const float s = amp * env * kVoiceHeadroom
                          * std::sin(static_cast<float>(voices_[i].phase));
            sampleL += s * gainL;
            sampleR += s * gainR;

            voices_[i].phase += 2.0 * M_PI * freq / sampleRate;
            if (voices_[i].phase > 2.0 * M_PI) {
                voices_[i].phase -= 2.0 * M_PI;
            }
            voices_[i].elapsedSec += invSampleRate;
        }
        leftOut[frame] += sampleL;
        rightOut[frame] += sampleR;
    }
}

} // namespace audioapp