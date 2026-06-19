#include "audioapp/DeviceChain.hpp"

#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/MasterMix.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/SamplePlayback.hpp"
#include "audioapp/SubtractiveSynth.hpp"
#include "audioapp/KickGenerator.hpp"
#include "audioapp/SnareGenerator.hpp"
#include "audioapp/ClapGenerator.hpp"
#include "audioapp/CymbalGenerator.hpp"
#include "audioapp/CrashGenerator.hpp"
#include "audioapp/DynamicsProcessor.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

constexpr int kScratchFrames = 4096;

float stereoBlockPeak(const float* left, const float* right, int frameCount) noexcept {
    float peak = 0.0f;
    for (int i = 0; i < frameCount; ++i) {
        peak = std::max(peak, std::max(std::abs(left[i]), std::abs(right[i])));
    }
    return peak;
}

void publishDynamicsMeters(const DeviceNodePlayback& node,
                           const DynamicsRuntime& runtime,
                           float inputPeak,
                           DeviceMeterAtomic* deviceMeters,
                           int maxDeviceMeters) noexcept {
    if (deviceMeters == nullptr || node.meterSlot < 0 || node.meterSlot >= maxDeviceMeters) {
        return;
    }
    deviceMeters[node.meterSlot].gainReductionDb.store(runtime.gainReductionDb,
                                                       std::memory_order_relaxed);
    deviceMeters[node.meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
}

bool isMidiNoteActive(const MidiPlaybackNote& note, double beat) {
    if (beat < note.clipStartBeat || beat >= note.clipStartBeat + note.clipLengthBeats) {
        return false;
    }
    const double posInClip = beat - note.clipStartBeat;
    const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
    const double noteEnd = std::min(note.noteStartBeat + note.noteDurationBeats, note.clipLengthBeats);
    return loopedBeat >= note.noteStartBeat && loopedBeat < noteEnd;
}

// ---- Per-type modulation overloads ----
// These handle DSP-specific parameters only (block-rate, use lfoValue at frame 0).

void applyModulation(OscillatorParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "frequency") {
        p.frequencyHz = std::max(20.0f, p.frequencyHz + modAmount * 440.0f);
    }
}

void applyModulation(SamplerParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "filterCutoff") {
        p.filterCutoff = std::clamp(p.filterCutoff + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterQ") {
        p.filterQ = std::clamp(p.filterQ + modAmount, 0.0f, 1.0f);
    } else if (paramId == "attack") {
        p.attack = std::clamp(p.attack + modAmount, 0.0f, 1.0f);
    } else if (paramId == "decay") {
        p.decay = std::clamp(p.decay + modAmount, 0.0f, 1.0f);
    } else if (paramId == "sustain") {
        p.sustain = std::clamp(p.sustain + modAmount, 0.0f, 1.0f);
    } else if (paramId == "release") {
        p.release = std::clamp(p.release + modAmount, 0.0f, 1.0f);
    } else if (paramId == "rootPitch") {
        p.rootPitch = std::clamp(
            static_cast<int>(std::lround(static_cast<float>(p.rootPitch) + modAmount * 12.0f)), 0, 127);
    } else if (paramId == "rootFineTune") {
        p.rootFineTune = std::clamp(p.rootFineTune + modAmount * 100.0f, -100.0f, 100.0f);
    }
}

void applyModulation(TrackGainParams&, float, const std::string&) noexcept {}

void applyModulation(SubtractiveSynthParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "filterCutoff") {
        p.filterCutoff = std::clamp(p.filterCutoff + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterQ") {
        p.filterQ = std::clamp(p.filterQ + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterMode") {
        p.filterMode = std::clamp(
            static_cast<int>(std::lround(static_cast<float>(p.filterMode) + modAmount * 5.0f)), 0, 5);
    } else if (paramId == "attack") {
        p.ampAttack = std::clamp(p.ampAttack + modAmount, 0.0f, 1.0f);
    } else if (paramId == "decay") {
        p.ampDecay = std::clamp(p.ampDecay + modAmount, 0.0f, 1.0f);
    } else if (paramId == "sustain") {
        p.ampSustain = std::clamp(p.ampSustain + modAmount, 0.0f, 1.0f);
    } else if (paramId == "release") {
        p.ampRelease = std::clamp(p.ampRelease + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc1Shape") {
        p.osc1Shape = std::clamp(p.osc1Shape + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc2Shape") {
        p.osc2Shape = std::clamp(p.osc2Shape + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc1Octave") {
        p.osc1Octave = std::clamp(p.osc1Octave + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc1Semi") {
        p.osc1Semi = std::clamp(p.osc1Semi + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc1Detune") {
        p.osc1Detune = std::clamp(p.osc1Detune + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc2Octave") {
        p.osc2Octave = std::clamp(p.osc2Octave + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc2Semi") {
        p.osc2Semi = std::clamp(p.osc2Semi + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc2Detune") {
        p.osc2Detune = std::clamp(p.osc2Detune + modAmount, 0.0f, 1.0f);
    } else if (paramId == "oscMix") {
        p.oscMix = std::clamp(p.oscMix + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc1Sync") {
        p.osc1Sync = std::clamp(p.osc1Sync + modAmount, 0.0f, 1.0f);
    } else if (paramId == "osc2Sync") {
        p.osc2Sync = std::clamp(p.osc2Sync + modAmount, 0.0f, 1.0f);
    } else if (paramId == "noiseLevel") {
        p.noiseLevel = std::clamp(p.noiseLevel + modAmount, 0.0f, 1.0f);
    } else if (paramId == "oscMixMode") {
        p.oscMixMode = std::clamp(
            static_cast<int>(std::lround(static_cast<float>(p.oscMixMode) + modAmount * 4.0f)), 0, 4);
    } else if (paramId == "unisonVoices") {
        p.unisonVoices = std::clamp(p.unisonVoices + modAmount, 0.0f, 1.0f);
    } else if (paramId == "unisonDetune") {
        p.unisonDetune = std::clamp(p.unisonDetune + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterEnvAmount") {
        p.filterEnvAmount = std::clamp(p.filterEnvAmount + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterAttack") {
        p.filterAttack = std::clamp(p.filterAttack + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterDecay") {
        p.filterDecay = std::clamp(p.filterDecay + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterSustain") {
        p.filterSustain = std::clamp(p.filterSustain + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterRelease") {
        p.filterRelease = std::clamp(p.filterRelease + modAmount, 0.0f, 1.0f);
    } else if (paramId == "glideMs") {
        p.glideMs = std::clamp(p.glideMs + modAmount, 0.0f, 1.0f);
    } else if (paramId == "velocitySensitivity") {
        p.velocitySensitivity = std::clamp(p.velocitySensitivity + modAmount, 0.0f, 1.0f);
    } else if (paramId == "preHpCutoff") {
        p.preHpCutoff = std::clamp(p.preHpCutoff + modAmount, 0.0f, 1.0f);
    } else if (paramId == "preHpRes") {
        p.preHpRes = std::clamp(p.preHpRes + modAmount, 0.0f, 1.0f);
    } else if (paramId == "preDrive") {
        p.preDrive = std::clamp(p.preDrive + modAmount, 0.0f, 1.0f);
    } else if (paramId == "mixFeedback") {
        p.mixFeedback = std::clamp(p.mixFeedback + modAmount, 0.0f, 1.0f);
    } else if (paramId == "globalPitch") {
        p.globalPitch = std::clamp(p.globalPitch + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterKeyTrack") {
        p.filterKeyTrack = std::clamp(p.filterKeyTrack + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterDrive") {
        p.filterDrive = std::clamp(p.filterDrive + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterShaper") {
        p.filterShaper = std::clamp(p.filterShaper + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterFm") {
        p.filterFm = std::clamp(p.filterFm + modAmount, 0.0f, 1.0f);
    } else if (paramId == "filterShaperMode") {
        p.filterShaperMode = std::clamp(
            static_cast<int>(std::lround(static_cast<float>(p.filterShaperMode) + modAmount * 3.0f)),
            0,
            3);
    } else if (paramId == "synthLegato") {
        p.synthLegato = std::clamp(p.synthLegato + modAmount, 0.0f, 1.0f);
    } else if (paramId == "synthMono") {
        p.synthMono = std::clamp(p.synthMono + modAmount, 0.0f, 1.0f);
    }
}

void applyModulation(KickGeneratorParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "kickModel") {
        p.kickModel = std::clamp(p.kickModel + modAmount, 0.0f, 1.0f);
    } else if (paramId == "kickPitch") {
        p.kickPitch = std::clamp(p.kickPitch + modAmount, 0.0f, 1.0f);
    } else if (paramId == "kickPunch") {
        p.kickPunch = std::clamp(p.kickPunch + modAmount, 0.0f, 1.0f);
    } else if (paramId == "kickDecay") {
        p.kickDecay = std::clamp(p.kickDecay + modAmount, 0.0f, 1.0f);
    } else if (paramId == "kickClick") {
        p.kickClick = std::clamp(p.kickClick + modAmount, 0.0f, 1.0f);
    } else if (paramId == "kickTone") {
        p.kickTone = std::clamp(p.kickTone + modAmount, 0.0f, 1.0f);
    } else if (paramId == "kickVelocity") {
        p.kickVelocity = std::clamp(p.kickVelocity + modAmount, 0.0f, 1.0f);
    }
}

void applyModulation(SnareGeneratorParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "snareModel") {
        p.snareModel = std::clamp(p.snareModel + modAmount, 0.0f, 1.0f);
    } else if (paramId == "snareBody") {
        p.snareBody = std::clamp(p.snareBody + modAmount, 0.0f, 1.0f);
    } else if (paramId == "snareRing") {
        p.snareRing = std::clamp(p.snareRing + modAmount, 0.0f, 1.0f);
    } else if (paramId == "snareTune") {
        p.snareTune = std::clamp(p.snareTune + modAmount, 0.0f, 1.0f);
    } else if (paramId == "snareSnares") {
        p.snareSnares = std::clamp(p.snareSnares + modAmount, 0.0f, 1.0f);
    } else if (paramId == "snareSnap") {
        p.snareSnap = std::clamp(p.snareSnap + modAmount, 0.0f, 1.0f);
    } else if (paramId == "snareDecay") {
        p.snareDecay = std::clamp(p.snareDecay + modAmount, 0.0f, 1.0f);
    } else if (paramId == "snareVelocity") {
        p.snareVelocity = std::clamp(p.snareVelocity + modAmount, 0.0f, 1.0f);
    }
}

void applyModulation(ClapGeneratorParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "clapBursts") {
        p.clapBursts = std::clamp(p.clapBursts + modAmount, 0.0f, 1.0f);
    } else if (paramId == "clapSpread") {
        p.clapSpread = std::clamp(p.clapSpread + modAmount, 0.0f, 1.0f);
    } else if (paramId == "clapTone") {
        p.clapTone = std::clamp(p.clapTone + modAmount, 0.0f, 1.0f);
    } else if (paramId == "clapRoom") {
        p.clapRoom = std::clamp(p.clapRoom + modAmount, 0.0f, 1.0f);
    } else if (paramId == "clapDecay") {
        p.clapDecay = std::clamp(p.clapDecay + modAmount, 0.0f, 1.0f);
    } else if (paramId == "clapVelocity") {
        p.clapVelocity = std::clamp(p.clapVelocity + modAmount, 0.0f, 1.0f);
    }
}

void applyModulation(CymbalGeneratorParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "cymbalColor") {
        p.cymbalColor = std::clamp(p.cymbalColor + modAmount, 0.0f, 1.0f);
    } else if (paramId == "cymbalDecay") {
        p.cymbalDecay = std::clamp(p.cymbalDecay + modAmount, 0.0f, 1.0f);
    } else if (paramId == "cymbalWidth") {
        p.cymbalWidth = std::clamp(p.cymbalWidth + modAmount, 0.0f, 1.0f);
    } else if (paramId == "cymbalVelocity") {
        p.cymbalVelocity = std::clamp(p.cymbalVelocity + modAmount, 0.0f, 1.0f);
    }
}

void applyModulation(CrashGeneratorParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "crashColor") {
        p.crashColor = std::clamp(p.crashColor + modAmount, 0.0f, 1.0f);
    } else if (paramId == "crashSpread") {
        p.crashSpread = std::clamp(p.crashSpread + modAmount, 0.0f, 1.0f);
    } else if (paramId == "crashDecay") {
        p.crashDecay = std::clamp(p.crashDecay + modAmount, 0.0f, 1.0f);
    } else if (paramId == "crashVelocity") {
        p.crashVelocity = std::clamp(p.crashVelocity + modAmount, 0.0f, 1.0f);
    }
}

void applyModulation(GateParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "inputGain") {
        p.inputGain = std::clamp(p.inputGain + modAmount, 0.0f, 1.0f);
    } else if (paramId == "gateThreshold") {
        p.gateThreshold = std::clamp(p.gateThreshold + modAmount, 0.0f, 1.0f);
    } else if (paramId == "gateAttack") {
        p.gateAttack = std::clamp(p.gateAttack + modAmount, 0.0f, 1.0f);
    } else if (paramId == "gateRelease") {
        p.gateRelease = std::clamp(p.gateRelease + modAmount, 0.0f, 1.0f);
    } else if (paramId == "gateHold") {
        p.gateHold = std::clamp(p.gateHold + modAmount, 0.0f, 1.0f);
    } else if (paramId == "gateRange") {
        p.gateRange = std::clamp(p.gateRange + modAmount, 0.0f, 1.0f);
    }
}

void applyModulation(CompressorParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "inputGain") {
        p.inputGain = std::clamp(p.inputGain + modAmount, 0.0f, 1.0f);
    } else if (paramId == "compThreshold") {
        p.compThreshold = std::clamp(p.compThreshold + modAmount, 0.0f, 1.0f);
    } else if (paramId == "compRatio") {
        p.compRatio = std::clamp(p.compRatio + modAmount, 0.0f, 1.0f);
    } else if (paramId == "compAttack") {
        p.compAttack = std::clamp(p.compAttack + modAmount, 0.0f, 1.0f);
    } else if (paramId == "compRelease") {
        p.compRelease = std::clamp(p.compRelease + modAmount, 0.0f, 1.0f);
    } else if (paramId == "compKnee") {
        p.compKnee = std::clamp(p.compKnee + modAmount, 0.0f, 1.0f);
    } else if (paramId == "compMakeup") {
        p.compMakeup = std::clamp(p.compMakeup + modAmount, 0.0f, 1.0f);
    }
}

void applyModulation(ExpanderParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "inputGain") {
        p.inputGain = std::clamp(p.inputGain + modAmount, 0.0f, 1.0f);
    } else if (paramId == "expandThreshold") {
        p.expandThreshold = std::clamp(p.expandThreshold + modAmount, 0.0f, 1.0f);
    } else if (paramId == "expandRatio") {
        p.expandRatio = std::clamp(p.expandRatio + modAmount, 0.0f, 1.0f);
    } else if (paramId == "expandAttack") {
        p.expandAttack = std::clamp(p.expandAttack + modAmount, 0.0f, 1.0f);
    } else if (paramId == "expandRelease") {
        p.expandRelease = std::clamp(p.expandRelease + modAmount, 0.0f, 1.0f);
    } else if (paramId == "expandRange") {
        p.expandRange = std::clamp(p.expandRange + modAmount, 0.0f, 1.0f);
    }
}

void applyModulation(LimiterParams& p, float modAmount, const std::string& paramId) noexcept {
    if (paramId == "inputGain") {
        p.inputGain = std::clamp(p.inputGain + modAmount, 0.0f, 1.0f);
    } else if (paramId == "limitCeiling") {
        p.limitCeiling = std::clamp(p.limitCeiling + modAmount, 0.0f, 1.0f);
    } else if (paramId == "limitAttack") {
        p.limitAttack = std::clamp(p.limitAttack + modAmount, 0.0f, 1.0f);
    } else if (paramId == "limitRelease") {
        p.limitRelease = std::clamp(p.limitRelease + modAmount, 0.0f, 1.0f);
    } else if (paramId == "limitKnee") {
        p.limitKnee = std::clamp(p.limitKnee + modAmount, 0.0f, 1.0f);
    } else if (paramId == "limitDrive") {
        p.limitDrive = std::clamp(p.limitDrive + modAmount, 0.0f, 1.0f);
    } else if (paramId == "limitMakeup") {
        p.limitMakeup = std::clamp(p.limitMakeup + modAmount, 0.0f, 1.0f);
    }
}

/// Multiply stereo buffers by a scalar gain.
void applyStereoScalarGain(float* left, float* right, int frames, float gain) noexcept {
    for (int f = 0; f < frames; ++f) {
        left[f] *= gain;
        right[f] *= gain;
    }
}

/// Multiply buffer by per-frame gain values.
void multiplyPerFrameGain(float* buffer, int frames, const float* perFrameGain) noexcept {
    for (int f = 0; f < frames; ++f) {
        buffer[f] *= perFrameGain[f];
    }
}

/// Mix mono buffer into stereo with per-frame pan values.
void mixStereoPerFramePan(float* trackLeft, float* trackRight,
                           const float* mono, int frames,
                           const float* perFramePan) noexcept {
    for (int f = 0; f < frames; ++f) {
        const float angle = std::clamp(perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
        trackLeft[f] += mono[f] * std::cos(angle);
        trackRight[f] += mono[f] * std::sin(angle);
    }
}

constexpr int kAutomationSubBlockFrames = 64;

void applyDspModulationAtFrame(DeviceVariantParams& params,
                               DeviceNodeKind kind,
                               const std::string& deviceId,
                               int lfoFrame,
                               int framesToProcess,
                               const float* lfoValues,
                               int lfoCount,
                               const ModulationEdge* modEdges,
                               int modEdgeCount) noexcept {
    if (lfoValues == nullptr || lfoCount <= 0 || deviceId.empty()) {
        return;
    }
    for (int e = 0; e < modEdgeCount; ++e) {
        const auto& edge = modEdges[e];
        if (edge.deviceId != deviceId || edge.lfoId >= lfoCount) {
            continue;
        }
        if (edge.paramId == "gain" || edge.paramId == "pan") {
            continue;
        }
        const float lfoOut = lfoValues[edge.lfoId * framesToProcess + lfoFrame];
        const float modAmount = edge.amount * lfoOut;
        std::visit([&](auto& p) { applyModulation(p, modAmount, edge.paramId); }, params);
    }
}

DeviceVariantParams dspParamsAtFrame(const DeviceNodePlayback& node,
                                   double beat,
                                   int lfoFrame,
                                   int framesToProcess,
                                   const AutomationClipPlayback* automationClips,
                                   int automationClipCount,
                                   const float* lfoValues,
                                   int lfoCount,
                                   const ModulationEdge* modEdges,
                                   int modEdgeCount) {
    auto params = node.params;
    applyDspAutomationAtBeat(params, node.kind, node.deviceId, beat, automationClips,
                             automationClipCount);
    applyDspModulationAtFrame(params, node.kind, node.deviceId, lfoFrame, framesToProcess,
                                lfoValues, lfoCount, modEdges, modEdgeCount);
    return params;
}

bool nodeUsesDspAutomationSubBlocks(const DeviceNodePlayback& node,
                                    const AutomationClipPlayback* clips,
                                    int clipCount) noexcept {
    if (!nodeHasDspAutomation(node.deviceId, clips, clipCount)) {
        return false;
    }
    switch (node.kind) {
    case DeviceNodeKind::Oscillator:
    case DeviceNodeKind::Sampler:
        return true;
    case DeviceNodeKind::SubtractiveSynth:
        // Filter/osc automation is applied per-sample inside mixSubtractiveMidiNotesBlock.
        return false;
    default:
        return false;
    }
}

} // namespace

bool isDynamicsDeviceNodeKind(const DeviceNodeKind kind) noexcept {
    return kind == DeviceNodeKind::Gate || kind == DeviceNodeKind::Compressor ||
           kind == DeviceNodeKind::Expander || kind == DeviceNodeKind::Limiter;
}

float midiActiveFrequencyHz(const MidiPlaybackNote* notes,
                            int noteCount,
                            double playheadBeat,
                            float idleFrequencyHz) noexcept {
    int pitch = -1;
    for (int i = 0; i < noteCount; ++i) {
        if (!isMidiNoteActive(notes[i], playheadBeat)) {
            continue;
        }
        pitch = notes[i].pitch;
    }
    if (pitch >= 0) {
        return midiNoteToHz(pitch);
    }
    return idleFrequencyHz;
}

void processDeviceChain(float* trackLeft,
                        float* trackRight,
                        int numFrames,
                        double sampleRate,
                        int bpm,
                        double playheadStartBeat,
                        const MidiPlaybackNote* notes,
                        int noteCount,
                        const DeviceNodePlayback* devices,
                        int deviceCount,
                        float& oscillatorPhase,
                        bool suppressInstruments,
                        BiquadState* samplerFilterStates,
                        SubtractiveSynthRuntime* subtractiveRuntimes,
                        KickGeneratorRuntime* kickRuntimes,
                        SnareGeneratorRuntime* snareRuntimes,
                        ClapGeneratorRuntime* clapRuntimes,
                        CymbalGeneratorRuntime* cymbalRuntimes,
                        CrashGeneratorRuntime* crashRuntimes,
                        DynamicsRuntime* dynamicsRuntimes,
                        DeviceMeterAtomic* deviceMeters,
                        int maxDeviceMeters,
                        const float* lfoValues,
                        int lfoCount,
                        const ModulationEdge* modEdges,
                        int modEdgeCount,
                        const AutomationClipPlayback* automationClips,
                        int automationClipCount) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || devices == nullptr ||
        deviceCount <= 0) {
        return;
    }

    const int framesToProcess = numFrames > kScratchFrames ? kScratchFrames : numFrames;
    float scratch[kScratchFrames];

    for (int deviceIndex = 0; deviceIndex < deviceCount; ++deviceIndex) {
        const DeviceNodePlayback& node = devices[deviceIndex];

        if (node.bypassed) {
            continue;
        }

        // --- Base params; timeline automation first, then LFO modulation on top ---
        auto modulatedParams = node.params;

        float perFrameGain[kScratchFrames];
        float perFramePan[kScratchFrames];
        for (int f = 0; f < framesToProcess; ++f) {
            perFrameGain[f] = node.gain;
            perFramePan[f] = node.pan;
        }

        const double beatsPerFrame =
            (static_cast<double>(std::max(bpm, 1)) / 60.0) / sampleRate;

        const bool dspAutomationSubBlocks = nodeUsesDspAutomationSubBlocks(
            node, automationClips, automationClipCount);

        if (automationClips != nullptr && automationClipCount > 0 && !node.deviceId.empty()) {
            for (int a = 0; a < automationClipCount; ++a) {
                const AutomationClipPlayback& ac = automationClips[a];
                if (std::string(ac.deviceId) != node.deviceId) {
                    continue;
                }
                const std::string paramId(ac.paramId);
                if (paramId == "gain" || paramId == "pan") {
                    for (int f = 0; f < framesToProcess; ++f) {
                        const double beat =
                            playheadStartBeat + static_cast<double>(f) * beatsPerFrame;
                        if (beat < static_cast<double>(ac.clipStartBeat) ||
                            beat >= static_cast<double>(ac.clipStartBeat + ac.clipLengthBeats)) {
                            continue;
                        }
                        const float beatInClip =
                            static_cast<float>(beat - static_cast<double>(ac.clipStartBeat));
                        const float value =
                            evaluateAutomationEnvelope(ac.points, ac.pointCount, beatInClip);
                        if (paramId == "gain") {
                            perFrameGain[f] = value;
                        } else {
                            perFramePan[f] = value;
                        }
                    }
                } else if (!dspAutomationSubBlocks) {
                    if (node.kind == DeviceNodeKind::SubtractiveSynth &&
                        nodeHasDspAutomation(node.deviceId, automationClips, automationClipCount)) {
                        continue;
                    }
                    const double beat = playheadStartBeat;
                    if (beat < static_cast<double>(ac.clipStartBeat) ||
                        beat >= static_cast<double>(ac.clipStartBeat + ac.clipLengthBeats)) {
                        continue;
                    }
                    const float beatInClip =
                        static_cast<float>(beat - static_cast<double>(ac.clipStartBeat));
                    const float value =
                        evaluateAutomationEnvelope(ac.points, ac.pointCount, beatInClip);
                    applyAutomationValue(modulatedParams, node.kind, paramId, value);
                }
            }
        }

        if (lfoValues != nullptr && lfoCount > 0 && !node.deviceId.empty()) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const auto& edge = modEdges[e];
                if (edge.deviceId != node.deviceId || edge.lfoId >= lfoCount) {
                    continue;
                }
                if (edge.paramId != "gain" && edge.paramId != "pan") {
                    if (dspAutomationSubBlocks) {
                        continue;
                    }
                    const float lfoOut = lfoValues[edge.lfoId * framesToProcess];
                    const float modAmount = edge.amount * lfoOut;
                    std::visit([&](auto& params) {
                        applyModulation(params, modAmount, edge.paramId);
                    }, modulatedParams);
                }
            }
        }

        if (lfoValues != nullptr && lfoCount > 0 && !node.deviceId.empty()) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const auto& edge = modEdges[e];
                if (edge.deviceId != node.deviceId || edge.lfoId >= lfoCount) {
                    continue;
                }
                if (edge.paramId == "gain") {
                    for (int f = 0; f < framesToProcess; ++f) {
                        const float lfoOut = lfoValues[edge.lfoId * framesToProcess + f];
                        perFrameGain[f] = std::clamp(perFrameGain[f] + edge.amount * lfoOut, 0.0f, 1.0f);
                    }
                } else if (edge.paramId == "pan") {
                    for (int f = 0; f < framesToProcess; ++f) {
                        const float lfoOut = lfoValues[edge.lfoId * framesToProcess + f];
                        perFramePan[f] = std::clamp(perFramePan[f] + edge.amount * lfoOut, 0.0f, 1.0f);
                    }
                }
            }
        }

        // --- Process device and apply per-frame gain/pan ---
        switch (node.kind) {
        case DeviceNodeKind::Oscillator: {
            if (!suppressInstruments) {
                std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                if (dspAutomationSubBlocks) {
                    for (int sub = 0; sub < framesToProcess; sub += kAutomationSubBlockFrames) {
                        const int subLen = std::min(kAutomationSubBlockFrames, framesToProcess - sub);
                        const double subBeat =
                            playheadStartBeat + static_cast<double>(sub) * beatsPerFrame;
                        auto subParams = dspParamsAtFrame(
                            node, subBeat, sub, framesToProcess, automationClips,
                            automationClipCount, lfoValues, lfoCount, modEdges, modEdgeCount);
                        auto p = std::get<OscillatorParams>(subParams);
                        p.frequencyHz =
                            midiActiveFrequencyHz(notes, noteCount, subBeat, p.frequencyHz);
                        if (p.frequencyHz > 0.0f) {
                            addSineBlock(scratch + sub, subLen, sampleRate, p.frequencyHz,
                                         oscillatorPhase, kInstrumentOutputGain);
                        }
                    }
                } else {
                    auto p = std::get<OscillatorParams>(modulatedParams);
                    p.frequencyHz = midiActiveFrequencyHz(notes, noteCount,
                        playheadStartBeat, p.frequencyHz);
                    const float frequency = p.frequencyHz;
                    if (frequency > 0.0f) {
                        addSineBlock(scratch, framesToProcess, sampleRate, frequency,
                                     oscillatorPhase, kInstrumentOutputGain);
                    }
                }
                multiplyPerFrameGain(scratch, framesToProcess, perFrameGain);
                mixStereoPerFramePan(trackLeft, trackRight, scratch,
                                     framesToProcess, perFramePan);
            }
            break;
        }
        case DeviceNodeKind::Sampler: {
            if (!suppressInstruments) {
                const auto& baseParams = std::get<SamplerParams>(modulatedParams);
                if (baseParams.samplerPcm != nullptr && noteCount > 0) {
                    SamplerMidiNoteRegion regions[32];
                    const int regionCount = noteCount > 32 ? 32 : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        regions[i] = SamplerMidiNoteRegion{
                            note.pitch, note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats, note.velocity,
                        };
                    }
                    std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    const auto renderSampler = [&](int sub, int subLen, double subBeat,
                                                   const SamplerParams& p) {
                        mixSamplerMidiNotesBlock(scratch + sub, subLen, sampleRate, bpm, subBeat,
                                               regions, regionCount,
                                               SamplerInstrumentPlayback{
                                                   p.samplerPcm,
                                                   p.samplerFrameCount,
                                                   p.samplerPcmSampleRate,
                                                   kInstrumentOutputGain,
                                                   p.rootPitch,
                                                   p.rootFineTune,
                                                   p.attack, p.decay,
                                                   p.sustain, p.release,
                                                   p.filterCutoff, p.filterQ,
                                                   p.filterMode,
                                                   p.trimStartFrame, p.trimEndFrame,
                                                   p.regionStartFrame, p.regionEndFrame,
                                                   p.playbackMode,
                                                   samplerFilterStates != nullptr
                                                       ? &samplerFilterStates[deviceIndex]
                                                       : nullptr,
                                               });
                    };
                    if (dspAutomationSubBlocks) {
                        for (int sub = 0; sub < framesToProcess; sub += kAutomationSubBlockFrames) {
                            const int subLen =
                                std::min(kAutomationSubBlockFrames, framesToProcess - sub);
                            const double subBeat =
                                playheadStartBeat + static_cast<double>(sub) * beatsPerFrame;
                            const auto& p = std::get<SamplerParams>(dspParamsAtFrame(
                                node, subBeat, sub, framesToProcess, automationClips,
                                automationClipCount, lfoValues, lfoCount, modEdges, modEdgeCount));
                            renderSampler(sub, subLen, subBeat, p);
                        }
                    } else {
                        renderSampler(0, framesToProcess, playheadStartBeat, baseParams);
                    }
                    multiplyPerFrameGain(scratch, framesToProcess, perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, scratch,
                                         framesToProcess, perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::SubtractiveSynth: {
            if (!suppressInstruments) {
                if (noteCount > 0) {
                    SubtractiveMidiNoteRegion regions[32];
                    const int regionCount = noteCount > 32 ? 32 : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        regions[i] = SubtractiveMidiNoteRegion{
                            note.pitch, i,
                            note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats,
                            note.velocity,
                        };
                    }
                    std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    SubtractiveSynthRuntime localRuntime{};
                    SubtractiveSynthRuntime& runtime =
                        subtractiveRuntimes != nullptr ? subtractiveRuntimes[deviceIndex]
                                                       : localRuntime;
                    const bool hasDspAutomation = nodeHasDspAutomation(
                        node.deviceId, automationClips, automationClipCount);
                    mixSubtractiveMidiNotesBlock(scratch,
                                                 framesToProcess,
                                                 sampleRate,
                                                 bpm,
                                                 playheadStartBeat,
                                                 regions,
                                                 regionCount,
                                                 std::get<SubtractiveSynthParams>(modulatedParams),
                                                 runtime,
                                                 hasDspAutomation ? automationClips : nullptr,
                                                 hasDspAutomation ? automationClipCount : 0,
                                                 hasDspAutomation ? &node.deviceId : nullptr);
                    multiplyPerFrameGain(scratch, framesToProcess, perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, scratch,
                                         framesToProcess, perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::KickGenerator: {
            if (!suppressInstruments) {
                const auto& kickParams = std::get<KickGeneratorParams>(modulatedParams);
                if (noteCount > 0) {
                    KickMidiNoteRegion regions[32];
                    const int regionCount = noteCount > 32 ? 32 : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        regions[i] = KickMidiNoteRegion{
                            note.pitch, i,
                            note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats,
                            note.velocity,
                        };
                    }
                    std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    KickGeneratorRuntime localRuntime{};
                    mixKickMidiNotesBlock(scratch, framesToProcess, sampleRate, bpm,
                                          playheadStartBeat, regions, regionCount, kickParams,
                                          kickRuntimes != nullptr ? kickRuntimes[deviceIndex]
                                                                  : localRuntime);
                    multiplyPerFrameGain(scratch, framesToProcess, perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, scratch,
                                         framesToProcess, perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::SnareGenerator: {
            if (!suppressInstruments) {
                const auto& snareParams = std::get<SnareGeneratorParams>(modulatedParams);
                if (noteCount > 0) {
                    SnareMidiNoteRegion regions[32];
                    const int regionCount = noteCount > 32 ? 32 : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        regions[i] = SnareMidiNoteRegion{
                            note.pitch, i,
                            note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats,
                            note.velocity,
                        };
                    }
                    std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    SnareGeneratorRuntime localRuntime{};
                    mixSnareMidiNotesBlock(scratch, framesToProcess, sampleRate, bpm,
                                           playheadStartBeat, regions, regionCount, snareParams,
                                           snareRuntimes != nullptr ? snareRuntimes[deviceIndex]
                                                                    : localRuntime);
                    multiplyPerFrameGain(scratch, framesToProcess, perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, scratch,
                                         framesToProcess, perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::ClapGenerator: {
            if (!suppressInstruments) {
                const auto& clapParams = std::get<ClapGeneratorParams>(modulatedParams);
                if (noteCount > 0) {
                    ClapMidiNoteRegion regions[32];
                    const int regionCount = noteCount > 32 ? 32 : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        regions[i] = ClapMidiNoteRegion{
                            note.pitch, i,
                            note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats,
                            note.velocity,
                        };
                    }
                    std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    ClapGeneratorRuntime localRuntime{};
                    mixClapMidiNotesBlock(scratch, framesToProcess, sampleRate, bpm,
                                          playheadStartBeat, regions, regionCount, clapParams,
                                          clapRuntimes != nullptr ? clapRuntimes[deviceIndex]
                                                                  : localRuntime);
                    multiplyPerFrameGain(scratch, framesToProcess, perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, scratch,
                                         framesToProcess, perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::CymbalGenerator: {
            if (!suppressInstruments) {
                const auto& cymbalParams = std::get<CymbalGeneratorParams>(modulatedParams);
                if (noteCount > 0) {
                    CymbalMidiNoteRegion regions[32];
                    const int regionCount = noteCount > 32 ? 32 : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        regions[i] = CymbalMidiNoteRegion{
                            note.pitch, i,
                            note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats,
                            note.velocity,
                        };
                    }
                    std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    CymbalGeneratorRuntime localRuntime{};
                    mixCymbalMidiNotesBlockStereo(trackLeft, trackRight, framesToProcess,
                                                  sampleRate, bpm, playheadStartBeat,
                                                  regions, regionCount, cymbalParams,
                                                  cymbalRuntimes != nullptr
                                                      ? cymbalRuntimes[deviceIndex]
                                                      : localRuntime,
                                                  perFrameGain);
                }
            }
            break;
        }
        case DeviceNodeKind::CrashGenerator: {
            if (!suppressInstruments) {
                const auto& crashParams = std::get<CrashGeneratorParams>(modulatedParams);
                if (noteCount > 0) {
                    CrashMidiNoteRegion regions[32];
                    const int regionCount = noteCount > 32 ? 32 : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        regions[i] = CrashMidiNoteRegion{
                            note.pitch, i,
                            note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats,
                            note.velocity,
                        };
                    }
                    std::memset(scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    CrashGeneratorRuntime localRuntime{};
                    mixCrashMidiNotesBlockStereo(trackLeft, trackRight, framesToProcess,
                                                 sampleRate, bpm, playheadStartBeat,
                                                 regions, regionCount, crashParams,
                                                 crashRuntimes != nullptr
                                                     ? crashRuntimes[deviceIndex]
                                                     : localRuntime,
                                                 perFrameGain);
                }
            }
            break;
        }
        case DeviceNodeKind::Gate: {
            auto p = std::get<GateParams>(modulatedParams);
            DynamicsRuntime localRuntime{};
            DynamicsRuntime& runtime =
                dynamicsRuntimes != nullptr ? dynamicsRuntimes[deviceIndex] : localRuntime;
            const float inputGain = std::clamp(p.inputGain, 0.0f, 1.0f);
            applyStereoScalarGain(trackLeft, trackRight, framesToProcess, inputGain);
            const float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
            processGateStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p, runtime);
            publishDynamicsMeters(node, runtime, inputPeak, deviceMeters, maxDeviceMeters);
            for (int f = 0; f < framesToProcess; ++f) {
                trackLeft[f] *= perFrameGain[f];
                trackRight[f] *= perFrameGain[f];
            }
            break;
        }
        case DeviceNodeKind::Compressor: {
            auto p = std::get<CompressorParams>(modulatedParams);
            DynamicsRuntime localRuntime{};
            DynamicsRuntime& runtime =
                dynamicsRuntimes != nullptr ? dynamicsRuntimes[deviceIndex] : localRuntime;
            const float inputGain = std::clamp(p.inputGain, 0.0f, 1.0f);
            applyStereoScalarGain(trackLeft, trackRight, framesToProcess, inputGain);
            const float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
            processCompressorStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p,
                                         runtime);
            publishDynamicsMeters(node, runtime, inputPeak, deviceMeters, maxDeviceMeters);
            for (int f = 0; f < framesToProcess; ++f) {
                trackLeft[f] *= perFrameGain[f];
                trackRight[f] *= perFrameGain[f];
            }
            break;
        }
        case DeviceNodeKind::Expander: {
            auto p = std::get<ExpanderParams>(modulatedParams);
            DynamicsRuntime localRuntime{};
            DynamicsRuntime& runtime =
                dynamicsRuntimes != nullptr ? dynamicsRuntimes[deviceIndex] : localRuntime;
            const float inputGain = std::clamp(p.inputGain, 0.0f, 1.0f);
            applyStereoScalarGain(trackLeft, trackRight, framesToProcess, inputGain);
            const float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
            processExpanderStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p,
                                       runtime);
            publishDynamicsMeters(node, runtime, inputPeak, deviceMeters, maxDeviceMeters);
            for (int f = 0; f < framesToProcess; ++f) {
                trackLeft[f] *= perFrameGain[f];
                trackRight[f] *= perFrameGain[f];
            }
            break;
        }
        case DeviceNodeKind::Limiter: {
            auto p = std::get<LimiterParams>(modulatedParams);
            DynamicsRuntime localRuntime{};
            DynamicsRuntime& runtime =
                dynamicsRuntimes != nullptr ? dynamicsRuntimes[deviceIndex] : localRuntime;
            const float inputGain = std::clamp(p.inputGain, 0.0f, 1.0f);
            applyStereoScalarGain(trackLeft, trackRight, framesToProcess, inputGain);
            const float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
            processLimiterStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p, runtime);
            publishDynamicsMeters(node, runtime, inputPeak, deviceMeters, maxDeviceMeters);
            for (int f = 0; f < framesToProcess; ++f) {
                trackLeft[f] *= perFrameGain[f];
                trackRight[f] *= perFrameGain[f];
            }
            break;
        }
        case DeviceNodeKind::TrackGain: {
            for (int f = 0; f < framesToProcess; ++f) {
                trackLeft[f] *= perFrameGain[f];
                trackRight[f] *= perFrameGain[f];
            }
            break;
        }
        case DeviceNodeKind::Unknown:
        default:
            break;
        }
    }
}

} // namespace audioapp