#pragma once

#include "audioapp/MetallicNoiseSynth.hpp"

namespace audioapp {

struct PercussionMidiNoteRegion {
    int pitch = 42;
    int noteKey = 0;
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    double noteStartBeat = 0.0;
    double noteDurationBeats = 1.0;
    float velocity = 100.0f;
    bool loopContent = false;
    double contentLengthBeats = 4.0;
};

struct HihatGeneratorParams {
    float gain = 1.0f;
    float hihatPitch = 0.50f;
    float hihatColor = 0.68f;
    float hihatDecay = 0.28f;
    float hihatTightness = 0.72f;
    float hihatNoise = 0.34f;
    float hihatWidth = 0.25f;
    float hihatVelocity = 1.0f;
    float hihatKeyTrack = 0.0f;
};

struct RideGeneratorParams {
    float gain = 1.0f;
    float ridePitch = 0.50f;
    float rideBrightness = 0.62f;
    float rideDecay = 0.62f;
    float rideBell = 0.28f;
    float rideDamping = 0.35f;
    float rideWidth = 0.30f;
    float rideVelocity = 1.0f;
    float rideKeyTrack = 0.0f;
};

struct TomGeneratorParams {
    float gain = 1.0f;
    float tomPitch = 0.42f;
    float tomDecay = 0.42f;
    float tomBend = 0.38f;
    float tomBody = 0.72f;
    float tomAttack = 0.35f;
    float tomNoise = 0.16f;
    float tomVelocity = 1.0f;
    float tomKeyTrack = 0.0f;
};

struct RimshotGeneratorParams {
    float gain = 1.0f;
    float rimshotPitch = 0.52f;
    float rimshotDecay = 0.24f;
    float rimshotTone = 0.62f;
    float rimshotSnap = 0.74f;
    float rimshotBody = 0.38f;
    float rimshotVelocity = 1.0f;
    float rimshotKeyTrack = 0.0f;
};

struct MetallicPercussionVoiceRuntime : MetallicNoiseVoiceRuntime {
    float phase[6]{};
    float sampleL = 0.0f;
    float sampleR = 0.0f;
    float noiseState = 0.314159f;
    BiquadCoeffs bodyCoeffs{};
    BiquadCoeffs colorCoeffs{};
    BiquadState bodyL{}, bodyR{}, colorL{}, colorR{};
    float configuredA = -1.0f;
    float configuredRatio = -1.0f;
    float configuredSampleRate = 0.0f;
};

template <typename Voice>
struct DedicatedPercussionRuntime {
    Voice voice{};
    int lastNoteKey = -1;
};

using HihatVoiceRuntime = MetallicPercussionVoiceRuntime;
using RideVoiceRuntime = MetallicPercussionVoiceRuntime;
using TomVoiceRuntime = MetallicPercussionVoiceRuntime;
using RimshotVoiceRuntime = MetallicPercussionVoiceRuntime;
using HihatGeneratorRuntime = DedicatedPercussionRuntime<HihatVoiceRuntime>;
using RideGeneratorRuntime = DedicatedPercussionRuntime<RideVoiceRuntime>;
using TomGeneratorRuntime = DedicatedPercussionRuntime<TomVoiceRuntime>;
using RimshotGeneratorRuntime = DedicatedPercussionRuntime<RimshotVoiceRuntime>;

void triggerHihatVoice(HihatVoiceRuntime&, int pitch, float velocity) noexcept;
void triggerRideVoice(RideVoiceRuntime&, int pitch, float velocity) noexcept;
void triggerTomVoice(TomVoiceRuntime&, int pitch, float velocity) noexcept;
void triggerRimshotVoice(RimshotVoiceRuntime&, int pitch, float velocity) noexcept;

float hihatSampleL(HihatVoiceRuntime&, const HihatGeneratorParams&, double, float) noexcept;
float hihatSampleR(HihatVoiceRuntime&, const HihatGeneratorParams&, double, float) noexcept;
float rideSampleL(RideVoiceRuntime&, const RideGeneratorParams&, double, float) noexcept;
float rideSampleR(RideVoiceRuntime&, const RideGeneratorParams&, double, float) noexcept;
float tomSampleL(TomVoiceRuntime&, const TomGeneratorParams&, double, float) noexcept;
float tomSampleR(TomVoiceRuntime&, const TomGeneratorParams&, double, float) noexcept;
float rimshotSampleL(RimshotVoiceRuntime&, const RimshotGeneratorParams&, double, float) noexcept;
float rimshotSampleR(RimshotVoiceRuntime&, const RimshotGeneratorParams&, double, float) noexcept;

float hihatReleaseSeconds(const HihatGeneratorParams&) noexcept;
float rideReleaseSeconds(const RideGeneratorParams&) noexcept;
float tomReleaseSeconds(const TomGeneratorParams&) noexcept;
float rimshotReleaseSeconds(const RimshotGeneratorParams&) noexcept;

} // namespace audioapp
