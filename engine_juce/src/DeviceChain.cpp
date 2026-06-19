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

// ---- Per-type modulation overloads (uint16_t localParamId, switched by device kind) ----

void applyModulation(OscillatorParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<OscillatorParam>(localParamId)) {
    case OscillatorParam::Frequency:
        p.frequencyHz = std::max(20.0f, p.frequencyHz + modAmount * 440.0f);
        break;
    default: break;
    }
}

void applyModulation(SamplerParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<SamplerParam>(localParamId)) {
    case SamplerParam::FilterCutoff:   p.filterCutoff = std::clamp(p.filterCutoff + modAmount, 0.0f, 1.0f); break;
    case SamplerParam::FilterQ:        p.filterQ = std::clamp(p.filterQ + modAmount, 0.0f, 1.0f); break;
    case SamplerParam::Attack:         p.attack = std::clamp(p.attack + modAmount, 0.0f, 1.0f); break;
    case SamplerParam::Decay:          p.decay = std::clamp(p.decay + modAmount, 0.0f, 1.0f); break;
    case SamplerParam::Sustain:        p.sustain = std::clamp(p.sustain + modAmount, 0.0f, 1.0f); break;
    case SamplerParam::Release:        p.release = std::clamp(p.release + modAmount, 0.0f, 1.0f); break;
    case SamplerParam::RootPitch:      p.rootPitch = std::clamp(static_cast<int>(std::lround(static_cast<float>(p.rootPitch) + modAmount * 12.0f)), 0, 127); break;
    case SamplerParam::RootFineTune:   p.rootFineTune = std::clamp(p.rootFineTune + modAmount * 100.0f, -100.0f, 100.0f); break;
    case SamplerParam::FilterEnvAmount: p.filterEnvAmount = std::clamp(p.filterEnvAmount + modAmount, 0.0f, 1.0f); break;
    case SamplerParam::FilterAttack:   p.filterAttack = std::clamp(p.filterAttack + modAmount, 0.0f, 1.0f); break;
    case SamplerParam::FilterDecay:    p.filterDecay = std::clamp(p.filterDecay + modAmount, 0.0f, 1.0f); break;
    case SamplerParam::FilterSustain:  p.filterSustain = std::clamp(p.filterSustain + modAmount, 0.0f, 1.0f); break;
    case SamplerParam::FilterRelease:  p.filterRelease = std::clamp(p.filterRelease + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(TrackGainParams&, float, uint16_t) noexcept {}

void applyModulation(SubtractiveSynthParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<SubtractiveParam>(localParamId)) {
    case SubtractiveParam::FilterCutoff:      p.filterCutoff = std::clamp(p.filterCutoff + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterQ:           p.filterQ = std::clamp(p.filterQ + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterMode:        p.filterMode = std::clamp(static_cast<int>(std::lround(static_cast<float>(p.filterMode) + modAmount * 5.0f)), 0, 5); break;
    case SubtractiveParam::AmpAttack:         p.ampAttack = std::clamp(p.ampAttack + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::AmpDecay:          p.ampDecay = std::clamp(p.ampDecay + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::AmpSustain:        p.ampSustain = std::clamp(p.ampSustain + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::AmpRelease:        p.ampRelease = std::clamp(p.ampRelease + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc1Shape:         p.osc1Shape = std::clamp(p.osc1Shape + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Shape:         p.osc2Shape = std::clamp(p.osc2Shape + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc1Octave:        p.osc1Octave = std::clamp(p.osc1Octave + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc1Semi:          p.osc1Semi = std::clamp(p.osc1Semi + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc1Detune:        p.osc1Detune = std::clamp(p.osc1Detune + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Octave:        p.osc2Octave = std::clamp(p.osc2Octave + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Semi:          p.osc2Semi = std::clamp(p.osc2Semi + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Detune:        p.osc2Detune = std::clamp(p.osc2Detune + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::OscMix:            p.oscMix = std::clamp(p.oscMix + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::OscMixMode:        p.oscMixMode = std::clamp(static_cast<int>(std::lround(static_cast<float>(p.oscMixMode) + modAmount * 4.0f)), 0, 4); break;
    case SubtractiveParam::Osc1Sync:          p.osc1Sync = std::clamp(p.osc1Sync + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Sync:          p.osc2Sync = std::clamp(p.osc2Sync + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::NoiseLevel:        p.noiseLevel = std::clamp(p.noiseLevel + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::UnisonVoices:      p.unisonVoices = std::clamp(p.unisonVoices + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::UnisonDetune:      p.unisonDetune = std::clamp(p.unisonDetune + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterEnvAmount:   p.filterEnvAmount = std::clamp(p.filterEnvAmount + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterAttack:      p.filterAttack = std::clamp(p.filterAttack + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterDecay:       p.filterDecay = std::clamp(p.filterDecay + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterSustain:     p.filterSustain = std::clamp(p.filterSustain + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterRelease:     p.filterRelease = std::clamp(p.filterRelease + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::GlideMs:           p.glideMs = std::clamp(p.glideMs + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::VelocitySensitivity: p.velocitySensitivity = std::clamp(p.velocitySensitivity + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::PreHpCutoff:       p.preHpCutoff = std::clamp(p.preHpCutoff + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::PreHpRes:          p.preHpRes = std::clamp(p.preHpRes + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::PreDrive:          p.preDrive = std::clamp(p.preDrive + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::MixFeedback:       p.mixFeedback = std::clamp(p.mixFeedback + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::GlobalPitch:       p.globalPitch = std::clamp(p.globalPitch + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterKeyTrack:    p.filterKeyTrack = std::clamp(p.filterKeyTrack + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterDrive:       p.filterDrive = std::clamp(p.filterDrive + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterShaper:      p.filterShaper = std::clamp(p.filterShaper + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterFm:          p.filterFm = std::clamp(p.filterFm + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterShaperMode:  p.filterShaperMode = std::clamp(static_cast<int>(std::lround(static_cast<float>(p.filterShaperMode) + modAmount * 3.0f)), 0, 3); break;
    case SubtractiveParam::SynthLegato:       p.synthLegato = std::clamp(p.synthLegato + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::SynthMono:         p.synthMono = std::clamp(p.synthMono + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(KickGeneratorParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<KickParam>(localParamId)) {
    case KickParam::Model:    p.kickModel = std::clamp(p.kickModel + modAmount, 0.0f, 1.0f); break;
    case KickParam::Pitch:    p.kickPitch = std::clamp(p.kickPitch + modAmount, 0.0f, 1.0f); break;
    case KickParam::Punch:    p.kickPunch = std::clamp(p.kickPunch + modAmount, 0.0f, 1.0f); break;
    case KickParam::Decay:    p.kickDecay = std::clamp(p.kickDecay + modAmount, 0.0f, 1.0f); break;
    case KickParam::Click:    p.kickClick = std::clamp(p.kickClick + modAmount, 0.0f, 1.0f); break;
    case KickParam::Tone:     p.kickTone = std::clamp(p.kickTone + modAmount, 0.0f, 1.0f); break;
    case KickParam::Velocity: p.kickVelocity = std::clamp(p.kickVelocity + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(SnareGeneratorParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<SnareParam>(localParamId)) {
    case SnareParam::Model:   p.snareModel = std::clamp(p.snareModel + modAmount, 0.0f, 1.0f); break;
    case SnareParam::Body:    p.snareBody = std::clamp(p.snareBody + modAmount, 0.0f, 1.0f); break;
    case SnareParam::Ring:    p.snareRing = std::clamp(p.snareRing + modAmount, 0.0f, 1.0f); break;
    case SnareParam::Tune:    p.snareTune = std::clamp(p.snareTune + modAmount, 0.0f, 1.0f); break;
    case SnareParam::Snares:  p.snareSnares = std::clamp(p.snareSnares + modAmount, 0.0f, 1.0f); break;
    case SnareParam::Snap:    p.snareSnap = std::clamp(p.snareSnap + modAmount, 0.0f, 1.0f); break;
    case SnareParam::Decay:   p.snareDecay = std::clamp(p.snareDecay + modAmount, 0.0f, 1.0f); break;
    case SnareParam::Velocity: p.snareVelocity = std::clamp(p.snareVelocity + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(ClapGeneratorParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<ClapParam>(localParamId)) {
    case ClapParam::Bursts:   p.clapBursts = std::clamp(p.clapBursts + modAmount, 0.0f, 1.0f); break;
    case ClapParam::Spread:   p.clapSpread = std::clamp(p.clapSpread + modAmount, 0.0f, 1.0f); break;
    case ClapParam::Tone:     p.clapTone = std::clamp(p.clapTone + modAmount, 0.0f, 1.0f); break;
    case ClapParam::Room:     p.clapRoom = std::clamp(p.clapRoom + modAmount, 0.0f, 1.0f); break;
    case ClapParam::Decay:    p.clapDecay = std::clamp(p.clapDecay + modAmount, 0.0f, 1.0f); break;
    case ClapParam::Velocity: p.clapVelocity = std::clamp(p.clapVelocity + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(CymbalGeneratorParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<CymbalParam>(localParamId)) {
    case CymbalParam::Color:    p.cymbalColor = std::clamp(p.cymbalColor + modAmount, 0.0f, 1.0f); break;
    case CymbalParam::Decay:    p.cymbalDecay = std::clamp(p.cymbalDecay + modAmount, 0.0f, 1.0f); break;
    case CymbalParam::Width:    p.cymbalWidth = std::clamp(p.cymbalWidth + modAmount, 0.0f, 1.0f); break;
    case CymbalParam::Velocity: p.cymbalVelocity = std::clamp(p.cymbalVelocity + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(CrashGeneratorParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<CrashParam>(localParamId)) {
    case CrashParam::Color:    p.crashColor = std::clamp(p.crashColor + modAmount, 0.0f, 1.0f); break;
    case CrashParam::Spread:   p.crashSpread = std::clamp(p.crashSpread + modAmount, 0.0f, 1.0f); break;
    case CrashParam::Decay:    p.crashDecay = std::clamp(p.crashDecay + modAmount, 0.0f, 1.0f); break;
    case CrashParam::Velocity: p.crashVelocity = std::clamp(p.crashVelocity + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(GateParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<GateParam>(localParamId)) {
    case GateParam::InputGain:  p.inputGain = std::clamp(p.inputGain + modAmount, 0.0f, 1.0f); break;
    case GateParam::Threshold:  p.gateThreshold = std::clamp(p.gateThreshold + modAmount, 0.0f, 1.0f); break;
    case GateParam::Attack:     p.gateAttack = std::clamp(p.gateAttack + modAmount, 0.0f, 1.0f); break;
    case GateParam::Release:    p.gateRelease = std::clamp(p.gateRelease + modAmount, 0.0f, 1.0f); break;
    case GateParam::Hold:       p.gateHold = std::clamp(p.gateHold + modAmount, 0.0f, 1.0f); break;
    case GateParam::Range:      p.gateRange = std::clamp(p.gateRange + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(CompressorParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<CompressorParam>(localParamId)) {
    case CompressorParam::InputGain:  p.inputGain = std::clamp(p.inputGain + modAmount, 0.0f, 1.0f); break;
    case CompressorParam::Threshold:  p.compThreshold = std::clamp(p.compThreshold + modAmount, 0.0f, 1.0f); break;
    case CompressorParam::Ratio:      p.compRatio = std::clamp(p.compRatio + modAmount, 0.0f, 1.0f); break;
    case CompressorParam::Attack:     p.compAttack = std::clamp(p.compAttack + modAmount, 0.0f, 1.0f); break;
    case CompressorParam::Release:    p.compRelease = std::clamp(p.compRelease + modAmount, 0.0f, 1.0f); break;
    case CompressorParam::Knee:       p.compKnee = std::clamp(p.compKnee + modAmount, 0.0f, 1.0f); break;
    case CompressorParam::Makeup:     p.compMakeup = std::clamp(p.compMakeup + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(ExpanderParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<ExpanderParam>(localParamId)) {
    case ExpanderParam::InputGain:  p.inputGain = std::clamp(p.inputGain + modAmount, 0.0f, 1.0f); break;
    case ExpanderParam::Threshold:  p.expandThreshold = std::clamp(p.expandThreshold + modAmount, 0.0f, 1.0f); break;
    case ExpanderParam::Ratio:      p.expandRatio = std::clamp(p.expandRatio + modAmount, 0.0f, 1.0f); break;
    case ExpanderParam::Attack:     p.expandAttack = std::clamp(p.expandAttack + modAmount, 0.0f, 1.0f); break;
    case ExpanderParam::Release:    p.expandRelease = std::clamp(p.expandRelease + modAmount, 0.0f, 1.0f); break;
    case ExpanderParam::Range:      p.expandRange = std::clamp(p.expandRange + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(LimiterParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<LimiterParam>(localParamId)) {
    case LimiterParam::InputGain:  p.inputGain = std::clamp(p.inputGain + modAmount, 0.0f, 1.0f); break;
    case LimiterParam::Ceiling:    p.limitCeiling = std::clamp(p.limitCeiling + modAmount, 0.0f, 1.0f); break;
    case LimiterParam::Attack:     p.limitAttack = std::clamp(p.limitAttack + modAmount, 0.0f, 1.0f); break;
    case LimiterParam::Release:    p.limitRelease = std::clamp(p.limitRelease + modAmount, 0.0f, 1.0f); break;
    case LimiterParam::Drive:      p.limitDrive = std::clamp(p.limitDrive + modAmount, 0.0f, 1.0f); break;
    case LimiterParam::Makeup:     p.limitMakeup = std::clamp(p.limitMakeup + modAmount, 0.0f, 1.0f); break;
    default: break;
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
void multiplyPerFrameGain(float* buffer, int frames, const float* gain) noexcept {
    for (int f = 0; f < frames; ++f) {
        buffer[f] *= gain[f];
    }
}

/// Mix mono buffer into stereo with per-frame pan.
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
                               int lfoFrame,
                               int framesToProcess,
                               const float* lfoValues,
                               int lfoCount,
                               const ModulationEdgePlayback* modEdges,
                               int modEdgeCount) noexcept {
    if (lfoValues == nullptr || lfoCount <= 0 || modEdges == nullptr || modEdgeCount <= 0) {
        return;
    }
    for (int e = 0; e < modEdgeCount; ++e) {
        const auto& edge = modEdges[e];
        if (edge.lfoId >= static_cast<uint16_t>(lfoCount)) continue;
        const uint16_t pid = edge.localParamId;
        if (pid == static_cast<uint16_t>(CommonParam::Gain) ||
            pid == static_cast<uint16_t>(CommonParam::Pan)) continue;
        const float lfoOut = lfoValues[edge.lfoId * framesToProcess + lfoFrame];
        const float modAmount = edge.amount * lfoOut;
        std::visit([&](auto& p) { applyModulation(p, modAmount, pid); }, params);
    }
}

DeviceVariantParams dspParamsAtFrame(const DeviceNodePlayback& node,
                                   int deviceIndex,
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
    applyDspAutomationAtBeat(params, node.kind, static_cast<uint16_t>(deviceIndex), beat,
                             automationClips, automationClipCount);
    applyDspModulationAtFrame(params, node.kind, lfoFrame, framesToProcess,
                                lfoValues, lfoCount, modEdges, modEdgeCount);
    return params;
}

bool nodeNeedsSubBlocks(const DeviceNodePlayback& node,
                        int deviceIndex,
                        const AutomationClipPlayback* clips,
                        int clipCount,
                        const ModulationEdgePlayback* modEdges,
                        int modEdgeCount) noexcept {
    // Automation clips — check via deviceIndex
    if (clips != nullptr && clipCount > 0) {
        for (int a = 0; a < clipCount; ++a) {
            if (clips[a].deviceIndex != static_cast<uint16_t>(deviceIndex)) continue;
            const uint16_t pid = clips[a].localParamId;
            if (pid != static_cast<uint16_t>(CommonParam::Gain) &&
                pid != static_cast<uint16_t>(CommonParam::Pan)) {
                return true;
            }
        }
    }
    // Modulation edges — check via deviceIndex
    if (modEdges != nullptr && modEdgeCount > 0) {
        for (int e = 0; e < modEdgeCount; ++e) {
            if (modEdges[e].deviceIndex != static_cast<uint16_t>(deviceIndex)) continue;
            const uint16_t pid = modEdges[e].localParamId;
            if (pid != static_cast<uint16_t>(CommonParam::Gain) &&
                pid != static_cast<uint16_t>(CommonParam::Pan)) {
                return true;
            }
        }
    }
    return false;
}

bool nodeUsesDspAutomationSubBlocks(const DeviceNodePlayback& node,
                                    int deviceIndex,
                                    const AutomationClipPlayback* clips,
                                    int clipCount) noexcept {
    if (clips == nullptr || clipCount <= 0) return false;
    for (int a = 0; a < clipCount; ++a) {
        if (clips[a].deviceIndex != static_cast<uint16_t>(deviceIndex)) continue;
        const uint16_t pid = clips[a].localParamId;
        if (pid != static_cast<uint16_t>(CommonParam::Gain) &&
            pid != static_cast<uint16_t>(CommonParam::Pan)) {
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

// =======================================================================
// Public API
// =======================================================================

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
        if (!isMidiNoteActive(notes[i], playheadBeat)) continue;
        pitch = notes[i].pitch;
    }
    if (pitch >= 0) return midiNoteToHz(pitch);
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
        if (node.bypassed) continue;

        auto modulatedParams = node.params;
        for (int f = 0; f < framesToProcess; ++f) {
            s.perFrameGain[f] = node.gain;
            s.perFramePan[f] = node.pan;
        }

        const uint16_t di = static_cast<uint16_t>(deviceIndex);
        const bool needsSubBlocks = nodeNeedsSubBlocks(
            node, deviceIndex, automationClips, automationClipCount, modEdges, modEdgeCount);

        // --- Timeline automation ---
        if (automationClips != nullptr && automationClipCount > 0) {
            for (int a = 0; a < automationClipCount; ++a) {
                const auto& ac = automationClips[a];
                if (ac.deviceIndex != di) continue;

                if (ac.localParamId == static_cast<uint16_t>(CommonParam::Gain) ||
                    ac.localParamId == static_cast<uint16_t>(CommonParam::Pan)) {
                    const bool isGain = ac.localParamId == static_cast<uint16_t>(CommonParam::Gain);
                    for (int f = 0; f < framesToProcess; ++f) {
                        const double beat = playheadStartBeat + static_cast<double>(f) * beatsPerFrame;
                        if (beat < static_cast<double>(ac.clipStartBeat) ||
                            beat >= static_cast<double>(ac.clipStartBeat + ac.clipLengthBeats)) {
                            continue;
                        }
                        const float beatInClip = static_cast<float>(beat - static_cast<double>(ac.clipStartBeat));
                        const float val = evaluateAutomationEnvelope(ac.points, ac.pointCount, beatInClip);
                        if (isGain) s.perFrameGain[f] = val;
                        else s.perFramePan[f] = val;
                    }
                } else if (!needsSubBlocks) {
                    if (node.kind == DeviceNodeKind::SubtractiveSynth &&
                        nodeHasDspAutomation(di, automationClips, automationClipCount)) {
                        continue;
                    }
                    const double beat = playheadStartBeat;
                    if (beat < static_cast<double>(ac.clipStartBeat) ||
                        beat >= static_cast<double>(ac.clipStartBeat + ac.clipLengthBeats)) continue;
                    const float beatInClip = static_cast<float>(beat - static_cast<double>(ac.clipStartBeat));
                    const float val = evaluateAutomationEnvelope(ac.points, ac.pointCount, beatInClip);
                    applyAutomationValue(modulatedParams, node.kind, ac.localParamId, val);
                }
            }
        }

        // --- LFO modulation (DSP params) ---
        if (lfoValues != nullptr && lfoCount > 0 && modEdges != nullptr && modEdgeCount > 0) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const auto& edge = modEdges[e];
                if (edge.deviceIndex != di || edge.lfoId >= static_cast<uint16_t>(lfoCount)) continue;
                const uint16_t pid = edge.localParamId;
                if (pid == static_cast<uint16_t>(CommonParam::Gain) ||
                    pid == static_cast<uint16_t>(CommonParam::Pan)) continue;
                if (!needsSubBlocks) {
                    if (node.kind == DeviceNodeKind::SubtractiveSynth &&
                        nodeHasDspAutomation(di, automationClips, automationClipCount)) continue;
                    const float lfoOut = lfoValues[edge.lfoId * framesToProcess];
                    const float modAmount = edge.amount * lfoOut;
                    std::visit([&](auto& params) {
                        applyModulation(params, modAmount, pid);
                    }, modulatedParams);
                }
            }
        }

        // --- Per-frame gain/pan LFO modulation ---
        if (lfoValues != nullptr && lfoCount > 0 && modEdges != nullptr && modEdgeCount > 0) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const auto& edge = modEdges[e];
                if (edge.deviceIndex != di || edge.lfoId >= static_cast<uint16_t>(lfoCount)) continue;
                const uint16_t pid = edge.localParamId;
                if (pid == static_cast<uint16_t>(CommonParam::Gain)) {
                    for (int f = 0; f < framesToProcess; ++f) {
                        const float lfoOut = lfoValues[edge.lfoId * framesToProcess + f];
                        s.perFrameGain[f] = std::clamp(s.perFrameGain[f] + edge.amount * lfoOut, 0.0f, 1.0f);
                    }
                } else if (pid == static_cast<uint16_t>(CommonParam::Pan)) {
                    for (int f = 0; f < framesToProcess; ++f) {
                        const float lfoOut = lfoValues[edge.lfoId * framesToProcess + f];
                        s.perFramePan[f] = std::clamp(s.perFramePan[f] + edge.amount * lfoOut, 0.0f, 1.0f);
                    }
                }
            }
        }

        // --- Process device --- (rest unchanged from before)
        switch (node.kind) {
        case DeviceNodeKind::Oscillator: {
            if (!suppressInstruments) {
                std::memset(s.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                if (needsSubBlocks) {
                    for (int sub = 0; sub < framesToProcess; sub += kAutomationSubBlockFrames) {
                        const int subLen = std::min(kAutomationSubBlockFrames, framesToProcess - sub);
                        const double subBeat = playheadStartBeat + static_cast<double>(sub) * beatsPerFrame;
                        auto subParams = dspParamsAtFrame(node, deviceIndex, subBeat, sub, framesToProcess,
                            automationClips, automationClipCount, lfoValues, lfoCount, modEdges, modEdgeCount);
                        auto p = std::get<OscillatorParams>(subParams);
                        p.frequencyHz = midiActiveFrequencyHz(notes, noteCount, subBeat, p.frequencyHz);
                        if (p.frequencyHz > 0.0f) {
                            addSineBlock(s.scratch + sub, subLen, sampleRate, p.frequencyHz,
                                         oscillatorPhase, kInstrumentOutputGain);
                        }
                    }
                } else {
                    auto p = std::get<OscillatorParams>(modulatedParams);
                    p.frequencyHz = midiActiveFrequencyHz(notes, noteCount, playheadStartBeat, p.frequencyHz);
                    if (p.frequencyHz > 0.0f) {
                        addSineBlock(s.scratch, framesToProcess, sampleRate, p.frequencyHz,
                                     oscillatorPhase, kInstrumentOutputGain);
                    }
                }
                multiplyPerFrameGain(s.scratch, framesToProcess, s.perFrameGain);
                mixStereoPerFramePan(trackLeft, trackRight, s.scratch, framesToProcess, s.perFramePan);
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

                    const auto render = [&](int sub, int subLen, double subBeat, const SamplerParams& p) {
                        mixSamplerMidiNotesBlock(s.scratch + sub, subLen, sampleRate, bpm, subBeat,
                            s.samplerRegions, regionCount, SamplerInstrumentPlayback{
                                p.samplerPcm, p.samplerFrameCount, p.samplerPcmSampleRate,
                                kInstrumentOutputGain, p.rootPitch, p.rootFineTune,
                                p.attack, p.decay, p.sustain, p.release,
                                p.filterCutoff, p.filterQ, p.filterMode,
                                p.filterEnvAmount, p.filterAttack, p.filterDecay, p.filterSustain, p.filterRelease,
                                p.trimStartFrame, p.trimEndFrame, p.regionStartFrame, p.regionEndFrame,
                                p.playbackMode, nullptr, effectiveNoteFilters, regionCount,
                            });
                    };
                    if (needsSubBlocks) {
                        for (int sub = 0; sub < framesToProcess; sub += kAutomationSubBlockFrames) {
                            const int subLen = std::min(kAutomationSubBlockFrames, framesToProcess - sub);
                            const double subBeat = playheadStartBeat + static_cast<double>(sub) * beatsPerFrame;
                            auto subParams = dspParamsAtFrame(node, deviceIndex, subBeat, sub, framesToProcess,
                                automationClips, automationClipCount, lfoValues, lfoCount, modEdges, modEdgeCount);
                            const auto p = std::get<SamplerParams>(subParams);
                            render(sub, subLen, subBeat, p);
                        }
                    } else {
                        render(0, framesToProcess, playheadStartBeat, baseParams);
                    }
                    multiplyPerFrameGain(s.scratch, framesToProcess, s.perFrameGain);
                    mixStereoPerFramePan(trackLeft, trackRight, s.scratch, framesToProcess, s.perFramePan);
                }
            }
            break;
        }
        case DeviceNodeKind::SubtractiveSynth: {
            if (!suppressInstruments && noteCount > 0) {
                const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                for (int i = 0; i < regionCount; ++i) {
                    const MidiPlaybackNote& note = notes[i];
                    s.subtractiveRegions[i] = SubtractiveMidiNoteRegion{note.pitch, i,
                        note.clipStartBeat, note.clipLengthBeats,
                        note.noteStartBeat, note.noteDurationBeats, note.velocity};
                }
                std::memset(s.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                SubtractiveSynthRuntime localRuntime{};
                auto& runtime = subtractiveRuntimes != nullptr ? subtractiveRuntimes[deviceIndex] : localRuntime;
                const bool hasAuto = nodeHasDspAutomation(di, automationClips, automationClipCount);
                mixSubtractiveMidiNotesBlock(s.scratch, framesToProcess, sampleRate, bpm, playheadStartBeat,
                    s.subtractiveRegions, regionCount, std::get<SubtractiveSynthParams>(modulatedParams), runtime,
                    hasAuto ? automationClips : nullptr, hasAuto ? automationClipCount : 0,
                    hasAuto ? &di : nullptr);
                multiplyPerFrameGain(s.scratch, framesToProcess, s.perFrameGain);
                mixStereoPerFramePan(trackLeft, trackRight, s.scratch, framesToProcess, s.perFramePan);
            }
            break;
        }
        case DeviceNodeKind::KickGenerator: {
            if (!suppressInstruments && noteCount > 0) {
                const auto& kp = std::get<KickGeneratorParams>(modulatedParams);
                const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                for (int i = 0; i < regionCount; ++i) {
                    const MidiPlaybackNote& note = notes[i];
                    s.kickRegions[i] = KickMidiNoteRegion{note.pitch, i,
                        note.clipStartBeat, note.clipLengthBeats,
                        note.noteStartBeat, note.noteDurationBeats, note.velocity};
                }
                std::memset(s.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                KickGeneratorRuntime localRuntime{};
                mixKickMidiNotesBlock(s.scratch, framesToProcess, sampleRate, bpm, playheadStartBeat,
                    s.kickRegions, regionCount, kp,
                    kickRuntimes != nullptr ? kickRuntimes[deviceIndex] : localRuntime);
                multiplyPerFrameGain(s.scratch, framesToProcess, s.perFrameGain);
                mixStereoPerFramePan(trackLeft, trackRight, s.scratch, framesToProcess, s.perFramePan);
            }
            break;
        }
        case DeviceNodeKind::SnareGenerator: {
            if (!suppressInstruments && noteCount > 0) {
                const auto& sp = std::get<SnareGeneratorParams>(modulatedParams);
                const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                for (int i = 0; i < regionCount; ++i) {
                    const MidiPlaybackNote& note = notes[i];
                    s.snareRegions[i] = SnareMidiNoteRegion{note.pitch, i,
                        note.clipStartBeat, note.clipLengthBeats,
                        note.noteStartBeat, note.noteDurationBeats, note.velocity};
                }
                std::memset(s.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                SnareGeneratorRuntime localRuntime{};
                mixSnareMidiNotesBlock(s.scratch, framesToProcess, sampleRate, bpm, playheadStartBeat,
                    s.snareRegions, regionCount, sp,
                    snareRuntimes != nullptr ? snareRuntimes[deviceIndex] : localRuntime);
                multiplyPerFrameGain(s.scratch, framesToProcess, s.perFrameGain);
                mixStereoPerFramePan(trackLeft, trackRight, s.scratch, framesToProcess, s.perFramePan);
            }
            break;
        }
        case DeviceNodeKind::ClapGenerator: {
            if (!suppressInstruments && noteCount > 0) {
                const auto& cp = std::get<ClapGeneratorParams>(modulatedParams);
                const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                for (int i = 0; i < regionCount; ++i) {
                    const MidiPlaybackNote& note = notes[i];
                    s.clapRegions[i] = ClapMidiNoteRegion{note.pitch, i,
                        note.clipStartBeat, note.clipLengthBeats,
                        note.noteStartBeat, note.noteDurationBeats, note.velocity};
                }
                std::memset(s.scratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                ClapGeneratorRuntime localRuntime{};
                mixClapMidiNotesBlock(s.scratch, framesToProcess, sampleRate, bpm, playheadStartBeat,
                    s.clapRegions, regionCount, cp,
                    clapRuntimes != nullptr ? clapRuntimes[deviceIndex] : localRuntime);
                multiplyPerFrameGain(s.scratch, framesToProcess, s.perFrameGain);
                mixStereoPerFramePan(trackLeft, trackRight, s.scratch, framesToProcess, s.perFramePan);
            }
            break;
        }
        case DeviceNodeKind::CymbalGenerator: {
            if (!suppressInstruments && noteCount > 0) {
                const auto& cyp = std::get<CymbalGeneratorParams>(modulatedParams);
                const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                for (int i = 0; i < regionCount; ++i) {
                    const MidiPlaybackNote& note = notes[i];
                    s.cymbalRegions[i] = CymbalMidiNoteRegion{note.pitch, i,
                        note.clipStartBeat, note.clipLengthBeats,
                        note.noteStartBeat, note.noteDurationBeats, note.velocity};
                }
                std::memset(s.tempStereoL, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                std::memset(s.tempStereoR, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                CymbalGeneratorRuntime localRuntime{};
                mixCymbalMidiNotesBlockStereo(s.tempStereoL, s.tempStereoR, framesToProcess, sampleRate, bpm,
                    playheadStartBeat, s.cymbalRegions, regionCount, cyp,
                    cymbalRuntimes != nullptr ? cymbalRuntimes[deviceIndex] : localRuntime, s.perFrameGain);
                for (int f = 0; f < framesToProcess; ++f) {
                    const float angle = std::clamp(s.perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
                    trackLeft[f] += s.tempStereoL[f] * std::cos(angle) + s.tempStereoR[f] * std::cos(angle);
                    trackRight[f] += s.tempStereoL[f] * std::sin(angle) + s.tempStereoR[f] * std::sin(angle);
                }
            }
            break;
        }
        case DeviceNodeKind::CrashGenerator: {
            if (!suppressInstruments && noteCount > 0) {
                const auto& crp = std::get<CrashGeneratorParams>(modulatedParams);
                const int regionCount = noteCount > kMaxInstrumentRegions ? kMaxInstrumentRegions : noteCount;
                for (int i = 0; i < regionCount; ++i) {
                    const MidiPlaybackNote& note = notes[i];
                    s.crashRegions[i] = CrashMidiNoteRegion{note.pitch, i,
                        note.clipStartBeat, note.clipLengthBeats,
                        note.noteStartBeat, note.noteDurationBeats, note.velocity};
                }
                std::memset(s.tempStereoL, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                std::memset(s.tempStereoR, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
                CrashGeneratorRuntime localRuntime{};
                mixCrashMidiNotesBlockStereo(s.tempStereoL, s.tempStereoR, framesToProcess, sampleRate, bpm,
                    playheadStartBeat, s.crashRegions, regionCount, crp,
                    crashRuntimes != nullptr ? crashRuntimes[deviceIndex] : localRuntime, s.perFrameGain);
                for (int f = 0; f < framesToProcess; ++f) {
                    const float angle = std::clamp(s.perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
                    trackLeft[f] += s.tempStereoL[f] * std::cos(angle) + s.tempStereoR[f] * std::cos(angle);
                    trackRight[f] += s.tempStereoL[f] * std::sin(angle) + s.tempStereoR[f] * std::sin(angle);
                }
            }
            break;
        }
        case DeviceNodeKind::Gate: {
            auto p = std::get<GateParams>(modulatedParams);
            DynamicsRuntime localRuntime{};
            auto& runtime = dynamicsRuntimes != nullptr ? dynamicsRuntimes[deviceIndex] : localRuntime;
            applyStereoScalarGain(trackLeft, trackRight, framesToProcess, std::clamp(p.inputGain, 0.0f, 1.0f));
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
            auto& runtime = dynamicsRuntimes != nullptr ? dynamicsRuntimes[deviceIndex] : localRuntime;
            applyStereoScalarGain(trackLeft, trackRight, framesToProcess, std::clamp(p.inputGain, 0.0f, 1.0f));
            const float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
            processCompressorStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p, runtime);
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
            auto& runtime = dynamicsRuntimes != nullptr ? dynamicsRuntimes[deviceIndex] : localRuntime;
            applyStereoScalarGain(trackLeft, trackRight, framesToProcess, std::clamp(p.inputGain, 0.0f, 1.0f));
            const float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
            processExpanderStereoBlock(trackLeft, trackRight, framesToProcess, sampleRate, p, runtime);
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
            auto& runtime = dynamicsRuntimes != nullptr ? dynamicsRuntimes[deviceIndex] : localRuntime;
            applyStereoScalarGain(trackLeft, trackRight, framesToProcess, std::clamp(p.inputGain, 0.0f, 1.0f));
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
        default:
            break;
        }
    }
}

} // namespace audioapp