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
    float rootFineTune = 0.0f;
    float attack = 0.01f;
    float decay = 0.1f;
    float sustain = 1.0f;
    float release = 0.2f;
    float filterCutoff = 1.0f;
    float filterQ = 0.5f;
    int filterMode = 0;
    float filterEnvAmount = 0.5f;
    float filterAttack = 0.05f;
    float filterDecay = 0.35f;
    float filterSustain = 0.4f;
    float filterRelease = 0.45f;
    int trimStartFrame = 0;
    int trimEndFrame = 0;
    int regionStartFrame = 0;
    int regionEndFrame = 0;
    int playbackMode = 0;
    BiquadState* filterState = nullptr;
    BiquadState* noteFilterStates = nullptr;
    int noteFilterStateCount = 0;
};

/// Direct-renderer entry point. Called by the arrangement playback path
/// (SamplerProcessor) and by the preset preview in EngineHost_commands.cpp.
void mixSamplerMidiNotesBlock(float* monoOut,
                              int numFrames,
                              double sampleRate,
                              int bpm,
                              double playheadStartBeat,
                              const SamplerMidiNoteRegion* notes,
                              int noteCount,
                              const SamplerInstrumentPlayback& sampler);

/// Cutoff Hz with filter-envelope depth applied (matches subtractive synth FEG).
float samplerFilterCutoffHz(float filterCutoffNorm,
                            float filterEnvGain,
                            float filterEnvAmount) noexcept;

float processSamplerFilteredSample(float sample,
                                   BiquadState& filterState,
                                   int filterMode,
                                   float outputSampleRate,
                                   float filterCutoffNorm,
                                   float filterQNorm,
                                   float filterEnvGain,
                                   float filterEnvAmount) noexcept;

/// Pitch ratio from MIDI note, root, and fine tune (cents, ±100).
double samplerPitchRatio(int notePitch, int rootPitch, float rootFineTuneCents) noexcept;

/// 0 = one-shot, 1 = loop, 2 = reverse one-shot.
bool computeSamplerReadPosition(int playbackMode,
                                int trimStartFrame,
                                int trimEndFrame,
                                int regionStartFrame,
                                int regionEndFrame,
                                double elapsedSec,
                                double pcmSampleRate,
                                double pitchRatio,
                                double& readPosOut) noexcept;

/// Maps UI-normalized ADSR (0..1) to seconds for envelope stages.
float adsrNormalizedToSeconds(float normalized, float maxSeconds) noexcept;

/// ADSR gain for one note at elapsed time since note-on (seconds).
float samplerAdsrGain(float elapsedSec,
                      float noteDurationSec,
                      float attackSec,
                      float decaySec,
                      float sustainLevel,
                      float releaseSec) noexcept;

void mixSampleRegionsBlock(float* monoOut,
                           int numFrames,
                           double sampleRate,
                           int bpm,
                           double playheadStartBeat,
                           const SampleClipPlaybackRegion* regions,
                           int regionCount);

} // namespace audioapp