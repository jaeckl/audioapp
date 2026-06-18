#include "audioapp/SamplePlayback.hpp"

#include "audioapp/SamplerFilter.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

namespace {

double beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0;
}

} // namespace

float adsrNormalizedToSeconds(float normalized, float maxSeconds) noexcept {
    const float clamped = std::clamp(normalized, 0.0f, 1.0f);
    return 0.001f + clamped * maxSeconds;
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

    const float sustain = std::clamp(sustainLevel, 0.0f, 1.0f);

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

bool isSamplerMidiNoteAudible(const SamplerMidiNoteRegion& note,
                              double beat,
                              int bpm,
                              float releaseSec,
                              double& elapsedSecondsOut) noexcept {
    if (beat < note.clipStartBeat || beat >= note.clipStartBeat + note.clipLengthBeats || bpm <= 0) {
        return false;
    }

    const double posInClip = beat - note.clipStartBeat;
    const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
    const double noteStart = note.noteStartBeat;
    const double noteEnd = note.noteStartBeat + note.noteDurationBeats;
    const double releaseBeats =
        static_cast<double>(releaseSec) * static_cast<double>(bpm) / 60.0;

    if (loopedBeat < noteStart) {
        return false;
    }

    const double elapsedBeats = loopedBeat - noteStart;
    elapsedSecondsOut = elapsedBeats * 60.0 / static_cast<double>(bpm);

    if (loopedBeat < noteEnd) {
        return true;
    }
    return loopedBeat < noteEnd + releaseBeats;
}

double samplerMidiNoteElapsedBeats(const SamplerMidiNoteRegion& note, double beat) {
    const double posInClip = beat - note.clipStartBeat;
    const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
    return loopedBeat - note.noteStartBeat;
}

void mixSamplerMidiNotesBlock(float* monoOut,
                              int numFrames,
                              double sampleRate,
                              int bpm,
                              double playheadStartBeat,
                              const SamplerMidiNoteRegion* notes,
                              int noteCount,
                              const SamplerInstrumentPlayback& sampler) {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }
    if (sampler.pcm == nullptr || sampler.frameCount <= 0 || sampler.pcmSampleRate <= 0.0) {
        return;
    }

    const float attackSec = adsrNormalizedToSeconds(sampler.attack, 2.0f);
    const float decaySec = adsrNormalizedToSeconds(sampler.decay, 2.0f);
    const float releaseSec = adsrNormalizedToSeconds(sampler.release, 3.0f);
    const float sustainLevel = std::clamp(sampler.sustain, 0.0f, 1.0f);

    BiquadCoeffs filterCoeffs{};
    const bool useFilter = sampler.filterState != nullptr;
    if (useFilter) {
        cookSamplerBiquad(filterCoeffs,
                          sampler.filterMode,
                          static_cast<float>(sampleRate),
                          normalizedCutoffToHz(sampler.filterCutoff),
                          normalizedQToValue(sampler.filterQ));
    }

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);
        float mix = 0.0f;
        for (int noteIndex = 0; noteIndex < noteCount; ++noteIndex) {
            const auto& note = notes[noteIndex];
            double elapsedSeconds = 0.0;
            if (!isSamplerMidiNoteAudible(note, beat, bpm, releaseSec, elapsedSeconds)) {
                continue;
            }

            const float noteDurationSec =
                static_cast<float>(note.noteDurationBeats * 60.0 / static_cast<double>(bpm));
            const float envGain = samplerAdsrGain(elapsedSeconds,
                                                  noteDurationSec,
                                                  attackSec,
                                                  decaySec,
                                                  sustainLevel,
                                                  releaseSec);
            if (envGain <= 0.0f) {
                continue;
            }

            const int startFrame = sampler.trimStartFrame;
            const int endFrame =
                sampler.trimEndFrame > startFrame ? sampler.trimEndFrame : sampler.frameCount;
            if (endFrame - startFrame <= 1) {
                continue;
            }

            const double pitchRatio =
                std::pow(2.0, static_cast<double>(note.pitch - sampler.rootPitch) / 12.0);

            // Determine the loop region within the trimmed sample (valid when regionEndFrame > 0)
            const bool hasRegion = sampler.regionEndFrame > 0 && sampler.regionEndFrame > sampler.regionStartFrame;
            const int loopStart = hasRegion ? sampler.regionStartFrame : startFrame;
            const int loopEnd = hasRegion ? sampler.regionEndFrame : endFrame;
            const int loopLen = loopEnd - loopStart;

            double readPos;
            if (hasRegion && loopLen > 1) {
                // Loop playback within the selected region
                const double regionProgress = elapsedSeconds * sampler.pcmSampleRate * pitchRatio;
                readPos = static_cast<double>(loopStart) + std::fmod(regionProgress, static_cast<double>(loopLen));
            } else {
                // No region set — linear playback (original behavior)
                readPos = static_cast<double>(startFrame) + elapsedSeconds * sampler.pcmSampleRate * pitchRatio;
                if (readPos < static_cast<double>(startFrame) ||
                    readPos >= static_cast<double>(endFrame - 1)) {
                    continue;
                }
            }
            const int index = static_cast<int>(readPos);
            const float frac = static_cast<float>(readPos - static_cast<double>(index));
            const int next = std::min(index + 1, sampler.frameCount - 1);
            const float sample =
                sampler.pcm[index] * (1.0f - frac) + sampler.pcm[next] * frac;
            mix += sample * (note.velocity / 100.0f) * envGain;
        }
        if (useFilter) {
            mix = processBiquadSample(mix, filterCoeffs, *sampler.filterState);
        }
        monoOut[frame] += mix * sampler.gain;
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
