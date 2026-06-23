#pragma once

#include <cstdint>

namespace audioapp {

struct KickGeneratorParams {
    float gain = 1.0f;
    float kickModel = 0.0f;
    float kickPitch = 0.55f;
    float kickPunch = 0.60f;
    float kickDecay = 0.50f;
    float kickClick = 0.35f;
    float kickTone = 0.50f;
    float kickVelocity = 1.0f;
    float kickKeyTrack = 1.0f;
};

struct KickVoiceRuntime {
    uint8_t active = 0;
    int pitch = 36;
    float velocity = 100.0f;
    float phase = 0.0f;
    double elapsedSec = 0.0;
    float noiseSeed = 0.123f;
};

struct KickGeneratorRuntime {
    KickVoiceRuntime voice{};
    int lastNoteKey = -1;
};

struct KickMidiNoteRegion {
    int pitch = 36;
    int noteKey = 0;
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    double noteStartBeat = 0.0;
    double noteDurationBeats = 1.0;
    float velocity = 100.0f;
};

float drumMidiKeyTrackRatio(int pitch, int referencePitch, float keyTrackNorm) noexcept;

float kickGeneratorSample(KickVoiceRuntime& voice,
                          const KickGeneratorParams& params,
                          double sampleRate,
                          float velocityGain) noexcept;

int kickModelIndex(float kickModel) noexcept;

void triggerKickVoice(KickVoiceRuntime& voice, int pitch, float velocity) noexcept;

float normalizedToAmpDecaySec(float normalized) noexcept;

} // namespace audioapp