#include "audioapp/SamplePlaybackAlgorithm.hpp"

#include "audioapp/SamplerFilter.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

namespace {

static inline float safe_clamp(float v, float lo, float hi) noexcept {
    if (!std::isfinite(v)) return lo;
    return std::clamp(v, lo, hi);
}

double beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0;
}

} // namespace

double samplerPitchRatio(int notePitch, int rootPitch, float rootFineTuneCents) noexcept {
    const double semitones = static_cast<double>(notePitch - rootPitch)
        + static_cast<double>(safe_clamp(rootFineTuneCents, -100.0f, 100.0f)) / 100.0;
    return std::pow(2.0, semitones / 12.0);
}

float adsrNormalizedToSeconds(float normalized, float maxSeconds) noexcept {
    const float clamped = safe_clamp(normalized, 0.0f, 1.0f);
    return 0.001f + clamped * maxSeconds;
}

float samplerFilterCutoffHz(const float filterCutoffNorm,
                            const float filterEnvGain,
                            const float filterEnvAmount) noexcept {
    const float baseCutoff = normalizedCutoffToHz(filterCutoffNorm);
    const float amount = safe_clamp(filterEnvAmount, 0.0f, 1.0f);
    return safe_clamp(baseCutoff * (1.0f + filterEnvGain * amount * 4.0f), 20.0f, 20000.0f);
}

float processSamplerFilteredSample(const float sample,
                                   BiquadState& filterState,
                                   const int filterMode,
                                   const float outputSampleRate,
                                   const float filterCutoffNorm,
                                   const float filterQNorm,
                                   const float filterEnvGain,
                                   const float filterEnvAmount) noexcept {
    const float rawCutoffHz =
        samplerFilterCutoffHz(filterCutoffNorm, filterEnvGain, filterEnvAmount);
    if (filterState.lastCutoffHz <= 0.0f) {
        filterState.lastCutoffHz = rawCutoffHz;
    } else {
        filterState.lastCutoffHz += (rawCutoffHz - filterState.lastCutoffHz) * 0.05f;
    }
    const float cutoffHz = safe_clamp(filterState.lastCutoffHz, 20.0f, 20000.0f);
    BiquadCoeffs coeffs{};
    cookSamplerBiquad(coeffs,
                      filterMode,
                      outputSampleRate,
                      cutoffHz,
                      normalizedQToValue(filterQNorm));
    return processBiquadSample(sample, coeffs, filterState);
}

float samplerAdsrGain(float elapsedSec,
                      float noteDurationSec,
                      float attackSec,
                      float decaySec,
                      float sustainLevel,
                      float releaseSec) noexcept {
    if (elapsedSec < 0.0f) {
        return 0.0f;
    }

    const float sustain = safe_clamp(sustainLevel, 0.0f, 1.0f);

    if (elapsedSec < attackSec) {
        return attackSec > 0.0f ? elapsedSec / attackSec : 1.0f;
    }
    elapsedSec -= attackSec;

    if (elapsedSec < decaySec) {
        if (decaySec <= 0.0f) {
            return sustain;
        }
        return 1.0f - (1.0f - sustain) * (elapsedSec / decaySec);
    }
    elapsedSec -= decaySec;

    if (elapsedSec < noteDurationSec) {
        return sustain;
    }

    const float releaseElapsed = elapsedSec - noteDurationSec;
    if (releaseElapsed < releaseSec) {
        return releaseSec > 0.0f ? sustain * (1.0f - releaseElapsed / releaseSec) : 0.0f;
    }
    return 0.0f;
}

bool isSamplerMidiNoteActive(const SamplerMidiNoteRegion& note, double beat) {
    if (beat < note.clipStartBeat || beat >= note.clipStartBeat + note.clipLengthBeats) {
        return false;
    }
    const double posInClip = beat - note.clipStartBeat;
    const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
    return loopedBeat >= note.noteStartBeat
        && loopedBeat < (note.noteStartBeat + note.noteDurationBeats);
}

double samplerMidiNoteElapsedBeats(const SamplerMidiNoteRegion& note, double beat) {
    const double posInClip = beat - note.clipStartBeat;
    const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
    return loopedBeat - note.noteStartBeat;
}

bool computeSamplerReadPosition(const int playbackMode,
                                const int trimStartFrame,
                                const int trimEndFrame,
                                const int regionStartFrame,
                                const int regionEndFrame,
                                const double elapsedSec,
                                const double pcmSampleRate,
                                const double pitchRatio,
                                double& readPosOut) noexcept {
    if (trimEndFrame <= trimStartFrame + 1 || pcmSampleRate <= 0.0 || elapsedSec < 0.0) {
        return false;
    }

    const bool hasRegion =
        regionEndFrame > regionStartFrame && regionEndFrame > trimStartFrame;
    const int loopStart = hasRegion ? regionStartFrame : trimStartFrame;
    const int loopEnd = hasRegion ? regionEndFrame : trimEndFrame;
    const int loopLen = loopEnd - loopStart;
    const double rateProgress = elapsedSec * pcmSampleRate * pitchRatio;

    switch (playbackMode) {
    case 1: // loop
        if (loopLen <= 1) {
            return false;
        }
        readPosOut =
            static_cast<double>(loopStart) + std::fmod(rateProgress, static_cast<double>(loopLen));
        return true;
    case 2: { // reverse one-shot
        readPosOut = static_cast<double>(trimEndFrame - 1) - rateProgress;
        return readPosOut >= static_cast<double>(trimStartFrame);
    }
    default: { // one-shot forward
        readPosOut = static_cast<double>(trimStartFrame) + rateProgress;
        return readPosOut < static_cast<double>(trimEndFrame - 1);
    }
    }
}

void mixSampleRegionsBlock(float* monoOut,
                           int numFrames,
                           double sampleRate,
                           int bpm,
                           double playheadStartBeat,
                           const SampleClipPlaybackRegion* regions,
                           int regionCount) {
    if (monoOut == nullptr || numFrames <= 0 || regions == nullptr || regionCount <= 0 || bpm <= 0) {
        return;
    }

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);
        float mix = 0.0f;
        for (int regionIndex = 0; regionIndex < regionCount; ++regionIndex) {
            const auto& region = regions[regionIndex];
            if (region.pcm == nullptr || region.frameCount <= 0 || region.clipLengthBeats <= 0.0) {
                continue;
            }
            const double clipEnd = region.clipStartBeat + region.clipLengthBeats;
            if (beat < region.clipStartBeat || beat >= clipEnd) {
                continue;
            }
            const double localBeat = beat - region.clipStartBeat;
            const double progress = localBeat / region.clipLengthBeats;
            const double readPos = progress * static_cast<double>(region.frameCount);
            const int index = static_cast<int>(readPos);
            const float frac = static_cast<float>(readPos - static_cast<double>(index));
            const int next = std::min(index + 1, region.frameCount - 1);
            const float sample =
                region.pcm[index] * (1.0f - frac) + region.pcm[next] * frac;
            mix += sample;
        }
        monoOut[frame] += mix;
    }
}

} // namespace audioapp