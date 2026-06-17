#pragma once

#include "audioapp/SamplerFilter.hpp"

namespace audioapp {

class SampleBank;

struct SampleClipPlaybackRegion {
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    const float* pcm = nullptr;
    int frameCount = 0;
    double sampleRate = 48000.0;
};

struct SamplerMidiNoteRegion {
    int pitch = 60;
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    double noteStartBeat = 0.0;
    double noteDurationBeats = 1.0;
    float velocity = 100.0f;
};

struct SamplerInstrumentPlayback {
    const float* pcm = nullptr;
    int frameCount = 0;
    double pcmSampleRate = 48000.0;
    float gain = 1.0f;
    int rootPitch = 60;
    float attack = 0.01f;
    float decay = 0.1f;
    float sustain = 1.0f;
    float release = 0.2f;
    float filterCutoff = 1.0f;
    float filterQ = 0.5f;
    int filterMode = 0;
    int trimStartFrame = 0;
    int trimEndFrame = 0;
    BiquadState* filterState = nullptr;
};

/// Maps UI-normalized ADSR (0..1) to seconds for envelope stages.
float adsrNormalizedToSeconds(float normalized, float maxSeconds) noexcept;

/// ADSR gain for one note at elapsed time since note-on (seconds).
float samplerAdsrGain(float elapsedSec,
                      float noteDurationSec,
                      float attackSec,
                      float decaySec,
                      float sustainLevel,
                      float releaseSec) noexcept;

bool isSamplerMidiNoteAudible(const SamplerMidiNoteRegion& note,
                              double beat,
                              int bpm,
                              float releaseSec,
                              double& elapsedSecondsOut) noexcept;

void mixSamplerMidiNotesBlock(float* monoOut,
                              int numFrames,
                              double sampleRate,
                              int bpm,
                              double playheadStartBeat,
                              const SamplerMidiNoteRegion* notes,
                              int noteCount,
                              const SamplerInstrumentPlayback& sampler);

void mixSampleRegionsBlock(float* monoOut,
                           int numFrames,
                           double sampleRate,
                           int bpm,
                           double playheadStartBeat,
                           const SampleClipPlaybackRegion* regions,
                           int regionCount);

} // namespace audioapp
