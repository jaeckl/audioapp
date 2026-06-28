#include "audioapp/DeviceChainAutomationModulation.hpp"

#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/MasterMix.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/SamplePlaybackAlgorithm.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"
#include "audioapp/KickAlgorithm.hpp"
#include "audioapp/SnareAlgorithm.hpp"
#include "audioapp/ClapAlgorithm.hpp"
#include "audioapp/CymbalAlgorithm.hpp"
#include "audioapp/CrashAlgorithm.hpp"
#include "audioapp/DynamicsProcessor.hpp"
#include "audioapp/WavetableSynthAlgorithm.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp::DeviceChainAutomationModulation {

// ---- Per-type modulation overloads (uint16_t localParamId, switched by device kind) ----

void applyModulation(OscillatorParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<OscillatorParam>(unpackParamId(localParamId))) {
    case OscillatorParam::Frequency:
        p.frequencyHz = std::max(20.0f, p.frequencyHz + modAmount * 440.0f);
        break;
    default: break;
    }
}

void applyModulation(SamplerParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<SamplerParam>(unpackParamId(localParamId))) {
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
void applyModulation(DelayParamsPlayback&, float, uint16_t) noexcept {}
void applyModulation(ReverbParamsPlayback&, float, uint16_t) noexcept {}
void applyModulation(ChorusParamsPlayback&, float, uint16_t) noexcept {}
void applyModulation(PhaserParamsPlayback&, float, uint16_t) noexcept {}
void applyModulation(BitcrusherParamsPlayback&, float, uint16_t) noexcept {}
void applyModulation(DistortionParamsPlayback&, float, uint16_t) noexcept {}
void applyModulation(TremoloParamsPlayback&, float, uint16_t) noexcept {}
void applyModulation(FilterParams& p, float modAmount, uint16_t localParamId) noexcept {
    // The FilterParams playback struct stores physical units (Hz, Q, mode
    // index). `modAmount` is the LFO output in roughly [-1, 1] multiplied by
    // the edge amount. Scale each field to physical units so a full-range
    // LFO produces a musically useful sweep (one octave of cutoff, ±5 Q,
    // all 4 modes).
    switch (static_cast<FilterParam>(unpackParamId(localParamId))) {
    case FilterParam::Cutoff:
        p.cutoffHz = std::clamp(p.cutoffHz + modAmount * 1000.0f, 20.0f, 20000.0f);
        break;
    case FilterParam::Resonance:
        p.resonance = std::clamp(p.resonance + modAmount * 5.0f, 0.1f, 20.0f);
        break;
    case FilterParam::Mode:
        // Sweep the filter mode. Quantise to the nearest of 4 modes by
        // treating the int as a continuous "mode position" (0..3), adding
        // `modAmount * 3` (so a full-range LFO sweeps all 4 modes), then
        // rounding and clamping. Matches the UI's 4-button quantisation.
        {
            const float basePos = static_cast<float>(p.filterMode);
            const int nextIdx = static_cast<int>(std::clamp(
                static_cast<float>(std::lround(basePos + modAmount * 3.0f)),
                0.0f, 3.0f));
            p.filterMode = nextIdx;
        }
        break;
    }
}

void applyModulation(FourBandEqParams& p, float modAmount, uint16_t localParamId) noexcept {
    // Same scaling pattern as Filter: physical-unit fields with full-range
    // LFO producing a musically useful sweep.
    switch (static_cast<FourBandEqParam>(unpackParamId(localParamId))) {
    case FourBandEqParam::Band1Freq: p.bands[0].frequencyHz = std::clamp(p.bands[0].frequencyHz + modAmount * 1000.0f, 20.0f, 20000.0f); break;
    case FourBandEqParam::Band1Gain: p.bands[0].gainDb      = std::clamp(p.bands[0].gainDb      + modAmount * 12.0f,  -24.0f,  24.0f); break;
    case FourBandEqParam::Band1Q:    p.bands[0].q           = std::clamp(p.bands[0].q           + modAmount * 5.0f,    0.1f,  20.0f); break;
    case FourBandEqParam::Band2Freq: p.bands[1].frequencyHz = std::clamp(p.bands[1].frequencyHz + modAmount * 1000.0f, 20.0f, 20000.0f); break;
    case FourBandEqParam::Band2Gain: p.bands[1].gainDb      = std::clamp(p.bands[1].gainDb      + modAmount * 12.0f,  -24.0f,  24.0f); break;
    case FourBandEqParam::Band2Q:    p.bands[1].q           = std::clamp(p.bands[1].q           + modAmount * 5.0f,    0.1f,  20.0f); break;
    case FourBandEqParam::Band3Freq: p.bands[2].frequencyHz = std::clamp(p.bands[2].frequencyHz + modAmount * 1000.0f, 20.0f, 20000.0f); break;
    case FourBandEqParam::Band3Gain: p.bands[2].gainDb      = std::clamp(p.bands[2].gainDb      + modAmount * 12.0f,  -24.0f,  24.0f); break;
    case FourBandEqParam::Band3Q:    p.bands[2].q           = std::clamp(p.bands[2].q           + modAmount * 5.0f,    0.1f,  20.0f); break;
    case FourBandEqParam::Band4Freq: p.bands[3].frequencyHz = std::clamp(p.bands[3].frequencyHz + modAmount * 1000.0f, 20.0f, 20000.0f); break;
    case FourBandEqParam::Band4Gain: p.bands[3].gainDb      = std::clamp(p.bands[3].gainDb      + modAmount * 12.0f,  -24.0f,  24.0f); break;
    case FourBandEqParam::Band4Q:    p.bands[3].q           = std::clamp(p.bands[3].q           + modAmount * 5.0f,    0.1f,  20.0f); break;
    }
}

void applyModulation(FrequencyShifterParams& p, float modAmount, uint16_t localParamId) noexcept {
    if (static_cast<FrequencyShifterParam>(unpackParamId(localParamId)) == FrequencyShifterParam::Shift) {
        // Shift is a signed Hz offset in [-2000, 2000]; full-range LFO sweeps 2 kHz.
        p.shiftHz = std::clamp(p.shiftHz + modAmount * 1000.0f, -2000.0f, 2000.0f);
    }
}

void applyModulation(ResonatorBankParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<ResonatorBankParam>(unpackParamId(localParamId))) {
    case ResonatorBankParam::Root:
        p.rootHz = std::clamp(p.rootHz * std::pow(2.0f, modAmount), 32.7032f, 2093.005f); break;
    case ResonatorBankParam::Spread:
        p.spread = std::clamp(p.spread + modAmount * 0.5f, 0.5f, 1.5f); break;
    case ResonatorBankParam::Decay:
        p.decaySeconds = std::clamp(p.decaySeconds * std::pow(4.0f, modAmount), 0.08f, 12.0f); break;
    case ResonatorBankParam::Damping:
        p.damping = std::clamp(p.damping + modAmount, 0.0f, 1.0f); break;
    case ResonatorBankParam::Color:
        p.colorDbPerOctave = std::clamp(p.colorDbPerOctave + modAmount * 12.0f, -12.0f, 12.0f); break;
    case ResonatorBankParam::Width:
        p.width = std::clamp(p.width + modAmount, 0.0f, 2.0f); break;
    case ResonatorBankParam::Mix:
        p.mix = std::clamp(p.mix + modAmount, 0.0f, 1.0f); break;
    }
}

void applyModulation(SubtractiveSynthParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<SubtractiveParam>(unpackParamId(localParamId))) {
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
    switch (static_cast<KickParam>(unpackParamId(localParamId))) {
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
    switch (static_cast<SnareParam>(unpackParamId(localParamId))) {
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
    switch (static_cast<ClapParam>(unpackParamId(localParamId))) {
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
    switch (static_cast<CymbalParam>(unpackParamId(localParamId))) {
    case CymbalParam::Color:    p.cymbalColor = std::clamp(p.cymbalColor + modAmount, 0.0f, 1.0f); break;
    case CymbalParam::Decay:    p.cymbalDecay = std::clamp(p.cymbalDecay + modAmount, 0.0f, 1.0f); break;
    case CymbalParam::Width:    p.cymbalWidth = std::clamp(p.cymbalWidth + modAmount, 0.0f, 1.0f); break;
    case CymbalParam::Velocity: p.cymbalVelocity = std::clamp(p.cymbalVelocity + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(CrashGeneratorParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<CrashParam>(unpackParamId(localParamId))) {
    case CrashParam::Color:    p.crashColor = std::clamp(p.crashColor + modAmount, 0.0f, 1.0f); break;
    case CrashParam::Spread:   p.crashSpread = std::clamp(p.crashSpread + modAmount, 0.0f, 1.0f); break;
    case CrashParam::Decay:    p.crashDecay = std::clamp(p.crashDecay + modAmount, 0.0f, 1.0f); break;
    case CrashParam::Velocity: p.crashVelocity = std::clamp(p.crashVelocity + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(GateParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<GateParam>(unpackParamId(localParamId))) {
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
    switch (static_cast<CompressorParam>(unpackParamId(localParamId))) {
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
    switch (static_cast<ExpanderParam>(unpackParamId(localParamId))) {
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
    switch (static_cast<LimiterParam>(unpackParamId(localParamId))) {
    case LimiterParam::InputGain:  p.inputGain = std::clamp(p.inputGain + modAmount, 0.0f, 1.0f); break;
    case LimiterParam::Ceiling:    p.limitCeiling = std::clamp(p.limitCeiling + modAmount, 0.0f, 1.0f); break;
    case LimiterParam::Attack:     p.limitAttack = std::clamp(p.limitAttack + modAmount, 0.0f, 1.0f); break;
    case LimiterParam::Release:    p.limitRelease = std::clamp(p.limitRelease + modAmount, 0.0f, 1.0f); break;
    case LimiterParam::Drive:      p.limitDrive = std::clamp(p.limitDrive + modAmount, 0.0f, 1.0f); break;
    case LimiterParam::Makeup:     p.limitMakeup = std::clamp(p.limitMakeup + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(PhaseModSynthParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<PhaseModSynthParam>(unpackParamId(localParamId))) {
    case PhaseModSynthParam::Op1Level:         p.operators[0].level = std::clamp(p.operators[0].level + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op1Fine:          p.operators[0].fine = std::clamp(p.operators[0].fine + modAmount * 100.0f, -50.0f, 50.0f); break;
    case PhaseModSynthParam::Op1Attack:        p.operators[0].attack = std::clamp(p.operators[0].attack + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op1Decay:         p.operators[0].decay = std::clamp(p.operators[0].decay + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op1Sustain:       p.operators[0].sustain = std::clamp(p.operators[0].sustain + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op1Release:       p.operators[0].release = std::clamp(p.operators[0].release + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2Level:         p.operators[1].level = std::clamp(p.operators[1].level + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2Fine:          p.operators[1].fine = std::clamp(p.operators[1].fine + modAmount * 100.0f, -50.0f, 50.0f); break;
    case PhaseModSynthParam::Op2Attack:        p.operators[1].attack = std::clamp(p.operators[1].attack + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2Decay:         p.operators[1].decay = std::clamp(p.operators[1].decay + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2Sustain:       p.operators[1].sustain = std::clamp(p.operators[1].sustain + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2Release:       p.operators[1].release = std::clamp(p.operators[1].release + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3Level:         p.operators[2].level = std::clamp(p.operators[2].level + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3Fine:          p.operators[2].fine = std::clamp(p.operators[2].fine + modAmount * 100.0f, -50.0f, 50.0f); break;
    case PhaseModSynthParam::Op3Attack:        p.operators[2].attack = std::clamp(p.operators[2].attack + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3Decay:         p.operators[2].decay = std::clamp(p.operators[2].decay + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3Sustain:       p.operators[2].sustain = std::clamp(p.operators[2].sustain + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3Release:       p.operators[2].release = std::clamp(p.operators[2].release + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4Level:         p.operators[3].level = std::clamp(p.operators[3].level + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4Fine:          p.operators[3].fine = std::clamp(p.operators[3].fine + modAmount * 100.0f, -50.0f, 50.0f); break;
    case PhaseModSynthParam::Op4Attack:        p.operators[3].attack = std::clamp(p.operators[3].attack + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4Decay:         p.operators[3].decay = std::clamp(p.operators[3].decay + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4Sustain:       p.operators[3].sustain = std::clamp(p.operators[3].sustain + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4Release:       p.operators[3].release = std::clamp(p.operators[3].release + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::FilterCutoff:     p.filterCutoff = std::clamp(p.filterCutoff + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::FilterQ:          p.filterQ = std::clamp(p.filterQ + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::FilterEnvAmount:  p.filterEnvAmount = std::clamp(p.filterEnvAmount + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::AmpAttack:        p.ampAttack = std::clamp(p.ampAttack + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::AmpDecay:         p.ampDecay = std::clamp(p.ampDecay + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::AmpSustain:       p.ampSustain = std::clamp(p.ampSustain + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::AmpRelease:       p.ampRelease = std::clamp(p.ampRelease + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Feedback:         p.feedback = std::clamp(p.feedback + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::MasterVol:        p.masterVol = std::clamp(p.masterVol + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::LfoRate:          p.lfoRate = std::clamp(p.lfoRate + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::LfoAmount:        p.lfoAmount = std::clamp(p.lfoAmount + modAmount, 0.0f, 1.0f); break;
    case PhaseModSynthParam::VibratoDepth:     p.vibratoDepth = std::clamp(p.vibratoDepth + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
}

void applyModulation(WavetableSynthParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<WavetableParam>(unpackParamId(localParamId))) {
    case WavetableParam::WtPosition:      p.wtPosition = std::clamp(p.wtPosition + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::WtOctave:        p.wtOctave = std::clamp(p.wtOctave + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::WtSemitone:      p.wtSemitone = std::clamp(p.wtSemitone + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::WtFine:          p.wtFine = std::clamp(p.wtFine + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::WtUnison:        p.wtUnison = std::clamp(p.wtUnison + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::WtDetune:        p.wtDetune = std::clamp(p.wtDetune + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::FilterCutoff:    p.filterCutoff = std::clamp(p.filterCutoff + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::FilterResonance: p.filterResonance = std::clamp(p.filterResonance + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::FilterEnvAmount: p.filterEnvAmount = std::clamp(p.filterEnvAmount + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::AmpAttack:       p.ampAttack = std::clamp(p.ampAttack + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::AmpDecay:        p.ampDecay = std::clamp(p.ampDecay + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::AmpSustain:      p.ampSustain = std::clamp(p.ampSustain + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::AmpRelease:      p.ampRelease = std::clamp(p.ampRelease + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::FilterAttack:    p.filterAttack = std::clamp(p.filterAttack + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::FilterDecay:     p.filterDecay = std::clamp(p.filterDecay + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::FilterSustain:   p.filterSustain = std::clamp(p.filterSustain + modAmount, 0.0f, 1.0f); break;
    case WavetableParam::FilterRelease:   p.filterRelease = std::clamp(p.filterRelease + modAmount, 0.0f, 1.0f); break;
    default: break;
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
        // Common gain/pan are handled by the device-chain loop. With the
        // encoded kind tag, the values 0 and 1 only mean Common::Gain/Pan;
        // SubtractiveSynth::FilterCutoff is 0x3000 etc. and is no longer
        // accidentally skipped here.
        if (pid == kEncodedCommonGain || pid == kEncodedCommonPan) continue;
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
            // Encoded kind tag prevents CommonParam::Gain (0) from being
            // confused with SubtractiveSynth::FilterCutoff (0x3000), so
            // the encoded Common gain/pan are the only ones to skip.
            if (pid != kEncodedCommonGain && pid != kEncodedCommonPan) {
                return true;
            }
        }
    }
    // Modulation edges — check via deviceIndex
    if (modEdges != nullptr && modEdgeCount > 0) {
        for (int e = 0; e < modEdgeCount; ++e) {
            if (modEdges[e].deviceIndex != static_cast<uint16_t>(deviceIndex)) continue;
            const uint16_t pid = modEdges[e].localParamId;
            if (pid != kEncodedCommonGain && pid != kEncodedCommonPan) {
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
        if (pid != kEncodedCommonGain && pid != kEncodedCommonPan) {
            switch (node.kind) {
            case DeviceNodeKind::Oscillator:
            case DeviceNodeKind::Sampler:
                return true;
            case DeviceNodeKind::SubtractiveSynth:
            case DeviceNodeKind::BassSynth:
            case DeviceNodeKind::PhaseModSynth:
                return false; // per-sample inside mix*MidiNotesBlock
            default:
                return false;
            }
        }
    }
    return false;
}

bool nodeHasDspModulation(uint16_t deviceIndex,
                          const ModulationEdgePlayback* modEdges,
                          int modEdgeCount) noexcept {
    if (modEdges == nullptr || modEdgeCount <= 0) return false;
    for (int e = 0; e < modEdgeCount; ++e) {
        if (modEdges[e].deviceIndex != deviceIndex) continue;
        const uint16_t pid = modEdges[e].localParamId;
        if (pid != kEncodedCommonGain && pid != kEncodedCommonPan) {
            return true;
        }
    }
    return false;
}

} // namespace audioapp::DeviceChainAutomationModulation
