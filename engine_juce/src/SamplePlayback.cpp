#include "audioapp/SamplePlayback.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

namespace {

double beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0;
}

} // namespace

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

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);
        float mix = 0.0f;
        for (int noteIndex = 0; noteIndex < noteCount; ++noteIndex) {
            const auto& note = notes[noteIndex];
            if (!isSamplerMidiNoteActive(note, beat)) {
                continue;
            }
            const double elapsedBeats = samplerMidiNoteElapsedBeats(note, beat);
            const double elapsedSeconds = elapsedBeats * 60.0 / static_cast<double>(bpm);
            const double pitchRatio =
                std::pow(2.0, static_cast<double>(note.pitch - sampler.rootPitch) / 12.0);
            const double readPos = elapsedSeconds * sampler.pcmSampleRate * pitchRatio;
            if (readPos < 0.0 || readPos >= static_cast<double>(sampler.frameCount - 1)) {
                continue;
            }
            const int index = static_cast<int>(readPos);
            const float frac = static_cast<float>(readPos - static_cast<double>(index));
            const int next = std::min(index + 1, sampler.frameCount - 1);
            const float sample =
                sampler.pcm[index] * (1.0f - frac) + sampler.pcm[next] * frac;
            mix += sample * (note.velocity / 100.0f);
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
