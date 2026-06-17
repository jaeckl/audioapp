#pragma once

#include <cstdint>

#include "audioapp/SamplerFilter.hpp"
#include "audioapp/SamplePlayback.hpp"

namespace audioapp {

static constexpr int kSubtractiveMaxVoices = 8;
static constexpr int kSubtractiveMaxUnison = 4;

/// Oscillator waveform: 0 sine, 1 tri, 2 saw, 3 square, 4 pulse.
enum class SubtractiveWave : int { Sine = 0, Tri = 1, Saw = 2, Square = 3, Pulse = 4 };

/// Osc mix: 0 mix, 1 neg, 2 am, 3 sign, 4 max.
enum class SubtractiveMixMode : int { Mix = 0, Neg = 1, Am = 2, Sign = 3, Max = 4 };

struct SubtractiveSynthParams {
    float gain = 1.0f;
    int osc1Wave = 2;
    int osc2Wave = 2;
    float osc1Shape = 0.5f;
    float osc2Shape = 0.5f;
    float osc1Octave = 0.5f;
    float osc1Semi = 0.0f;
    float osc1Detune = 0.5f;
    float osc2Octave = 0.5f;
    float osc2Semi = 0.0f;
    float osc2Detune = 0.5f;
    float osc1Level = 0.85f;
    float osc2Level = 0.5f;
    float oscMix = 0.37f;
    float noiseLevel = 0.0f;
    int oscMixMode = 0;
    float osc1Sync = 0.0f;
    float osc2Sync = 0.0f;
    float unisonVoices = 0.0f;
    float unisonDetune = 0.35f;
    int filterMode = 0;
    float filterCutoff = 0.75f;
    float filterQ = 0.2f;
    float filterEnvAmount = 0.5f;
    float filterAttack = 0.05f;
    float filterDecay = 0.35f;
    float filterSustain = 0.4f;
    float filterRelease = 0.45f;
    float ampAttack = 0.02f;
    float ampDecay = 0.25f;
    float ampSustain = 0.75f;
    float ampRelease = 0.35f;
    float glideMs = 0.0f;
    float velocitySensitivity = 1.0f;
};

struct SubtractiveVoiceRuntime {
    uint8_t active = 0;
    int pitch = 60;
    int noteKey = -1;
    float velocity = 100.0f;
    double startBeat = 0.0;
    double releaseBeat = -1.0;
    float osc1Phases[kSubtractiveMaxUnison]{};
    float osc2Phases[kSubtractiveMaxUnison]{};
    float currentHz = 440.0f;
    float targetHz = 440.0f;
    float noiseSeed = 0.123f;
    BiquadState filterState{};
};

struct SubtractiveSynthRuntime {
    SubtractiveVoiceRuntime voices[kSubtractiveMaxVoices]{};
    int stealIndex = 0;
};

struct SubtractiveMidiNoteRegion {
    int pitch = 60;
    int noteKey = 0;
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    double noteStartBeat = 0.0;
    double noteDurationBeats = 1.0;
    float velocity = 100.0f;
};

float subtractiveWaveSample(int wave, float phase) noexcept;

/// Continuous shape 0..1 morphs sine → tri → saw → square → pulse.
float subtractiveMorphWaveSample(float shape, float phase) noexcept;

int subtractiveUnisonCount(float normalized) noexcept;

float subtractiveOscPitchHz(int rootPitch,
                            float octaveNorm,
                            float semiNorm,
                            float detuneNorm) noexcept;

float subtractiveMixOscPair(float osc1, float osc2, int mixMode, float osc2Level) noexcept;

float subtractiveVoiceSample(SubtractiveVoiceRuntime& voice,
                             const SubtractiveSynthParams& params,
                             float ampGain,
                             float filterGain,
                             double sampleRate,
                             float glideCoeff) noexcept;

void mixSubtractiveMidiNotesBlock(float* monoOut,
                                  int numFrames,
                                  double sampleRate,
                                  int bpm,
                                  double playheadStartBeat,
                                  const SubtractiveMidiNoteRegion* notes,
                                  int noteCount,
                                  const SubtractiveSynthParams& params,
                                  SubtractiveSynthRuntime& runtime) noexcept;

void renderSubtractiveLiveVoice(float& mix,
                                SubtractiveVoiceRuntime& voice,
                                const SubtractiveSynthParams& params,
                                double sampleRate,
                                uint64_t sampleIndex,
                                uint64_t blockStartSample) noexcept;

} // namespace audioapp
