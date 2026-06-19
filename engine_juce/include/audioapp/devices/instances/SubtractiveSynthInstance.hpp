#pragma once

#include "audioapp/SubtractiveSynth.hpp"

namespace audioapp {

struct SubtractiveSynthInstance {
    float gain = 1.0f;
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
    float preHpCutoff = 0.0f;
    float preHpRes = 0.2f;
    float preDrive = 0.0f;
    float mixFeedback = 0.0f;
    float globalPitch = 0.5f;
    float filterKeyTrack = 0.0f;
    float filterDrive = 0.0f;
    float filterShaper = 0.0f;
    float filterFm = 0.0f;
    int filterShaperMode = 1;
    float synthLegato = 0.0f;
    float synthMono = 0.0f;

    SubtractiveSynthParams toPlaybackParams() const {
        SubtractiveSynthParams params;
        params.gain = gain;
        params.osc1Shape = osc1Shape;
        params.osc2Shape = osc2Shape;
        params.osc1Octave = osc1Octave;
        params.osc1Semi = osc1Semi;
        params.osc1Detune = osc1Detune;
        params.osc2Octave = osc2Octave;
        params.osc2Semi = osc2Semi;
        params.osc2Detune = osc2Detune;
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
        params.preHpCutoff = preHpCutoff;
        params.preHpRes = preHpRes;
        params.preDrive = preDrive;
        params.mixFeedback = mixFeedback;
        params.globalPitch = globalPitch;
        params.filterKeyTrack = filterKeyTrack;
        params.filterDrive = filterDrive;
        params.filterShaper = filterShaper;
        params.filterFm = filterFm;
        params.filterShaperMode = filterShaperMode;
        params.synthLegato = synthLegato;
        params.synthMono = synthMono;
        return params;
    }
};

} // namespace audioapp
