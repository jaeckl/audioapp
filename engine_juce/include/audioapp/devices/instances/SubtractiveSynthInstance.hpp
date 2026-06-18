#pragma once

#include "audioapp/DeviceState.hpp"
#include "audioapp/SubtractiveSynth.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

namespace audioapp {

struct SubtractiveSynthInstance {
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
    float osc1Sync = 0.0f;
    float osc2Sync = 0.0f;
    float noiseLevel = 0.0f;
    int oscMixMode = 0;
    float unisonVoices = 0.0f;
    float unisonDetune = 0.35f;
    float filterMode = 0;
    float filterCutoff = 1.0f;
    float filterQ = 0.35f;
    float filterEnvAmount = 0.5f;
    float filterAttack = 0.05f;
    float filterDecay = 0.35f;
    float filterSustain = 0.4f;
    float filterRelease = 0.45f;
    float ampAttack = 0.01f;
    float ampDecay = 0.3f;
    float ampSustain = 0.7f;
    float ampRelease = 0.4f;
    float glideMs = 0.0f;
    float velocitySensitivity = 1.0f;

    static SubtractiveSynthInstance fromState(const DeviceState& state) {
        SubtractiveSynthInstance instance;
        instance.gain = state.gain;
        instance.osc1Wave = state.osc1Wave;
        instance.osc2Wave = state.osc2Wave;
        instance.osc1Shape = state.osc1Shape;
        instance.osc2Shape = state.osc2Shape;
        instance.osc1Octave = state.osc1Octave;
        instance.osc1Semi = state.osc1Semi;
        instance.osc1Detune = state.osc1Detune;
        instance.osc2Octave = state.osc2Octave;
        instance.osc2Semi = state.osc2Semi;
        instance.osc2Detune = state.osc2Detune;
        instance.osc1Level = state.osc1Level;
        instance.osc2Level = state.osc2Level;
        instance.oscMix = state.oscMix;
        instance.osc1Sync = state.osc1Sync;
        instance.osc2Sync = state.osc2Sync;
        instance.noiseLevel = state.noiseLevel;
        instance.oscMixMode = state.oscMixMode;
        instance.unisonVoices = state.unisonVoices;
        instance.unisonDetune = state.unisonDetune;
        instance.filterMode = static_cast<float>(state.filterMode);
        instance.filterCutoff = state.filterCutoff;
        instance.filterQ = state.filterQ;
        instance.filterEnvAmount = state.filterEnvAmount;
        instance.filterAttack = state.filterAttack;
        instance.filterDecay = state.filterDecay;
        instance.filterSustain = state.filterSustain;
        instance.filterRelease = state.filterRelease;
        instance.ampAttack = state.attack;
        instance.ampDecay = state.decay;
        instance.ampSustain = state.sustain;
        instance.ampRelease = state.release;
        instance.glideMs = state.glideMs;
        instance.velocitySensitivity = state.velocitySensitivity;
        return instance;
    }

    void applyTo(DeviceState& state) const {
        state.type = device_types::kSubtractiveSynth;
        state.gain = gain;
        state.osc1Wave = osc1Wave;
        state.osc2Wave = osc2Wave;
        state.osc1Shape = osc1Shape;
        state.osc2Shape = osc2Shape;
        state.osc1Octave = osc1Octave;
        state.osc1Semi = osc1Semi;
        state.osc1Detune = osc1Detune;
        state.osc2Octave = osc2Octave;
        state.osc2Semi = osc2Semi;
        state.osc2Detune = osc2Detune;
        state.osc1Level = osc1Level;
        state.osc2Level = osc2Level;
        state.oscMix = oscMix;
        state.osc1Sync = osc1Sync;
        state.osc2Sync = osc2Sync;
        state.noiseLevel = noiseLevel;
        state.oscMixMode = oscMixMode;
        state.unisonVoices = unisonVoices;
        state.unisonDetune = unisonDetune;
        state.filterMode = static_cast<int>(filterMode);
        state.filterCutoff = filterCutoff;
        state.filterQ = filterQ;
        state.filterEnvAmount = filterEnvAmount;
        state.filterAttack = filterAttack;
        state.filterDecay = filterDecay;
        state.filterSustain = filterSustain;
        state.filterRelease = filterRelease;
        state.attack = ampAttack;
        state.decay = ampDecay;
        state.sustain = ampSustain;
        state.release = ampRelease;
        state.glideMs = glideMs;
        state.velocitySensitivity = velocitySensitivity;
    }

    SubtractiveSynthParams toPlaybackParams() const {
        SubtractiveSynthParams params;
        params.gain = gain;
        params.osc1Wave = osc1Wave;
        params.osc2Wave = osc2Wave;
        params.osc1Shape = osc1Shape;
        params.osc2Shape = osc2Shape;
        params.osc1Octave = osc1Octave;
        params.osc1Semi = osc1Semi;
        params.osc1Detune = osc1Detune;
        params.osc2Octave = osc2Octave;
        params.osc2Semi = osc2Semi;
        params.osc2Detune = osc2Detune;
        params.osc1Level = osc1Level;
        params.osc2Level = osc2Level;
        params.oscMix = oscMix;
        params.osc1Sync = osc1Sync;
        params.osc2Sync = osc2Sync;
        params.noiseLevel = noiseLevel;
        params.oscMixMode = oscMixMode;
        params.unisonVoices = unisonVoices;
        params.unisonDetune = unisonDetune;
        params.filterMode = static_cast<int>(filterMode);
        params.filterCutoff = filterCutoff;
        params.filterQ = filterQ;
        params.filterEnvAmount = filterEnvAmount;
        params.filterAttack = filterAttack;
        params.filterDecay = filterDecay;
        params.filterSustain = filterSustain;
        params.filterRelease = filterRelease;
        params.ampAttack = ampAttack;
        params.ampDecay = ampDecay;
        params.ampSustain = ampSustain;
        params.ampRelease = ampRelease;
        params.glideMs = glideMs;
        params.velocitySensitivity = velocitySensitivity;
        return params;
    }
};

} // namespace audioapp
