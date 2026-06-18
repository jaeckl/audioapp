#pragma once

#include <string>

namespace audioapp {

/// Serializable device DTO shared by project snapshots and device type factories.
struct DeviceState {
    std::string id;
    std::string type;
    float frequencyHz = 440.0f;
    float gain = 1.0f;
    float pan = 0.5f;
    std::string sampleId;
    float attack = 0.01f;
    float decay = 0.3f;
    float sustain = 0.7f;
    float release = 0.4f;
    float filterCutoff = 1.0f;
    float filterQ = 0.35f;
    int filterMode = 0;
    float trimStartSec = 0.0f;
    float trimEndSec = 0.0f;
    float regionStartSec = 0.0f;
    float regionEndSec = 0.0f;
    bool bypassed = false;
    float osc1Shape = 0.5f;
    float osc2Shape = 0.5f;
    float osc1Octave = 0.5f;
    float osc1Semi = 0.0f;
    float osc1Detune = 0.5f;
    float osc2Octave = 0.5f;
    float osc2Semi = 0.0f;
    float osc2Detune = 0.5f;
    float oscMix = 0.37f;
    float osc1Sync = 0.0f;
    float osc2Sync = 0.0f;
    float noiseLevel = 0.0f;
    int oscMixMode = 0;
    float unisonVoices = 0.0f;
    float unisonDetune = 0.35f;
    float filterEnvAmount = 0.5f;
    float filterAttack = 0.05f;
    float filterDecay = 0.35f;
    float filterSustain = 0.4f;
    float filterRelease = 0.45f;
    float glideMs = 0.0f;
    float velocitySensitivity = 1.0f;
    float kickPitch = 0.55f;
    float kickPunch = 0.60f;
    float kickDecay = 0.50f;
    float kickClick = 0.35f;
    float kickTone = 0.50f;
    float kickVelocity = 1.0f;
    float snareBody = 0.55f;
    float snareTune = 0.50f;
    float snareSnares = 0.60f;
    float snareSnap = 0.40f;
    float snareDecay = 0.50f;
    float snareVelocity = 1.0f;
};

} // namespace audioapp
