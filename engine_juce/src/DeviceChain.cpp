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
constexpr int kAutomationSubBlockFrames = 64;

struct DeviceChainScratch {
    float scratch[kScratchFrames];
    float tempStereoL[kScratchFrames];
    float tempStereoR[kScratchFrames];
    float perFrameGain[kScratchFrames];
    float perFramePan[kScratchFrames];
    SamplerMidiNoteRegion samplerRegions[kMaxInstrumentRegions];
    SubtractiveMidiNoteRegion subtractiveRegions[kMaxInstrumentRegions];
    KickMidiNoteRegion kickRegions[kMaxInstrumentRegions];
    SnareMidiNoteRegion snareRegions[kMaxInstrumentRegions];
    ClapMidiNoteRegion clapRegions[kMaxInstrumentRegions];
    CymbalMidiNoteRegion cymbalRegions[kMaxInstrumentRegions];
    CrashMidiNoteRegion crashRegions[kMaxInstrumentRegions];
    BiquadState samplerNoteFilterStates[kMaxInstrumentRegions];
};
thread_local DeviceChainScratch gScratch;

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

// ---- Realtime-safe helpers ----

/// Compare a char[48] deviceId with a std::string (both NUL-terminated).
bool deviceIdMatches(const char* clipDeviceId, const std::string& deviceId) noexcept {
    return std::strncmp(clipDeviceId, deviceId.c_str(), 47) == 0;
}

/// True when the deviceId has any non-gain/pan automation clip, OR any modulation edge.
bool nodeNeedsSubBlocks(const DeviceNodePlayback& node,
                        const AutomationClipPlayback* clips,
                        int clipCount,
                        const ModulationEdgePlayback* modEdges,
                        int modEdgeCount) noexcept {
    if (clips != nullptr && clipCount > 0 && !node.deviceId.empty()) {
        for (int a = 0; a < clipCount; ++a) {
            if (!deviceIdMatches(clips[a].deviceId, node.deviceId)) continue;
            if (clips[a].paramId != ParamId::Gain && clips[a].paramId != ParamId::Pan) {
                return true;
            }
        }
    }
    if (modEdges != nullptr && modEdgeCount > 0 && !node.deviceId.empty()) {
        for (int e = 0; e < modEdgeCount; ++e) {
            if (modEdges[e].deviceId != node.deviceId) continue;
            if (modEdges[e].paramId != ParamId::Gain && modEdges[e].paramId != ParamId::Pan) {
                return true;
            }
        }
    }
    return false;
}

// ---- Per-type modulation overloads (ParamId enum dispatch) ----

void applyModulation(OscillatorParams& p, float modAmount, ParamId pid) noexcept {
    if (pid == ParamId::Frequency) {
        p.frequencyHz = std::max(20.0f, p.frequencyHz + modAmount * 440.0f);
    }
}

void applyModulation(SamplerParams& p, float modAmount, ParamId pid) noexcept {
    switch (pid) {
    case ParamId::FilterCutoff:   p.filterCutoff = std::clamp(p.filterCutoff + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterQ:        p.filterQ = std::clamp(p.filterQ + modAmount, 0.0f, 1.0f); break;
    case ParamId::Attack:         p.attack = std::clamp(p.attack + modAmount, 0.0f, 1.0f); break;
    case ParamId::Decay:          p.decay = std::clamp(p.decay + modAmount, 0.0f, 1.0f); break;
    case ParamId::Sustain:        p.sustain = std::clamp(p.sustain + modAmount, 0.0f, 1.0f); break;
    case ParamId::Release:        p.release = std::clamp(p.release + modAmount, 0.0f, 1.0f); break;
    case ParamId::RootPitch:      p.rootPitch = std::clamp(static_cast<int>(std::lround(static_cast<float>(p.rootPitch) + modAmount * 12.0f)), 0, 127); break;
    case ParamId::RootFineTune:   p.rootFineTune = std::clamp(p.rootFineTune + modAmount * 100.0f, -100.0f, 100.0f); break;
    case ParamId::FilterEnvAmount: p.filterEnvAmount = std::clamp(p.filterEnvAmount + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterAttack:   p.filterAttack = std::clamp(p.filterAttack + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterDecay:    p.filterDecay = std::clamp(p.filterDecay + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterSustain:  p.filterSustain = std::clamp(p.filterSustain + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterRelease:  p.filterRelease = std::clamp(p.filterRelease + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(TrackGainParams&, float, ParamId) noexcept {}

void applyModulation(SubtractiveSynthParams& p, float modAmount, ParamId pid) noexcept {
    switch (pid) {
    case ParamId::FilterCutoff:      p.filterCutoff = std::clamp(p.filterCutoff + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterQ:           p.filterQ = std::clamp(p.filterQ + modAmount, 0.0f, 1.0f); break;
    case ParamId::Attack:            p.ampAttack = std::clamp(p.ampAttack + modAmount, 0.0f, 1.0f); break;
    case ParamId::Decay:             p.ampDecay = std::clamp(p.ampDecay + modAmount, 0.0f, 1.0f); break;
    case ParamId::Sustain:           p.ampSustain = std::clamp(p.ampSustain + modAmount, 0.0f, 1.0f); break;
    case ParamId::Release:           p.ampRelease = std::clamp(p.ampRelease + modAmount, 0.0f, 1.0f); break;
    case ParamId::Osc1Shape:         p.osc1Shape = std::clamp(p.osc1Shape + modAmount, 0.0f, 1.0f); break;
    case ParamId::Osc2Shape:         p.osc2Shape = std::clamp(p.osc2Shape + modAmount, 0.0f, 1.0f); break;
    case ParamId::Osc1Octave:        p.osc1Octave = std::clamp(p.osc1Octave + modAmount, 0.0f, 1.0f); break;
    case ParamId::Osc1Semi:          p.osc1Semi = std::clamp(p.osc1Semi + modAmount, 0.0f, 1.0f); break;
    case ParamId::Osc1Detune:        p.osc1Detune = std::clamp(p.osc1Detune + modAmount, 0.0f, 1.0f); break;
    case ParamId::Osc2Octave:        p.osc2Octave = std::clamp(p.osc2Octave + modAmount, 0.0f, 1.0f); break;
    case ParamId::Osc2Semi:          p.osc2Semi = std::clamp(p.osc2Semi + modAmount, 0.0f, 1.0f); break;
    case ParamId::Osc2Detune:        p.osc2Detune = std::clamp(p.osc2Detune + modAmount, 0.0f, 1.0f); break;
    case ParamId::OscMix:            p.oscMix = std::clamp(p.oscMix + modAmount, 0.0f, 1.0f); break;
    case ParamId::Osc1Sync:          p.osc1Sync = std::clamp(p.osc1Sync + modAmount, 0.0f, 1.0f); break;
    case ParamId::Osc2Sync:          p.osc2Sync = std::clamp(p.osc2Sync + modAmount, 0.0f, 1.0f); break;
    case ParamId::NoiseLevel:        p.noiseLevel = std::clamp(p.noiseLevel + modAmount, 0.0f, 1.0f); break;
    case ParamId::OscMixMode:        p.oscMixMode = std::clamp(static_cast<int>(std::lround(static_cast<float>(p.oscMixMode) + modAmount * 4.0f)), 0, 4); break;
    case ParamId::UnisonVoices:      p.unisonVoices = std::clamp(p.unisonVoices + modAmount, 0.0f, 1.0f); break;
    case ParamId::UnisonDetune:      p.unisonDetune = std::clamp(p.unisonDetune + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterEnvAmount:   p.filterEnvAmount = std::clamp(p.filterEnvAmount + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterAttack:      p.filterAttack = std::clamp(p.filterAttack + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterDecay:       p.filterDecay = std::clamp(p.filterDecay + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterSustain:     p.filterSustain = std::clamp(p.filterSustain + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterRelease:     p.filterRelease = std::clamp(p.filterRelease + modAmount, 0.0f, 1.0f); break;
    case ParamId::GlideMs:           p.glideMs = std::clamp(p.glideMs + modAmount, 0.0f, 1.0f); break;
    case ParamId::VelocitySensitivity: p.velocitySensitivity = std::clamp(p.velocitySensitivity + modAmount, 0.0f, 1.0f); break;
    case ParamId::PreHpCutoff:       p.preHpCutoff = std::clamp(p.preHpCutoff + modAmount, 0.0f, 1.0f); break;
    case ParamId::PreHpRes:          p.preHpRes = std::clamp(p.preHpRes + modAmount, 0.0f, 1.0f); break;
    case ParamId::PreDrive:          p.preDrive = std::clamp(p.preDrive + modAmount, 0.0f, 1.0f); break;
    case ParamId::MixFeedback:       p.mixFeedback = std::clamp(p.mixFeedback + modAmount, 0.0f, 1.0f); break;
    case ParamId::GlobalPitch:       p.globalPitch = std::clamp(p.globalPitch + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterKeyTrack:    p.filterKeyTrack = std::clamp(p.filterKeyTrack + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterDrive:       p.filterDrive = std::clamp(p.filterDrive + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterShaper:      p.filterShaper = std::clamp(p.filterShaper + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterFm:          p.filterFm = std::clamp(p.filterFm + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterShaperMode:  p.filterShaperMode = std::clamp(static_cast<int>(std::lround(static_cast<float>(p.filterShaperMode) + modAmount * 3.0f)), 0, 3); break;
    case ParamId::SynthLegato:       p.synthLegato = std::clamp(p.synthLegato + modAmount, 0.0f, 1.0f); break;
    case ParamId::SynthMono:         p.synthMono = std::clamp(p.synthMono + modAmount, 0.0f, 1.0f); break;
    case ParamId::FilterMode:        p.filterMode = std::clamp(static_cast<int>(std::lround(static_cast<float>(p.filterMode) + modAmount * 5.0f)), 0, 5); break;
    default: break;
    }
}

void applyModulation(KickGeneratorParams& p, float modAmount, ParamId pid) noexcept {
    switch (pid) {
    case ParamId::KickModel:    p.kickModel = std::clamp(p.kickModel + modAmount, 0.0f, 1.0f); break;
    case ParamId::KickPitch:    p.kickPitch = std::clamp(p.kickPitch + modAmount, 0.0f, 1.0f); break;
    case ParamId::KickPunch:    p.kickPunch = std::clamp(p.kickPunch + modAmount, 0.0f, 1.0f); break;
    case ParamId::KickDecay:    p.kickDecay = std::clamp(p.kickDecay + modAmount, 0.0f, 1.0f); break;
    case ParamId::KickClick:    p.kickClick = std::clamp(p.kickClick + modAmount, 0.0f, 1.0f); break;
    case ParamId::KickTone:     p.kickTone = std::clamp(p.kickTone + modAmount, 0.0f, 1.0f); break;
    case ParamId::KickVelocity: p.kickVelocity = std::clamp(p.kickVelocity + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(SnareGeneratorParams& p, float modAmount, ParamId pid) noexcept {
    switch (pid) {
    case ParamId::SnareModel:   p.snareModel = std::clamp(p.snareModel + modAmount, 0.0f, 1.0f); break;
    case ParamId::SnareBody:    p.snareBody = std::clamp(p.snareBody + modAmount, 0.0f, 1.0f); break;
    case ParamId::SnareRing:    p.snareRing = std::clamp(p.snareRing + modAmount, 0.0f, 1.0f); break;
    case ParamId::SnareTune:    p.snareTune = std::clamp(p.snareTune + modAmount, 0.0f, 1.0f); break;
    case ParamId::SnareSnares:  p.snareSnares = std::clamp(p.snareSnares + modAmount, 0.0f, 1.0f); break;
    case ParamId::SnareSnap:    p.snareSnap = std::clamp(p.snareSnap + modAmount, 0.0f, 1.0f); break;
    case ParamId::SnareDecay:   p.snareDecay = std::clamp(p.snareDecay + modAmount, 0.0f, 1.0f); break;
    case ParamId::SnareVelocity: p.snareVelocity = std::clamp(p.snareVelocity + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(ClapGeneratorParams& p, float modAmount, ParamId pid) noexcept {
    switch (pid) {
    case ParamId::ClapBursts:   p.clapBursts = std::clamp(p.clapBursts + modAmount, 0.0f, 1.0f); break;
    case ParamId::ClapSpread:   p.clapSpread = std::clamp(p.clapSpread + modAmount, 0.0f, 1.0f); break;
    case ParamId::ClapTone:     p.clapTone = std::clamp(p.clapTone + modAmount, 0.0f, 1.0f); break;
    case ParamId::ClapRoom:     p.clapRoom = std::clamp(p.clapRoom + modAmount, 0.0f, 1.0f); break;
    case ParamId::ClapDecay:    p.clapDecay = std::clamp(p.clapDecay + modAmount, 0.0f, 1.0f); break;
    case ParamId::ClapVelocity: p.clapVelocity = std::clamp(p.clapVelocity + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(CymbalGeneratorParams& p, float modAmount, ParamId pid) noexcept {
    switch (pid) {
    case ParamId::CymbalColor:    p.cymbalColor = std::clamp(p.cymbalColor + modAmount, 0.0f, 1.0f); break;
    case ParamId::CymbalDecay:    p.cymbalDecay = std::clamp(p.cymbalDecay + modAmount, 0.0f, 1.0f); break;
    case ParamId::CymbalWidth:    p.cymbalWidth = std::clamp(p.cymbalWidth + modAmount, 0.0f, 1.0f); break;
    case ParamId::CymbalVelocity: p.cymbalVelocity = std::clamp(p.cymbalVelocity + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(CrashGeneratorParams& p, float modAmount, ParamId pid) noexcept {
    switch (pid) {
    case ParamId::CrashColor:    p.crashColor = std::clamp(p.crashColor + modAmount, 0.0f, 1.0f); break;
    case ParamId::CrashSpread:   p.crashSpread = std::clamp(p.crashSpread + modAmount, 0.0f, 1.0f); break;
    case ParamId::CrashDecay:    p.crashDecay = std::clamp(p.crashDecay + modAmount, 0.0f, 1.0f); break;
    case ParamId::CrashVelocity: p.crashVelocity = std::clamp(p.crashVelocity + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(GateParams& p, float modAmount, ParamId pid) noexcept {
    switch (pid) {
    case ParamId::InputGain:      p.inputGain = std::clamp(p.inputGain + modAmount, 0.0f, 1.0f); break;
    case ParamId::Threshold:      p.gateThreshold = std::clamp(p.gateThreshold + modAmount, 0.0f, 1.0f); break;
    case ParamId::GateHold:       p.gateHold = std::clamp(p.gateHold + modAmount, 0.0f, 1.0f); break;
    case ParamId::GateRange:      p.gateRange = std::clamp(p.gateRange + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
    // Use same gateAttack/gateRelease — they map to Attack/Release in dynamics context.
    if (pid == ParamId::Attack) { p.gateAttack = std::clamp(p.gateAttack + modAmount, 0.0f, 1.0f); }
    if (pid == ParamId::Release) { p.gateRelease = std::clamp(p.gateRelease + modAmount, 0.0f, 1.0f); }
}

void applyModulation(CompressorParams& p, float modAmount, ParamId pid) noexcept {
    switch (pid) {
    case ParamId::InputGain:      p.inputGain = std::clamp(p.inputGain + modAmount, 0.0f, 1.0f); break;
    case ParamId::Threshold:      p.compThreshold = std::clamp(p.compThreshold + modAmount, 0.0f, 1.0f); break;
    case ParamId::CompKnee:       p.compKnee = std::clamp(p.compKnee + modAmount, 0.0f, 1.0f); break;
    case ParamId::CompMakeup:     p.compMakeup = std::clamp(p.compMakeup + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
    if (pid == ParamId::Attack) { p.compAttack = std::clamp(p.compAttack + modAmount, 0.0f, 1.0f); }
    if (pid == ParamId::Release) { p.compRelease = std::clamp(p.compRelease + modAmount, 0.0f, 1.0f); }
}

void applyModulation(ExpanderParams& p, float modAmount, ParamId pid) noexcept {
    switch (pid) {
    case ParamId::InputGain:      p.inputGain = std::clamp(p.inputGain + modAmount, 0.0f, 1.0f); break;
    case ParamId::Threshold:      p.expandThreshold = std::clamp(p.expandThreshold + modAmount, 0.0f, 1.0f); break;
    case ParamId::GateRange:      p.expandRange = std::clamp(p.expandRange + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
    if (pid == ParamId::Attack) { p.expandAttack = std::clamp(p.expandAttack + modAmount, 0.0f, 1.0f); }
    if (pid == ParamId::Release) { p.expandRelease = std::clamp(p.expandRelease + modAmount, 0.0f, 1.0f); }
}

void applyModulation(LimiterParams& p, float modAmount, ParamId pid) noexcept {
    switch (pid) {
    case ParamId::InputGain:      p.inputGain = std::clamp(p.inputGain + modAmount, 0.0f, 1.0f); break;
    case ParamId::LimitCeiling:   p.limitCeiling = std::clamp(p.limitCeiling + modAmount, 0.0f, 1.0f); break;
    case ParamId::LimitDrive:     p.limitDrive = std::clamp(p.limitDrive + modAmount, 0.0f, 1.0f); break;
    case ParamId::CompMakeup:     p.limitMakeup = std::clamp(p.limitMakeup + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
    if (pid == ParamId::Attack) { p.limitAttack = std::clamp(p.limitAttack + modAmount, 0.0f, 1.0f); }
    if (pid == ParamId::Release) { p.limitRelease = std::clamp(p.limitRelease + modAmount, 0.0f, 1.0f); }
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

void applyDspModulationAtFrame(DeviceVariantParams& params,
                               DeviceNodeKind kind,
                               const std::string& deviceId,
                               int lfoFrame,
                               int framesToProcess,
                               const float* lfoValues,
                               int lfoCount,
                               const ModulationEdgePlayback* modEdges,
                               int modEdgeCount) noexcept {
    if (lfoValues == nullptr || lfoCount <= 0 || modEdges == nullptr || deviceId.empty()) {
        return;
    }
    for (int e = 0; e < modEdgeCount; ++e) {
        const auto& edge = modEdges[e];
        if (edge.deviceId != deviceId || edge.lfoId < 0 || edge.lfoId >= lfoCount) {
            continue;
        }
        if (edge.paramId == ParamId::Gain || edge.paramId == ParamId::Pan) {
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
                                   const ModulationEdgePlayback* modEdges,
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
    if (clips == nullptr || clipCount <= 0 || node.deviceId.empty()) {
        return false;
    }
    for (int a = 0; a < clipCount; ++a) {
        if (!deviceIdMatches(clips[a].deviceId, node.deviceId)) continue;
        if (clips[a].paramId != ParamId::Gain && clips[a].paramId != ParamId::Pan) {
            switch (node.kind) {
            case DeviceNodeKind::Oscillator:
            case DeviceNodeKind::Sampler:
                return true;
            case DeviceNodeKind::SubtractiveSynth:
                return false; // per-sample inside mixSubtractiveMidiNotesBlock
            default:
                return false;
            }
        }
    }
    return false;
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
                        const ModulationEdgePlayback* modEdges,
                        int modEdgeCount,
                        const AutomationClipPlayback* automationClips,
                        int automationClipCount) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 || devices == nullptr ||
        deviceCount <= 0) {
        return;
    }

    const int framesToProcess = numFrames > kScratchFrames ? kScratchFrames : numFrames;
    auto& s = gScratch;

    const double beatsPerFrame =
        (static_cast<double>(std::max(bpm, 1)) / 60.0) / sampleRate;

    for (int deviceIndex = 0; deviceIndex < deviceCount; ++deviceIndex) {
        const DeviceNodePlayback& node = devices[deviceIndex];

        if (node.bypassed) {
            continue;
        }

        auto modulatedParams = node.params;

        for (int f = 0; f < framesToProcess; ++f) {
            s.perFrameGain[f] = node.gain;
            s.perFramePan[f] = node.pan;
        }

        const bool needsSubBlocks = nodeNeedsSubBlocks(
            node, automationClips, automationClipCount, modEdges, modEdgeCount);

        // --- Timeline automation ---
        if (automationClips != nullptr && automationClipCount > 0 && !node.deviceId.empty()) {
            for (int a = 0; a < automationClipCount; ++a) {
                const AutomationClipPlayback& ac = automationClips[a];
                if (!deviceIdMatches(ac.deviceId, node.deviceId)) continue;

                if (ac.paramId == ParamId::Gain || ac.paramId == ParamId::Pan) {
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
                        if (ac.paramId == ParamId::Gain) {
                            s.perFrameGain[f] = value;
                        } else {
                            s.perFramePan[f] = value;
                        }
                    }
                } else if (!needsSubBlocks) {
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
                    applyAutomationValue(modulatedParams, node.kind, ac.paramId, value);
                }
            }
        }

        // --- LFO modulation ---
        if (lfoValues != nullptr && lfoCount > 0 && modEdges != nullptr && modEdgeCount > 0 && !node.deviceId.empty()) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const auto& edge = modEdges[e];
                if (edge.deviceId != node.deviceId || edge.lfoId < 0 || edge.lfoId >= lfoCount) {
                    continue;
                }
                if (edge.paramId == ParamId::Gain || edge.paramId == ParamId::Pan) {
                    continue;
                }
                if (!needsSubBlocks) {
                    if (node.kind == DeviceNodeKind::SubtractiveSynth &&
                        nodeHasDspAutomation(node.deviceId, automationClips, automationClipCount)) {
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

        // Per-frame gain/pan LFO modulation
        if (lfoValues != nullptr && lfoCount > 0 && modEdges != nullptr && modEdgeCount > 0 && !node.deviceId.empty()) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const auto& edge = modEdges[e];
                if (edge.deviceId != node.deviceId || edge.lfoId < 0 || edge.lfoId >= lfoCount) {
                    continue;
                }
                if (edge.paramId == ParamId::Gain) {
                    for (int f = 0; f < framesToProcess; ++f) {
                        const float lfoOut = lfoValues[edge.lfoId * framesToProcess + f];
                        s.perFrameGain[f] = std::clamp(s.perFrameGain[f] + edge.amount * lfoOut, 0.0f, 1.0f);
                    }
                } else if (edge.paramId == ParamId::Pan) {
                    for (int f = 0; f < framesToProcess; ++f) {
                        const float lfoOut = lfoValues[edge.lfoId * framesToProcess + f];
                        s.perFramePan[f] = std::clamp(s.perFramePan[f] + edge.amount * lfoOut, 0.0f, 1.0f);
                    }
                }
            }
        }

        // --- Process device ---
        switch (node.kind) {
        case DeviceNodeKind::Oscillator: {
            if (!suppressInstruments) {
                std::memset(s.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                if (needsSubBlocks) {
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
                            addSineBlock(s.scratch + sub, subLen, sampleRate, p.frequencyHz,
                                         oscillatorPhase, kInstrumentOutputGain);
                        }
                    }
                } else {
                    auto p = std::get<OscillatorParams>(modulatedParams);
                    p.frequencyHz = midiActiveFrequencyHz(notes, noteCount,
                        playheadStartBeat, p.frequencyHz);
                    if (p.frequencyHz > 0.0f) {
                        addSineBlock(s.scratch, framesToProcess, sampleRate, p.frequencyHz,
                                     oscillatorPhase, kInstrumentOutputGain);
                    }
                }
                multiplyPerFrameGain(s.scratch, framesToProcess, s.perFrameGain);
                mixStereoPerFramePan(trackLeft, trackRight, s.scratch,
                                     framesToProcess, s.perFramePan);
            }
            break;
        }
        case DeviceNodeKind::Sampler: {
            if (!suppressInstruments) {
                const auto& baseParams = std::get<SamplerParams>(modulatedParams);
                if (baseParams.samplerPcm != nullptr && noteCount > 0) {
                    const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        s.samplerRegions[i] = SamplerMidiNoteRegion{
                            note.pitch, note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats, note.velocity,
                        };
                    }
                    std::memset(s.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));

                    BiquadState* noteFilterBase = nullptr;
                    if (samplerFilterStates != nullptr) {
                        noteFilterBase = &samplerFilterStates[deviceIndex * kMaxInstrumentRegions];
                    }
                    std::memset(s.samplerNoteFilterStates, 0, sizeof(s.samplerNoteFilterStates));
                    BiquadState* effectiveNoteFilters =
                        noteFilterBase != nullptr ? noteFilterBase : s.samplerNoteFilterStates;

                    const auto renderSampler = [&](int sub, int subLen, double subBeat,
                                                   const SamplerParams& p) {
                        mixSamplerMidiNotesBlock(s.scratch + sub, subLen, sampleRate, bpm, subBeat,
                                               s.samplerRegions, regionCount,
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
                                                   p.filterEnvAmount,
                                                   p.filterAttack,
                                                   p.filterDecay,
                                                   p.filterSustain,
                                                   p.filterRelease,
                                                   p.trimStartFrame, p.trimEndFrame,
                                                   p.regionStartFrame, p.regionEndFrame,
                                                   p.playbackMode,
                                                   nullptr,
                                                   effectiveNoteFilters,
                                                   regionCount,
                                               });
                    };
                    if (needsSubBlocks) {
                        for (int sub = 0; sub < framesToProcess; sub += kAutomationSubBlockFrames) {
                            const int subLen = std::min(kAutomationSubBlockFrames, framesToProcess - sub);
                            const double subBeat =
                                playheadStartBeat + static_cast<double>(sub) * beatsPerFrame;
                            auto subParams = dspParamsAtFrame(
                                node, subBeat, sub, framesToProcess, automationClips,
                                automationClipCount, lfoValues, lfoCount, modEdges, modEdgeCount);
                            const auto p = std::get<SamplerParams>(subParams);
                            renderSampler(sub, subLen, subBeat, p);
                        }
                    } else {
                        renderSampler(0, framesToProcess, playheadStartBeat, baseParams);
                    }
                    multiplyPerFrameGain(s.scratch, framesToProcess, s.perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, s.scratch,
                                         framesToProcess, s.perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::SubtractiveSynth: {
            if (!suppressInstruments) {
                if (noteCount > 0) {
                    const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        s.subtractiveRegions[i] = SubtractiveMidiNoteRegion{
                            note.pitch, i,
                            note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats,
                            note.velocity,
                        };
                    }
                    std::memset(s.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    SubtractiveSynthRuntime localRuntime{};
                    SubtractiveSynthRuntime& runtime =
                        subtractiveRuntimes != nullptr ? subtractiveRuntimes[deviceIndex]
                                                       : localRuntime;
                    const bool hasDspAutomation = nodeHasDspAutomation(
                        node.deviceId, automationClips, automationClipCount);
                    mixSubtractiveMidiNotesBlock(s.scratch,
                                                 framesToProcess,
                                                 sampleRate,
                                                 bpm,
                                                 playheadStartBeat,
                                                 s.subtractiveRegions,
                                                 regionCount,
                                                 std::get<SubtractiveSynthParams>(modulatedParams),
                                                 runtime,
                                                 hasDspAutomation ? automationClips : nullptr,
                                                 hasDspAutomation ? automationClipCount : 0,
                                                 hasDspAutomation ? &node.deviceId : nullptr);
                    multiplyPerFrameGain(s.scratch, framesToProcess, s.perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, s.scratch,
                                         framesToProcess, s.perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::KickGenerator: {
            if (!suppressInstruments) {
                const auto& kickParams = std::get<KickGeneratorParams>(modulatedParams);
                if (noteCount > 0) {
                    const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        s.kickRegions[i] = KickMidiNoteRegion{
                            note.pitch, i,
                            note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats,
                            note.velocity,
                        };
                    }
                    std::memset(s.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    KickGeneratorRuntime localRuntime{};
                    mixKickMidiNotesBlock(s.scratch, framesToProcess, sampleRate, bpm,
                                          playheadStartBeat, s.kickRegions, regionCount, kickParams,
                                          kickRuntimes != nullptr ? kickRuntimes[deviceIndex]
                                                                  : localRuntime);
                    multiplyPerFrameGain(s.scratch, framesToProcess, s.perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, s.scratch,
                                         framesToProcess, s.perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::SnareGenerator: {
            if (!suppressInstruments) {
                const auto& snareParams = std::get<SnareGeneratorParams>(modulatedParams);
                if (noteCount > 0) {
                    const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        s.snareRegions[i] = SnareMidiNoteRegion{
                            note.pitch, i,
                            note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats,
                            note.velocity,
                        };
                    }
                    std::memset(s.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    SnareGeneratorRuntime localRuntime{};
                    mixSnareMidiNotesBlock(s.scratch, framesToProcess, sampleRate, bpm,
                                           playheadStartBeat, s.snareRegions, regionCount, snareParams,
                                           snareRuntimes != nullptr ? snareRuntimes[deviceIndex]
                                                                    : localRuntime);
                    multiplyPerFrameGain(s.scratch, framesToProcess, s.perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, s.scratch,
                                         framesToProcess, s.perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::ClapGenerator: {
            if (!suppressInstruments) {
                const auto& clapParams = std::get<ClapGeneratorParams>(modulatedParams);
                if (noteCount > 0) {
                    const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        s.clapRegions[i] = ClapMidiNoteRegion{
                            note.pitch, i,
                            note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats,
                            note.velocity,
                        };
                    }
                    std::memset(s.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    ClapGeneratorRuntime localRuntime{};
                    mixClapMidiNotesBlock(s.scratch, framesToProcess, sampleRate, bpm,
                                          playheadStartBeat, s.clapRegions, regionCount, clapParams,
                                          clapRuntimes != nullptr ? clapRuntimes[deviceIndex]
                                                                  : localRuntime);
                    multiplyPerFrameGain(s.scratch, framesToProcess, s.perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, s.scratch,
                                         framesToProcess, s.perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::CymbalGenerator: {
            if (!suppressInstruments) {
                const auto& cymbalParams = std::get<CymbalGeneratorParams>(modulatedParams);
                if (noteCount > 0) {
                    const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        s.cymbalRegions[i] = CymbalMidiNoteRegion{
                            note.pitch, i,
                            note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats,
                            note.velocity,
                        };
                    }
                    std::memset(s.tempStereoL, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    std::memset(s.tempStereoR, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    CymbalGeneratorRuntime localRuntime{};
                    mixCymbalMidiNotesBlockStereo(s.tempStereoL, s.tempStereoR, framesToProcess,
                                                  sampleRate, bpm, playheadStartBeat,
                                                  s.cymbalRegions, regionCount, cymbalParams,
                                                  cymbalRuntimes != nullptr
                                                      ? cymbalRuntimes[deviceIndex]
                                                      : localRuntime,
                                                  s.perFrameGain);
                    for (int f = 0; f < framesToProcess; ++f) {
                        const float angle = std::clamp(s.perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
                        trackLeft[f] += s.tempStereoL[f] * std::cos(angle) +
                                        s.tempStereoR[f] * std::cos(angle);
                        trackRight[f] += s.tempStereoL[f] * std::sin(angle) +
                                         s.tempStereoR[f] * std::sin(angle);
                    }
                }
            }
            break;
        }
        case DeviceNodeKind::CrashGenerator: {
            if (!suppressInstruments) {
                const auto& crashParams = std::get<CrashGeneratorParams>(modulatedParams);
                if (noteCount > 0) {
                    const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                    for (int i = 0; i < regionCount; ++i) {
                        const MidiPlaybackNote& note = notes[i];
                        s.crashRegions[i] = CrashMidiNoteRegion{
                            note.pitch, i,
                            note.clipStartBeat, note.clipLengthBeats,
                            note.noteStartBeat, note.noteDurationBeats,
                            note.velocity,
                        };
                    }
                    std::memset(s.tempStereoL, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    std::memset(s.tempStereoR, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                    CrashGeneratorRuntime localRuntime{};
                    mixCrashMidiNotesBlockStereo(s.tempStereoL, s.tempStereoR, framesToProcess,
                                                 sampleRate, bpm, playheadStartBeat,
                                                 s.crashRegions, regionCount, crashParams,
                                                 crashRuntimes != nullptr
                                                     ? crashRuntimes[deviceIndex]
                                                     : localRuntime,
                                                 s.perFrameGain);
                    for (int f = 0; f < framesToProcess; ++f) {
                        const float angle = std::clamp(s.perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
                        trackLeft[f] += s.tempStereoL[f] * std::cos(angle) +
                                        s.tempStereoR[f] * std::cos(angle);
                        trackRight[f] += s.tempStereoL[f] * std::sin(angle) +
                                         s.tempStereoR[f] * std::sin(angle);
                    }
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
                trackLeft[f] *= s.perFrameGain[f];
                trackRight[f] *= s.perFrameGain[f];
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
                trackLeft[f] *= s.perFrameGain[f];
                trackRight[f] *= s.perFrameGain[f];
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
                trackLeft[f] *= s.perFrameGain[f];
                trackRight[f] *= s.perFrameGain[f];
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
                trackLeft[f] *= s.perFrameGain[f];
                trackRight[f] *= s.perFrameGain[f];
            }
            break;
        }
        case DeviceNodeKind::TrackGain: {
            for (int f = 0; f < framesToProcess; ++f) {
                trackLeft[f] *= s.perFrameGain[f];
                trackRight[f] *= s.perFrameGain[f];
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