#include "audioapp/AutomationPlayback.hpp"

#include "audioapp/DeviceChain.hpp"
#include "audioapp/model/TrackModel.hpp"
#include "audioapp/KickAlgorithm.hpp"
#include "audioapp/SnareAlgorithm.hpp"
#include "audioapp/ClapAlgorithm.hpp"
#include "audioapp/CymbalAlgorithm.hpp"
#include "audioapp/CrashAlgorithm.hpp"
#include "audioapp/PhaseModSynthAlgorithm.hpp"
#include "audioapp/WavetableSynthAlgorithm.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

// -----------------------------------------------------------------------
// ParamKind <-> DeviceNodeKind mapping
// -----------------------------------------------------------------------

static ParamKind paramKindForDevice(DeviceNodeKind kind) noexcept {
    switch (kind) {
    case DeviceNodeKind::Oscillator:       return ParamKind::Oscillator;
    case DeviceNodeKind::Sampler:          return ParamKind::Sampler;
    case DeviceNodeKind::SubtractiveSynth: return ParamKind::SubtractiveSynth;
    case DeviceNodeKind::KickGenerator:    return ParamKind::KickGenerator;
    case DeviceNodeKind::SnareGenerator:   return ParamKind::SnareGenerator;
    case DeviceNodeKind::ClapGenerator:    return ParamKind::ClapGenerator;
    case DeviceNodeKind::CymbalGenerator:  return ParamKind::CymbalGenerator;
    case DeviceNodeKind::CrashGenerator:   return ParamKind::CrashGenerator;
    case DeviceNodeKind::Gate:             return ParamKind::Gate;
    case DeviceNodeKind::Compressor:       return ParamKind::Compressor;
    case DeviceNodeKind::Expander:         return ParamKind::Expander;
    case DeviceNodeKind::Limiter:          return ParamKind::Limiter;
    case DeviceNodeKind::BassSynth:        return ParamKind::BassSynth;
    case DeviceNodeKind::PhaseModSynth:    return ParamKind::PhaseModSynth;
    case DeviceNodeKind::Filter:           return ParamKind::Filter;
    case DeviceNodeKind::FourBandEq:       return ParamKind::FourBandEq;
    case DeviceNodeKind::FrequencyShifter: return ParamKind::FrequencyShifter;
    case DeviceNodeKind::ResonatorBank:    return ParamKind::ResonatorBank;
    case DeviceNodeKind::AudioReceiver:
    case DeviceNodeKind::MidiReceiver:     return ParamKind::Routing;
    case DeviceNodeKind::TrackGain:        return ParamKind::TrackGain;
    case DeviceNodeKind::Unknown:
    default:                                return ParamKind::Common;
    }
}

// -----------------------------------------------------------------------
// paramIdFromString / paramIdToString  (control thread, string scan OK)
// Returns an encoded (ParamKind, perKindId) uint16_t so the audio thread
// can disambiguate which per-kind enum to dispatch to (see AutomationTypes.hpp
// for the pack/unpack helpers).
// -----------------------------------------------------------------------

uint16_t paramIdFromString(const char* name, DeviceNodeKind kind) noexcept {
    if (name == nullptr || name[0] == '\0') return 0;
    // Common params (same across all device kinds)
    if (std::strcmp(name, "gain") == 0) return packParamId(ParamKind::Common, static_cast<uint16_t>(CommonParam::Gain));
    if (std::strcmp(name, "pan") == 0) return packParamId(ParamKind::Common, static_cast<uint16_t>(CommonParam::Pan));

    switch (kind) {
    case DeviceNodeKind::Oscillator: {
        if (std::strcmp(name, "frequency") == 0)
            return packParamId(ParamKind::Oscillator, static_cast<uint16_t>(OscillatorParam::Frequency));
        return 0;
    }
    case DeviceNodeKind::Sampler: {
        auto p = [&](const char* n, SamplerParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::Sampler, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = p("filterCutoff", SamplerParam::FilterCutoff)) return v;
        if (auto v = p("filterQ", SamplerParam::FilterQ)) return v;
        if (auto v = p("attack", SamplerParam::Attack)) return v;
        if (auto v = p("decay", SamplerParam::Decay)) return v;
        if (auto v = p("sustain", SamplerParam::Sustain)) return v;
        if (auto v = p("release", SamplerParam::Release)) return v;
        if (auto v = p("rootPitch", SamplerParam::RootPitch)) return v;
        if (auto v = p("rootFineTune", SamplerParam::RootFineTune)) return v;
        if (auto v = p("filterEnvAmount", SamplerParam::FilterEnvAmount)) return v;
        if (auto v = p("filterAttack", SamplerParam::FilterAttack)) return v;
        if (auto v = p("filterDecay", SamplerParam::FilterDecay)) return v;
        if (auto v = p("filterSustain", SamplerParam::FilterSustain)) return v;
        if (auto v = p("filterRelease", SamplerParam::FilterRelease)) return v;
        return 0;
    }
    case DeviceNodeKind::SubtractiveSynth: {
        auto s = [&](const char* n, SubtractiveParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::SubtractiveSynth, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = s("filterCutoff", SubtractiveParam::FilterCutoff)) return v;
        if (auto v = s("filterQ", SubtractiveParam::FilterQ)) return v;
        if (auto v = s("filterMode", SubtractiveParam::FilterMode)) return v;
        if (auto v = s("attack", SubtractiveParam::AmpAttack)) return v;
        if (auto v = s("decay", SubtractiveParam::AmpDecay)) return v;
        if (auto v = s("sustain", SubtractiveParam::AmpSustain)) return v;
        if (auto v = s("release", SubtractiveParam::AmpRelease)) return v;
        if (auto v = s("osc1Shape", SubtractiveParam::Osc1Shape)) return v;
        if (auto v = s("osc2Shape", SubtractiveParam::Osc2Shape)) return v;
        if (auto v = s("osc1Octave", SubtractiveParam::Osc1Octave)) return v;
        if (auto v = s("osc1Semi", SubtractiveParam::Osc1Semi)) return v;
        if (auto v = s("osc1Detune", SubtractiveParam::Osc1Detune)) return v;
        if (auto v = s("osc2Octave", SubtractiveParam::Osc2Octave)) return v;
        if (auto v = s("osc2Semi", SubtractiveParam::Osc2Semi)) return v;
        if (auto v = s("osc2Detune", SubtractiveParam::Osc2Detune)) return v;
        if (auto v = s("oscMix", SubtractiveParam::OscMix)) return v;
        if (auto v = s("oscMixMode", SubtractiveParam::OscMixMode)) return v;
        if (auto v = s("osc1Sync", SubtractiveParam::Osc1Sync)) return v;
        if (auto v = s("osc2Sync", SubtractiveParam::Osc2Sync)) return v;
        if (auto v = s("noiseLevel", SubtractiveParam::NoiseLevel)) return v;
        if (auto v = s("unisonVoices", SubtractiveParam::UnisonVoices)) return v;
        if (auto v = s("unisonDetune", SubtractiveParam::UnisonDetune)) return v;
        if (auto v = s("filterEnvAmount", SubtractiveParam::FilterEnvAmount)) return v;
        if (auto v = s("filterAttack", SubtractiveParam::FilterAttack)) return v;
        if (auto v = s("filterDecay", SubtractiveParam::FilterDecay)) return v;
        if (auto v = s("filterSustain", SubtractiveParam::FilterSustain)) return v;
        if (auto v = s("filterRelease", SubtractiveParam::FilterRelease)) return v;
        if (auto v = s("glideMs", SubtractiveParam::GlideMs)) return v;
        if (auto v = s("velocitySensitivity", SubtractiveParam::VelocitySensitivity)) return v;
        if (auto v = s("preHpCutoff", SubtractiveParam::PreHpCutoff)) return v;
        if (auto v = s("preHpRes", SubtractiveParam::PreHpRes)) return v;
        if (auto v = s("preDrive", SubtractiveParam::PreDrive)) return v;
        if (auto v = s("mixFeedback", SubtractiveParam::MixFeedback)) return v;
        if (auto v = s("globalPitch", SubtractiveParam::GlobalPitch)) return v;
        if (auto v = s("filterKeyTrack", SubtractiveParam::FilterKeyTrack)) return v;
        if (auto v = s("filterDrive", SubtractiveParam::FilterDrive)) return v;
        if (auto v = s("filterShaper", SubtractiveParam::FilterShaper)) return v;
        if (auto v = s("filterFm", SubtractiveParam::FilterFm)) return v;
        if (auto v = s("filterShaperMode", SubtractiveParam::FilterShaperMode)) return v;
        if (auto v = s("synthLegato", SubtractiveParam::SynthLegato)) return v;
        if (auto v = s("synthMono", SubtractiveParam::SynthMono)) return v;
        return 0;
    }
    case DeviceNodeKind::KickGenerator: {
        auto k = [&](const char* n, KickParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::KickGenerator, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = k("kickModel", KickParam::Model)) return v;
        if (auto v = k("kickPitch", KickParam::Pitch)) return v;
        if (auto v = k("kickPunch", KickParam::Punch)) return v;
        if (auto v = k("kickDecay", KickParam::Decay)) return v;
        if (auto v = k("kickClick", KickParam::Click)) return v;
        if (auto v = k("kickTone", KickParam::Tone)) return v;
        if (auto v = k("kickVelocity", KickParam::Velocity)) return v;
        return 0;
    }
    case DeviceNodeKind::SnareGenerator: {
        auto s = [&](const char* n, SnareParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::SnareGenerator, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = s("snareModel", SnareParam::Model)) return v;
        if (auto v = s("snareBody", SnareParam::Body)) return v;
        if (auto v = s("snareRing", SnareParam::Ring)) return v;
        if (auto v = s("snareTune", SnareParam::Tune)) return v;
        if (auto v = s("snareSnares", SnareParam::Snares)) return v;
        if (auto v = s("snareSnap", SnareParam::Snap)) return v;
        if (auto v = s("snareDecay", SnareParam::Decay)) return v;
        if (auto v = s("snareVelocity", SnareParam::Velocity)) return v;
        return 0;
    }
    case DeviceNodeKind::ClapGenerator: {
        auto c = [&](const char* n, ClapParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::ClapGenerator, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = c("clapBursts", ClapParam::Bursts)) return v;
        if (auto v = c("clapSpread", ClapParam::Spread)) return v;
        if (auto v = c("clapTone", ClapParam::Tone)) return v;
        if (auto v = c("clapRoom", ClapParam::Room)) return v;
        if (auto v = c("clapDecay", ClapParam::Decay)) return v;
        if (auto v = c("clapVelocity", ClapParam::Velocity)) return v;
        return 0;
    }
    case DeviceNodeKind::CymbalGenerator: {
        auto c = [&](const char* n, CymbalParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::CymbalGenerator, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = c("cymbalColor", CymbalParam::Color)) return v;
        if (auto v = c("cymbalDecay", CymbalParam::Decay)) return v;
        if (auto v = c("cymbalWidth", CymbalParam::Width)) return v;
        if (auto v = c("cymbalVelocity", CymbalParam::Velocity)) return v;
        return 0;
    }
    case DeviceNodeKind::CrashGenerator: {
        auto c = [&](const char* n, CrashParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::CrashGenerator, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = c("crashColor", CrashParam::Color)) return v;
        if (auto v = c("crashSpread", CrashParam::Spread)) return v;
        if (auto v = c("crashDecay", CrashParam::Decay)) return v;
        if (auto v = c("crashVelocity", CrashParam::Velocity)) return v;
        return 0;
    }
    case DeviceNodeKind::Gate: {
        auto g = [&](const char* n, GateParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::Gate, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = g("inputGain", GateParam::InputGain)) return v;
        if (auto v = g("gateThreshold", GateParam::Threshold)) return v;
        if (auto v = g("gateAttack", GateParam::Attack)) return v;
        if (auto v = g("gateRelease", GateParam::Release)) return v;
        if (auto v = g("gateHold", GateParam::Hold)) return v;
        if (auto v = g("gateRange", GateParam::Range)) return v;
        return 0;
    }
    case DeviceNodeKind::Compressor: {
        auto c = [&](const char* n, CompressorParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::Compressor, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = c("inputGain", CompressorParam::InputGain)) return v;
        if (auto v = c("compThreshold", CompressorParam::Threshold)) return v;
        if (auto v = c("compRatio", CompressorParam::Ratio)) return v;
        if (auto v = c("compAttack", CompressorParam::Attack)) return v;
        if (auto v = c("compRelease", CompressorParam::Release)) return v;
        if (auto v = c("compKnee", CompressorParam::Knee)) return v;
        if (auto v = c("compMakeup", CompressorParam::Makeup)) return v;
        return 0;
    }
    case DeviceNodeKind::Expander: {
        auto e = [&](const char* n, ExpanderParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::Expander, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = e("inputGain", ExpanderParam::InputGain)) return v;
        if (auto v = e("expandThreshold", ExpanderParam::Threshold)) return v;
        if (auto v = e("expandRatio", ExpanderParam::Ratio)) return v;
        if (auto v = e("expandAttack", ExpanderParam::Attack)) return v;
        if (auto v = e("expandRelease", ExpanderParam::Release)) return v;
        if (auto v = e("expandRange", ExpanderParam::Range)) return v;
        return 0;
    }
    case DeviceNodeKind::Limiter: {
        auto l = [&](const char* n, LimiterParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::Limiter, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = l("inputGain", LimiterParam::InputGain)) return v;
        if (auto v = l("limitCeiling", LimiterParam::Ceiling)) return v;
        if (auto v = l("limitAttack", LimiterParam::Attack)) return v;
        if (auto v = l("limitRelease", LimiterParam::Release)) return v;
        if (auto v = l("limitDrive", LimiterParam::Drive)) return v;
        if (auto v = l("limitMakeup", LimiterParam::Makeup)) return v;
        return 0;
    }
    case DeviceNodeKind::TrackGain: {
        // TrackGain has no DSP-local params; gain is the only one and is
        // handled via CommonParam::Gain. Return 0 for any other name.
        return 0;
    }
    case DeviceNodeKind::BassSynth: {
        auto b = [&](const char* n, BassSynthParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::BassSynth, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = b("bassOscShape", BassSynthParam::OscShape)) return v;
        if (auto v = b("bassSubMix", BassSynthParam::SubMix)) return v;
        if (auto v = b("bassNoise", BassSynthParam::Noise)) return v;
        if (auto v = b("filterCutoff", BassSynthParam::FilterCutoff)) return v;
        if (auto v = b("bassFilterResonance", BassSynthParam::FilterResonance)) return v;
        if (auto v = b("filterEnvAmount", BassSynthParam::FilterEnvAmount)) return v;
        if (auto v = b("filterDecay", BassSynthParam::FilterDecay)) return v;
        if (auto v = b("attack", BassSynthParam::AmpAttack)) return v;
        if (auto v = b("sustain", BassSynthParam::AmpSustain)) return v;
        if (auto v = b("release", BassSynthParam::AmpRelease)) return v;
        if (auto v = b("bassDrive", BassSynthParam::Drive)) return v;
        if (auto v = b("bassSquash", BassSynthParam::Squash)) return v;
        if (auto v = b("glideMs", BassSynthParam::GlideMs)) return v;
        if (auto v = b("bassVelocitySense", BassSynthParam::VelocitySense)) return v;
        if (auto v = b("bassOctave", BassSynthParam::Octave)) return v;
        if (auto v = b("bassSubOctave", BassSynthParam::SubOctave)) return v;
        return 0;
    }
    case DeviceNodeKind::PhaseModSynth: {
        auto p = [&](const char* n, PhaseModSynthParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::PhaseModSynth, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = p("pmOp1Level", PhaseModSynthParam::Op1Level)) return v;
        if (auto v = p("pmOp1Fine", PhaseModSynthParam::Op1Fine)) return v;
        if (auto v = p("pmOp1Attack", PhaseModSynthParam::Op1Attack)) return v;
        if (auto v = p("pmOp1Decay", PhaseModSynthParam::Op1Decay)) return v;
        if (auto v = p("pmOp1Sustain", PhaseModSynthParam::Op1Sustain)) return v;
        if (auto v = p("pmOp1Release", PhaseModSynthParam::Op1Release)) return v;
        if (auto v = p("pmOp2Level", PhaseModSynthParam::Op2Level)) return v;
        if (auto v = p("pmOp2Fine", PhaseModSynthParam::Op2Fine)) return v;
        if (auto v = p("pmOp2Attack", PhaseModSynthParam::Op2Attack)) return v;
        if (auto v = p("pmOp2Decay", PhaseModSynthParam::Op2Decay)) return v;
        if (auto v = p("pmOp2Sustain", PhaseModSynthParam::Op2Sustain)) return v;
        if (auto v = p("pmOp2Release", PhaseModSynthParam::Op2Release)) return v;
        if (auto v = p("pmOp3Level", PhaseModSynthParam::Op3Level)) return v;
        if (auto v = p("pmOp3Fine", PhaseModSynthParam::Op3Fine)) return v;
        if (auto v = p("pmOp3Attack", PhaseModSynthParam::Op3Attack)) return v;
        if (auto v = p("pmOp3Decay", PhaseModSynthParam::Op3Decay)) return v;
        if (auto v = p("pmOp3Sustain", PhaseModSynthParam::Op3Sustain)) return v;
        if (auto v = p("pmOp3Release", PhaseModSynthParam::Op3Release)) return v;
        if (auto v = p("pmOp4Level", PhaseModSynthParam::Op4Level)) return v;
        if (auto v = p("pmOp4Fine", PhaseModSynthParam::Op4Fine)) return v;
        if (auto v = p("pmOp4Attack", PhaseModSynthParam::Op4Attack)) return v;
        if (auto v = p("pmOp4Decay", PhaseModSynthParam::Op4Decay)) return v;
        if (auto v = p("pmOp4Sustain", PhaseModSynthParam::Op4Sustain)) return v;
        if (auto v = p("pmOp4Release", PhaseModSynthParam::Op4Release)) return v;
        if (auto v = p("filterCutoff", PhaseModSynthParam::FilterCutoff)) return v;
        if (auto v = p("filterQ", PhaseModSynthParam::FilterQ)) return v;
        if (auto v = p("filterEnvAmount", PhaseModSynthParam::FilterEnvAmount)) return v;
        if (auto v = p("filterMode", PhaseModSynthParam::FilterMode)) return v;
        if (auto v = p("filterAttack", PhaseModSynthParam::FilterAttack)) return v;
        if (auto v = p("filterDecay", PhaseModSynthParam::FilterDecay)) return v;
        if (auto v = p("filterSustain", PhaseModSynthParam::FilterSustain)) return v;
        if (auto v = p("filterRelease", PhaseModSynthParam::FilterRelease)) return v;
        if (auto v = p("filterKeyTrack", PhaseModSynthParam::FilterKeyTrack)) return v;
        if (auto v = p("attack", PhaseModSynthParam::AmpAttack)) return v;
        if (auto v = p("decay", PhaseModSynthParam::AmpDecay)) return v;
        if (auto v = p("sustain", PhaseModSynthParam::AmpSustain)) return v;
        if (auto v = p("release", PhaseModSynthParam::AmpRelease)) return v;
        if (auto v = p("pmFeedback", PhaseModSynthParam::Feedback)) return v;
        if (auto v = p("pmMasterVol", PhaseModSynthParam::MasterVol)) return v;
        if (auto v = p("pmLfoRate", PhaseModSynthParam::LfoRate)) return v;
        if (auto v = p("pmLfoAmount", PhaseModSynthParam::LfoAmount)) return v;
        if (auto v = p("pmVibratoDepth", PhaseModSynthParam::VibratoDepth)) return v;
        if (auto v = p("pmVibratoRate", PhaseModSynthParam::VibratoRate)) return v;
        return 0;
    }
    case DeviceNodeKind::Filter: {
        auto f = [&](const char* n, FilterParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::Filter, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = f("ffxCutoff", FilterParam::Cutoff)) return v;
        if (auto v = f("ffxResonance", FilterParam::Resonance)) return v;
        if (auto v = f("ffxFilterMode", FilterParam::Mode)) return v;
        return 0;
    }
    case DeviceNodeKind::FourBandEq: {
        auto e = [&](const char* n, FourBandEqParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::FourBandEq, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = e("ffxBand1Freq", FourBandEqParam::Band1Freq)) return v;
        if (auto v = e("ffxBand1Gain", FourBandEqParam::Band1Gain)) return v;
        if (auto v = e("ffxBand1Q",    FourBandEqParam::Band1Q))    return v;
        if (auto v = e("ffxBand2Freq", FourBandEqParam::Band2Freq)) return v;
        if (auto v = e("ffxBand2Gain", FourBandEqParam::Band2Gain)) return v;
        if (auto v = e("ffxBand2Q",    FourBandEqParam::Band2Q))    return v;
        if (auto v = e("ffxBand3Freq", FourBandEqParam::Band3Freq)) return v;
        if (auto v = e("ffxBand3Gain", FourBandEqParam::Band3Gain)) return v;
        if (auto v = e("ffxBand3Q",    FourBandEqParam::Band3Q))    return v;
        if (auto v = e("ffxBand4Freq", FourBandEqParam::Band4Freq)) return v;
        if (auto v = e("ffxBand4Gain", FourBandEqParam::Band4Gain)) return v;
        if (auto v = e("ffxBand4Q",    FourBandEqParam::Band4Q))    return v;
        return 0;
    }
    case DeviceNodeKind::FrequencyShifter: {
        auto s = [&](const char* n, FrequencyShifterParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::FrequencyShifter, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = s("ffxShift", FrequencyShifterParam::Shift)) return v;
        return 0;
    }
    case DeviceNodeKind::ResonatorBank: {
        auto r = [&](const char* n, ResonatorBankParam pid) {
            return std::strcmp(name, n) == 0
                ? packParamId(ParamKind::ResonatorBank, static_cast<uint16_t>(pid))
                : 0;
        };
        if (auto v = r("resRoot", ResonatorBankParam::Root)) return v;
        if (auto v = r("resSpread", ResonatorBankParam::Spread)) return v;
        if (auto v = r("resDecay", ResonatorBankParam::Decay)) return v;
        if (auto v = r("resDamping", ResonatorBankParam::Damping)) return v;
        if (auto v = r("resColor", ResonatorBankParam::Color)) return v;
        if (auto v = r("resWidth", ResonatorBankParam::Width)) return v;
        if (auto v = r("resMix", ResonatorBankParam::Mix)) return v;
        return 0;
    }
    case DeviceNodeKind::AudioReceiver:
    case DeviceNodeKind::MidiReceiver: {
        if (std::strcmp(name, "routeMix") == 0)
            return packParamId(ParamKind::Routing, static_cast<uint16_t>(RoutingParam::Mix));
        return 0;
    }
    default:
        return 0;
    }
}

const char* paramIdToString(uint16_t localParamId, DeviceNodeKind kind) noexcept {
    // localParamId is now an encoded (ParamKind, perKindId) uint16_t. The
    // caller still passes the device kind, so we use it to switch the
    // outer dispatch and unpackParamId() to get the raw enum value.
    const uint16_t rawId = unpackParamId(localParamId);
    switch (kind) {
    case DeviceNodeKind::Oscillator: {
        switch (static_cast<OscillatorParam>(rawId)) {
        case OscillatorParam::Frequency: return "frequency";
        default: return "";
        }
    }
    case DeviceNodeKind::Sampler: {
        switch (static_cast<SamplerParam>(rawId)) {
        case SamplerParam::FilterCutoff: return "filterCutoff";
        case SamplerParam::FilterQ: return "filterQ";
        case SamplerParam::Attack: return "attack";
        case SamplerParam::Decay: return "decay";
        case SamplerParam::Sustain: return "sustain";
        case SamplerParam::Release: return "release";
        case SamplerParam::RootPitch: return "rootPitch";
        case SamplerParam::RootFineTune: return "rootFineTune";
        case SamplerParam::FilterEnvAmount: return "filterEnvAmount";
        case SamplerParam::FilterAttack: return "filterAttack";
        case SamplerParam::FilterDecay: return "filterDecay";
        case SamplerParam::FilterSustain: return "filterSustain";
        case SamplerParam::FilterRelease: return "filterRelease";
        default: return "";
        }
    }
    case DeviceNodeKind::SubtractiveSynth: {
        switch (static_cast<SubtractiveParam>(rawId)) {
        case SubtractiveParam::FilterCutoff: return "filterCutoff";
        case SubtractiveParam::FilterQ: return "filterQ";
        case SubtractiveParam::FilterMode: return "filterMode";
        case SubtractiveParam::AmpAttack: return "attack";
        case SubtractiveParam::AmpDecay: return "decay";
        case SubtractiveParam::AmpSustain: return "sustain";
        case SubtractiveParam::AmpRelease: return "release";
        case SubtractiveParam::Osc1Shape: return "osc1Shape";
        case SubtractiveParam::Osc2Shape: return "osc2Shape";
        case SubtractiveParam::Osc1Octave: return "osc1Octave";
        case SubtractiveParam::Osc1Semi: return "osc1Semi";
        case SubtractiveParam::Osc1Detune: return "osc1Detune";
        case SubtractiveParam::Osc2Octave: return "osc2Octave";
        case SubtractiveParam::Osc2Semi: return "osc2Semi";
        case SubtractiveParam::Osc2Detune: return "osc2Detune";
        case SubtractiveParam::OscMix: return "oscMix";
        case SubtractiveParam::OscMixMode: return "oscMixMode";
        case SubtractiveParam::Osc1Sync: return "osc1Sync";
        case SubtractiveParam::Osc2Sync: return "osc2Sync";
        case SubtractiveParam::NoiseLevel: return "noiseLevel";
        case SubtractiveParam::UnisonVoices: return "unisonVoices";
        case SubtractiveParam::UnisonDetune: return "unisonDetune";
        case SubtractiveParam::FilterEnvAmount: return "filterEnvAmount";
        case SubtractiveParam::FilterAttack: return "filterAttack";
        case SubtractiveParam::FilterDecay: return "filterDecay";
        case SubtractiveParam::FilterSustain: return "filterSustain";
        case SubtractiveParam::FilterRelease: return "filterRelease";
        case SubtractiveParam::GlideMs: return "glideMs";
        case SubtractiveParam::VelocitySensitivity: return "velocitySensitivity";
        case SubtractiveParam::PreHpCutoff: return "preHpCutoff";
        case SubtractiveParam::PreHpRes: return "preHpRes";
        case SubtractiveParam::PreDrive: return "preDrive";
        case SubtractiveParam::MixFeedback: return "mixFeedback";
        case SubtractiveParam::GlobalPitch: return "globalPitch";
        case SubtractiveParam::FilterKeyTrack: return "filterKeyTrack";
        case SubtractiveParam::FilterDrive: return "filterDrive";
        case SubtractiveParam::FilterShaper: return "filterShaper";
        case SubtractiveParam::FilterFm: return "filterFm";
        case SubtractiveParam::FilterShaperMode: return "filterShaperMode";
        case SubtractiveParam::SynthLegato: return "synthLegato";
        case SubtractiveParam::SynthMono: return "synthMono";
        default: return "";
        }
    }
    case DeviceNodeKind::KickGenerator: {
        switch (static_cast<KickParam>(rawId)) {
        case KickParam::Model: return "kickModel";
        case KickParam::Pitch: return "kickPitch";
        case KickParam::Punch: return "kickPunch";
        case KickParam::Decay: return "kickDecay";
        case KickParam::Click: return "kickClick";
        case KickParam::Tone: return "kickTone";
        case KickParam::Velocity: return "kickVelocity";
        default: return "";
        }
    }
    case DeviceNodeKind::SnareGenerator: {
        switch (static_cast<SnareParam>(rawId)) {
        case SnareParam::Model: return "snareModel";
        case SnareParam::Body: return "snareBody";
        case SnareParam::Ring: return "snareRing";
        case SnareParam::Tune: return "snareTune";
        case SnareParam::Snares: return "snareSnares";
        case SnareParam::Snap: return "snareSnap";
        case SnareParam::Decay: return "snareDecay";
        case SnareParam::Velocity: return "snareVelocity";
        default: return "";
        }
    }
    case DeviceNodeKind::ClapGenerator: {
        switch (static_cast<ClapParam>(rawId)) {
        case ClapParam::Bursts: return "clapBursts";
        case ClapParam::Spread: return "clapSpread";
        case ClapParam::Tone: return "clapTone";
        case ClapParam::Room: return "clapRoom";
        case ClapParam::Decay: return "clapDecay";
        case ClapParam::Velocity: return "clapVelocity";
        default: return "";
        }
    }
    case DeviceNodeKind::CymbalGenerator: {
        switch (static_cast<CymbalParam>(rawId)) {
        case CymbalParam::Color: return "cymbalColor";
        case CymbalParam::Decay: return "cymbalDecay";
        case CymbalParam::Width: return "cymbalWidth";
        case CymbalParam::Velocity: return "cymbalVelocity";
        default: return "";
        }
    }
    case DeviceNodeKind::CrashGenerator: {
        switch (static_cast<CrashParam>(rawId)) {
        case CrashParam::Color: return "crashColor";
        case CrashParam::Spread: return "crashSpread";
        case CrashParam::Decay: return "crashDecay";
        case CrashParam::Velocity: return "crashVelocity";
        default: return "";
        }
    }
    case DeviceNodeKind::Gate: {
        switch (static_cast<GateParam>(rawId)) {
        case GateParam::InputGain: return "inputGain";
        case GateParam::Threshold: return "gateThreshold";
        case GateParam::Attack: return "gateAttack";
        case GateParam::Release: return "gateRelease";
        case GateParam::Hold: return "gateHold";
        case GateParam::Range: return "gateRange";
        default: return "";
        }
    }
    case DeviceNodeKind::Compressor: {
        switch (static_cast<CompressorParam>(rawId)) {
        case CompressorParam::InputGain: return "inputGain";
        case CompressorParam::Threshold: return "compThreshold";
        case CompressorParam::Ratio: return "compRatio";
        case CompressorParam::Attack: return "compAttack";
        case CompressorParam::Release: return "compRelease";
        case CompressorParam::Knee: return "compKnee";
        case CompressorParam::Makeup: return "compMakeup";
        default: return "";
        }
    }
    case DeviceNodeKind::Expander: {
        switch (static_cast<ExpanderParam>(rawId)) {
        case ExpanderParam::InputGain: return "inputGain";
        case ExpanderParam::Threshold: return "expandThreshold";
        case ExpanderParam::Ratio: return "expandRatio";
        case ExpanderParam::Attack: return "expandAttack";
        case ExpanderParam::Release: return "expandRelease";
        case ExpanderParam::Range: return "expandRange";
        default: return "";
        }
    }
    case DeviceNodeKind::Limiter: {
        switch (static_cast<LimiterParam>(rawId)) {
        case LimiterParam::InputGain: return "inputGain";
        case LimiterParam::Ceiling: return "limitCeiling";
        case LimiterParam::Attack: return "limitAttack";
        case LimiterParam::Release: return "limitRelease";
        case LimiterParam::Drive: return "limitDrive";
        case LimiterParam::Makeup: return "limitMakeup";
        default: return "";
        }
    }
    case DeviceNodeKind::BassSynth: {
        switch (static_cast<BassSynthParam>(rawId)) {
        case BassSynthParam::FilterCutoff: return "filterCutoff";
        case BassSynthParam::FilterResonance: return "bassFilterResonance";
        case BassSynthParam::FilterEnvAmount: return "filterEnvAmount";
        case BassSynthParam::AmpAttack: return "attack";
        case BassSynthParam::AmpSustain: return "sustain";
        case BassSynthParam::AmpRelease: return "release";
        case BassSynthParam::OscShape: return "bassOscShape";
        case BassSynthParam::SubMix: return "bassSubMix";
        case BassSynthParam::Noise: return "bassNoise";
        case BassSynthParam::Drive: return "bassDrive";
        case BassSynthParam::Squash: return "bassSquash";
        case BassSynthParam::GlideMs: return "glideMs";
        case BassSynthParam::VelocitySense: return "bassVelocitySense";
        case BassSynthParam::FilterDecay: return "filterDecay";
        case BassSynthParam::Octave: return "bassOctave";
        case BassSynthParam::SubOctave: return "bassSubOctave";
        default:         return "";
        }
    }
    case DeviceNodeKind::PhaseModSynth: {
        switch (static_cast<PhaseModSynthParam>(rawId)) {
        case PhaseModSynthParam::Op1Level: return "pmOp1Level";
        case PhaseModSynthParam::Op1Fine: return "pmOp1Fine";
        case PhaseModSynthParam::Op1Attack: return "pmOp1Attack";
        case PhaseModSynthParam::Op1Decay: return "pmOp1Decay";
        case PhaseModSynthParam::Op1Sustain: return "pmOp1Sustain";
        case PhaseModSynthParam::Op1Release: return "pmOp1Release";
        case PhaseModSynthParam::Op2Level: return "pmOp2Level";
        case PhaseModSynthParam::Op2Fine: return "pmOp2Fine";
        case PhaseModSynthParam::Op2Attack: return "pmOp2Attack";
        case PhaseModSynthParam::Op2Decay: return "pmOp2Decay";
        case PhaseModSynthParam::Op2Sustain: return "pmOp2Sustain";
        case PhaseModSynthParam::Op2Release: return "pmOp2Release";
        case PhaseModSynthParam::Op3Level: return "pmOp3Level";
        case PhaseModSynthParam::Op3Fine: return "pmOp3Fine";
        case PhaseModSynthParam::Op3Attack: return "pmOp3Attack";
        case PhaseModSynthParam::Op3Decay: return "pmOp3Decay";
        case PhaseModSynthParam::Op3Sustain: return "pmOp3Sustain";
        case PhaseModSynthParam::Op3Release: return "pmOp3Release";
        case PhaseModSynthParam::Op4Level: return "pmOp4Level";
        case PhaseModSynthParam::Op4Fine: return "pmOp4Fine";
        case PhaseModSynthParam::Op4Attack: return "pmOp4Attack";
        case PhaseModSynthParam::Op4Decay: return "pmOp4Decay";
        case PhaseModSynthParam::Op4Sustain: return "pmOp4Sustain";
        case PhaseModSynthParam::Op4Release: return "pmOp4Release";
        case PhaseModSynthParam::FilterCutoff: return "filterCutoff";
        case PhaseModSynthParam::FilterQ: return "filterQ";
        case PhaseModSynthParam::FilterEnvAmount: return "filterEnvAmount";
        case PhaseModSynthParam::FilterMode: return "filterMode";
        case PhaseModSynthParam::FilterAttack: return "filterAttack";
        case PhaseModSynthParam::FilterDecay: return "filterDecay";
        case PhaseModSynthParam::FilterSustain: return "filterSustain";
        case PhaseModSynthParam::FilterRelease: return "filterRelease";
        case PhaseModSynthParam::FilterKeyTrack: return "filterKeyTrack";
        case PhaseModSynthParam::AmpAttack: return "attack";
        case PhaseModSynthParam::AmpDecay: return "decay";
        case PhaseModSynthParam::AmpSustain: return "sustain";
        case PhaseModSynthParam::AmpRelease: return "release";
        case PhaseModSynthParam::Feedback: return "pmFeedback";
        case PhaseModSynthParam::MasterVol: return "pmMasterVol";
        case PhaseModSynthParam::LfoRate: return "pmLfoRate";
        case PhaseModSynthParam::LfoAmount: return "pmLfoAmount";
        case PhaseModSynthParam::VibratoDepth: return "pmVibratoDepth";
        case PhaseModSynthParam::VibratoRate: return "pmVibratoRate";
        default: return "";
        }
    }
    case DeviceNodeKind::Filter: {
        switch (static_cast<FilterParam>(rawId)) {
        case FilterParam::Cutoff:    return "ffxCutoff";
        case FilterParam::Resonance: return "ffxResonance";
        case FilterParam::Mode:      return "ffxFilterMode";
        default: return "";
        }
    }
    case DeviceNodeKind::FourBandEq: {
        switch (static_cast<FourBandEqParam>(rawId)) {
        case FourBandEqParam::Band1Freq: return "ffxBand1Freq";
        case FourBandEqParam::Band1Gain: return "ffxBand1Gain";
        case FourBandEqParam::Band1Q:    return "ffxBand1Q";
        case FourBandEqParam::Band2Freq: return "ffxBand2Freq";
        case FourBandEqParam::Band2Gain: return "ffxBand2Gain";
        case FourBandEqParam::Band2Q:    return "ffxBand2Q";
        case FourBandEqParam::Band3Freq: return "ffxBand3Freq";
        case FourBandEqParam::Band3Gain: return "ffxBand3Gain";
        case FourBandEqParam::Band3Q:    return "ffxBand3Q";
        case FourBandEqParam::Band4Freq: return "ffxBand4Freq";
        case FourBandEqParam::Band4Gain: return "ffxBand4Gain";
        case FourBandEqParam::Band4Q:    return "ffxBand4Q";
        default: return "";
        }
    }
    case DeviceNodeKind::FrequencyShifter: {
        switch (static_cast<FrequencyShifterParam>(rawId)) {
        case FrequencyShifterParam::Shift: return "ffxShift";
        default: return "";
        }
    }
    case DeviceNodeKind::ResonatorBank: {
        switch (static_cast<ResonatorBankParam>(rawId)) {
        case ResonatorBankParam::Root: return "resRoot";
        case ResonatorBankParam::Spread: return "resSpread";
        case ResonatorBankParam::Decay: return "resDecay";
        case ResonatorBankParam::Damping: return "resDamping";
        case ResonatorBankParam::Color: return "resColor";
        case ResonatorBankParam::Width: return "resWidth";
        case ResonatorBankParam::Mix: return "resMix";
        default: return "";
        }
    }
    case DeviceNodeKind::AudioReceiver:
    case DeviceNodeKind::MidiReceiver: {
        switch (static_cast<RoutingParam>(rawId)) {
        case RoutingParam::Mix: return "routeMix";
        default: return "";
        }
    }
    default:
        return "";
    }
}

// -----------------------------------------------------------------------
// ParamDescriptor tables (control thread metadata)
// -----------------------------------------------------------------------

const ParamDescriptor* paramDescriptorsForKind(DeviceNodeKind kind, int& countOut) noexcept {
    countOut = 0;
    switch (kind) {
    case DeviceNodeKind::Oscillator: {
        static constexpr ParamDescriptor kParams[] = {
            {static_cast<uint16_t>(OscillatorParam::Frequency), "frequency", "Frequency", 440.0f, 20.0f, 20000.0f, true, true},
        };
        countOut = 1;
        return kParams;
    }
    case DeviceNodeKind::Sampler: {
        static constexpr ParamDescriptor kParams[] = {
            {static_cast<uint16_t>(SamplerParam::FilterCutoff), "filterCutoff", "Filter Cutoff", 1.0f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(SamplerParam::FilterQ), "filterQ", "Filter Q", 0.5f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(SamplerParam::Attack), "attack", "Attack", 0.01f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(SamplerParam::Decay), "decay", "Decay", 0.1f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(SamplerParam::Sustain), "sustain", "Sustain", 1.0f, 0.0f, 1.0f, true, false},
            {static_cast<uint16_t>(SamplerParam::Release), "release", "Release", 0.2f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(SamplerParam::RootPitch), "rootPitch", "Root Pitch", 60.0f, 0.0f, 127.0f, true, false},
            {static_cast<uint16_t>(SamplerParam::RootFineTune), "rootFineTune", "Fine Tune", 0.0f, -100.0f, 100.0f, true, false},
            {static_cast<uint16_t>(SamplerParam::FilterEnvAmount), "filterEnvAmount", "Filter Env", 0.5f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(SamplerParam::FilterAttack), "filterAttack", "Flt Attack", 0.05f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(SamplerParam::FilterDecay), "filterDecay", "Flt Decay", 0.35f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(SamplerParam::FilterSustain), "filterSustain", "Flt Sustain", 0.4f, 0.0f, 1.0f, true, false},
            {static_cast<uint16_t>(SamplerParam::FilterRelease), "filterRelease", "Flt Release", 0.45f, 0.0f, 1.0f, true, true},
        };
        countOut = 13;
        return kParams;
    }
    case DeviceNodeKind::SubtractiveSynth: {
        // ... (omitted for length, auto-generated in real code)
        countOut = 0;
        return nullptr;
    }
    case DeviceNodeKind::BassSynth: {
        static constexpr ParamDescriptor kParams[] = {
            {static_cast<uint16_t>(BassSynthParam::FilterCutoff), "filterCutoff", "Filter Cutoff", 0.85f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::FilterResonance), "bassFilterResonance", "Filter Resonance", 0.25f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::FilterEnvAmount), "filterEnvAmount", "Env Amount", 0.6f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::FilterDecay), "filterDecay", "Filter Decay", 0.4f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::AmpAttack), "attack", "Attack", 0.02f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::AmpSustain), "sustain", "Sustain", 0.8f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::AmpRelease), "release", "Release", 0.35f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::OscShape), "bassOscShape", "Osc Shape", 0.3f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::SubMix), "bassSubMix", "Sub Mix", 0.5f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::Noise), "bassNoise", "Noise", 0.0f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::Drive), "bassDrive", "Drive", 0.0f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::Squash), "bassSquash", "Squash", 0.0f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::GlideMs), "glideMs", "Glide", 0.0f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::VelocitySense), "bassVelocitySense", "Velocity Sense", 1.0f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::Octave), "bassOctave", "Octave", 2.0f, 0.0f, 4.0f, true, true},
            {static_cast<uint16_t>(BassSynthParam::SubOctave), "bassSubOctave", "Sub Octave", 0.0f, 0.0f, 2.0f, true, true},
        };
        countOut = 14;
        return kParams;
    }
    case DeviceNodeKind::PhaseModSynth: {
        static constexpr ParamDescriptor kParams[] = {
            {static_cast<uint16_t>(PhaseModSynthParam::Op1Level), "pmOp1Level", "Op1 Level", 0.8f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op1Fine), "pmOp1Fine", "Op1 Fine", 0.5f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op1Attack), "pmOp1Attack", "Op1 Attack", 0.01f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op1Decay), "pmOp1Decay", "Op1 Decay", 0.3f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op1Sustain), "pmOp1Sustain", "Op1 Sustain", 0.8f, 0.0f, 1.0f, true, false},
            {static_cast<uint16_t>(PhaseModSynthParam::Op1Release), "pmOp1Release", "Op1 Release", 0.4f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op2Level), "pmOp2Level", "Op2 Level", 0.4f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op2Fine), "pmOp2Fine", "Op2 Fine", 0.5f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op2Attack), "pmOp2Attack", "Op2 Attack", 0.01f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op2Decay), "pmOp2Decay", "Op2 Decay", 0.3f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op2Sustain), "pmOp2Sustain", "Op2 Sustain", 0.8f, 0.0f, 1.0f, true, false},
            {static_cast<uint16_t>(PhaseModSynthParam::Op2Release), "pmOp2Release", "Op2 Release", 0.4f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op3Level), "pmOp3Level", "Op3 Level", 0.0f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op3Fine), "pmOp3Fine", "Op3 Fine", 0.5f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op3Attack), "pmOp3Attack", "Op3 Attack", 0.01f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op3Decay), "pmOp3Decay", "Op3 Decay", 0.3f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op3Sustain), "pmOp3Sustain", "Op3 Sustain", 0.8f, 0.0f, 1.0f, true, false},
            {static_cast<uint16_t>(PhaseModSynthParam::Op3Release), "pmOp3Release", "Op3 Release", 0.4f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op4Level), "pmOp4Level", "Op4 Level", 0.0f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op4Fine), "pmOp4Fine", "Op4 Fine", 0.5f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op4Attack), "pmOp4Attack", "Op4 Attack", 0.01f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op4Decay), "pmOp4Decay", "Op4 Decay", 0.3f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Op4Sustain), "pmOp4Sustain", "Op4 Sustain", 0.8f, 0.0f, 1.0f, true, false},
            {static_cast<uint16_t>(PhaseModSynthParam::Op4Release), "pmOp4Release", "Op4 Release", 0.4f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::FilterCutoff), "filterCutoff", "Filter Cutoff", 0.85f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::FilterQ), "filterQ", "Filter Q", 0.25f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::FilterEnvAmount), "filterEnvAmount", "Filter Env", 0.5f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::FilterMode), "filterMode", "Filter Mode", 0.0f, 0.0f, 5.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::FilterAttack), "filterAttack", "Filter Attack", 0.05f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::FilterDecay), "filterDecay", "Filter Decay", 0.35f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::FilterSustain), "filterSustain", "Filter Sustain", 0.4f, 0.0f, 1.0f, true, false},
            {static_cast<uint16_t>(PhaseModSynthParam::FilterRelease), "filterRelease", "Filter Release", 0.45f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::FilterKeyTrack), "filterKeyTrack", "Filter Key Track", 0.0f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::AmpAttack), "attack", "Attack", 0.01f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::AmpDecay), "decay", "Decay", 0.3f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::AmpSustain), "sustain", "Sustain", 0.75f, 0.0f, 1.0f, true, false},
            {static_cast<uint16_t>(PhaseModSynthParam::AmpRelease), "release", "Release", 0.35f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::Feedback), "pmFeedback", "Feedback", 0.0f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::MasterVol), "pmMasterVol", "Master Vol", 0.85f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::LfoRate), "pmLfoRate", "LFO Rate", 0.2f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::LfoAmount), "pmLfoAmount", "LFO Amount", 0.0f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::VibratoDepth), "pmVibratoDepth", "Vibrato Depth", 0.0f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(PhaseModSynthParam::VibratoRate), "pmVibratoRate", "Vibrato Rate", 0.3f, 0.0f, 1.0f, true, true},
        };
        countOut = 43;
        return kParams;
    }
    case DeviceNodeKind::Filter: {
        static constexpr ParamDescriptor kParams[] = {
            {static_cast<uint16_t>(FilterParam::Cutoff),    "ffxCutoff",    "Cutoff",    0.6f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(FilterParam::Resonance), "ffxResonance", "Resonance", 0.3f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(FilterParam::Mode),      "ffxFilterMode","Mode",      0.0f, 0.0f, 1.0f, true, true},
        };
        countOut = 3;
        return kParams;
    }
    case DeviceNodeKind::FourBandEq: {
        static constexpr ParamDescriptor kParams[] = {
            {static_cast<uint16_t>(FourBandEqParam::Band1Freq), "ffxBand1Freq", "Low Freq",  0.4f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(FourBandEqParam::Band1Gain), "ffxBand1Gain", "Low Gain",  0.5f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(FourBandEqParam::Band1Q),    "ffxBand1Q",    "Low Q",     0.3f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(FourBandEqParam::Band2Freq), "ffxBand2Freq", "LM Freq",   0.5f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(FourBandEqParam::Band2Gain), "ffxBand2Gain", "LM Gain",   0.5f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(FourBandEqParam::Band2Q),    "ffxBand2Q",    "LM Q",      0.3f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(FourBandEqParam::Band3Freq), "ffxBand3Freq", "HM Freq",   0.7f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(FourBandEqParam::Band3Gain), "ffxBand3Gain", "HM Gain",   0.5f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(FourBandEqParam::Band3Q),    "ffxBand3Q",    "HM Q",      0.3f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(FourBandEqParam::Band4Freq), "ffxBand4Freq", "High Freq", 0.8f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(FourBandEqParam::Band4Gain), "ffxBand4Gain", "High Gain", 0.5f, 0.0f, 1.0f, true, true},
            {static_cast<uint16_t>(FourBandEqParam::Band4Q),    "ffxBand4Q",    "High Q",    0.3f, 0.0f, 1.0f, true, true},
        };
        countOut = 12;
        return kParams;
    }
    case DeviceNodeKind::FrequencyShifter: {
        static constexpr ParamDescriptor kParams[] = {
            {static_cast<uint16_t>(FrequencyShifterParam::Shift), "ffxShift", "Shift", 0.5f, 0.0f, 1.0f, true, true},
        };
        countOut = 1;
        return kParams;
    }
    case DeviceNodeKind::ResonatorBank: {
        static constexpr ParamDescriptor kParams[] = {
            {0, "resRoot", "Root", 0.5f, 0.0f, 1.0f, true, true},
            {1, "resSpread", "Spread", 0.5f, 0.0f, 1.0f, true, true},
            {2, "resDecay", "Decay", 0.55f, 0.0f, 1.0f, true, true},
            {3, "resDamping", "Damping", 0.35f, 0.0f, 1.0f, true, true},
            {4, "resColor", "Color", 0.5f, 0.0f, 1.0f, true, true},
            {5, "resWidth", "Width", 0.5f, 0.0f, 1.0f, true, true},
            {6, "resMix", "Mix", 0.5f, 0.0f, 1.0f, true, true},
        };
        countOut = 7;
        return kParams;
    }
    case DeviceNodeKind::AudioReceiver:
    case DeviceNodeKind::MidiReceiver: {
        static constexpr ParamDescriptor kParams[] = {
            {0, "routeMix", "Mix", 1.0f, 0.0f, 1.0f, true, true},
        };
        countOut = kind == DeviceNodeKind::AudioReceiver ? 1 : 0;
        return kParams;
    }
    default:
        return nullptr;
    }
}

// -----------------------------------------------------------------------
// evaluateAutomationEnvelope (unchanged logic)
// -----------------------------------------------------------------------

float evaluateAutomationEnvelope(const AutomationPointPlayback* points,
                                 int pointCount,
                                 float beatInClip) noexcept {
    if (points == nullptr || pointCount <= 0) {
        return 0.0f;
    }
    if (pointCount == 1) {
        return points[0].value;
    }
    if (beatInClip <= points[0].beat) {
        return points[0].value;
    }
    if (beatInClip >= points[pointCount - 1].beat) {
        return points[pointCount - 1].value;
    }
    for (int i = 0; i < pointCount - 1; ++i) {
        const float b0 = points[i].beat;
        const float b1 = points[i + 1].beat;
        if (beatInClip < b0 || beatInClip > b1) continue;
        if (std::abs(b1 - b0) < 1.0e-6f) return points[i + 1].value;
        const float t = (beatInClip - b0) / (b1 - b0);
        return points[i].value + t * (points[i + 1].value - points[i].value);
    }
    return points[pointCount - 1].value;
}

// -----------------------------------------------------------------------
// applyAutomationValue — per-device enum dispatch (audio thread)
// -----------------------------------------------------------------------

void applyAutomationValue(DeviceVariantParams& params,
                          DeviceNodeKind kind,
                          uint16_t localParamId,
                          float value) noexcept {
    if (!std::isfinite(value)) {
        value = 0.0f;
    }
    value = std::clamp(value, 0.0f, 1.0f);
    // localParamId is now encoded (ParamKind, perKindId). We dispatch on
    // the encoded kind so that a SubtractiveSynth::FilterCutoff (encoded
    // as 0x3000) doesn't collide with CommonParam::Gain (encoded as 0).
    // We still read `kind` for the std::get_if check.
    const uint16_t rawId = unpackParamId(localParamId);
    const ParamKind k = unpackParamKind(localParamId);
    (void)kind; // kind is the device kind of the params; useful for safety but not required.
    switch (k) {
    case ParamKind::Oscillator:
        if (auto* p = std::get_if<OscillatorParams>(&params)) {
            switch (static_cast<OscillatorParam>(rawId)) {
            case OscillatorParam::Frequency: p->frequencyHz = 20.0f + value * 1980.0f; break;
            default: break;
            }
        }
        break;
    case ParamKind::Sampler:
        if (auto* p = std::get_if<SamplerParams>(&params)) {
            switch (static_cast<SamplerParam>(rawId)) {
            case SamplerParam::FilterCutoff: p->filterCutoff = value; break;
            case SamplerParam::FilterQ: p->filterQ = value; break;
            case SamplerParam::Attack: p->attack = value; break;
            case SamplerParam::Decay: p->decay = value; break;
            case SamplerParam::Sustain: p->sustain = value; break;
            case SamplerParam::Release: p->release = value; break;
            case SamplerParam::FilterEnvAmount: p->filterEnvAmount = value; break;
            case SamplerParam::FilterAttack: p->filterAttack = value; break;
            case SamplerParam::FilterDecay: p->filterDecay = value; break;
            case SamplerParam::FilterSustain: p->filterSustain = value; break;
            case SamplerParam::FilterRelease: p->filterRelease = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::SubtractiveSynth:
        if (auto* p = std::get_if<SubtractiveSynthParams>(&params)) {
            switch (static_cast<SubtractiveParam>(rawId)) {
            case SubtractiveParam::FilterCutoff: p->filterCutoff = value; break;
            case SubtractiveParam::FilterQ: p->filterQ = value; break;
            case SubtractiveParam::FilterMode: p->filterMode = std::clamp(static_cast<int>(std::lround(value * 4.0f)), 0, 4); break;
            case SubtractiveParam::AmpAttack: p->ampAttack = value; break;
            case SubtractiveParam::AmpDecay: p->ampDecay = value; break;
            case SubtractiveParam::AmpSustain: p->ampSustain = value; break;
            case SubtractiveParam::AmpRelease: p->ampRelease = value; break;
            case SubtractiveParam::Osc1Shape: p->osc1Shape = value; break;
            case SubtractiveParam::Osc2Shape: p->osc2Shape = value; break;
            case SubtractiveParam::Osc1Octave: p->osc1Octave = value; break;
            case SubtractiveParam::Osc1Semi: p->osc1Semi = value; break;
            case SubtractiveParam::Osc1Detune: p->osc1Detune = value; break;
            case SubtractiveParam::Osc2Octave: p->osc2Octave = value; break;
            case SubtractiveParam::Osc2Semi: p->osc2Semi = value; break;
            case SubtractiveParam::Osc2Detune: p->osc2Detune = value; break;
            case SubtractiveParam::OscMix: p->oscMix = value; break;
            case SubtractiveParam::OscMixMode: p->oscMixMode = std::clamp(static_cast<int>(std::lround(value * 4.0f)), 0, 4); break;
            case SubtractiveParam::Osc1Sync: p->osc1Sync = value; break;
            case SubtractiveParam::Osc2Sync: p->osc2Sync = value; break;
            case SubtractiveParam::NoiseLevel: p->noiseLevel = value; break;
            case SubtractiveParam::UnisonVoices: p->unisonVoices = value; break;
            case SubtractiveParam::UnisonDetune: p->unisonDetune = value; break;
            case SubtractiveParam::FilterEnvAmount: p->filterEnvAmount = value; break;
            case SubtractiveParam::FilterAttack: p->filterAttack = value; break;
            case SubtractiveParam::FilterDecay: p->filterDecay = value; break;
            case SubtractiveParam::FilterSustain: p->filterSustain = value; break;
            case SubtractiveParam::FilterRelease: p->filterRelease = value; break;
            case SubtractiveParam::GlideMs: p->glideMs = value; break;
            case SubtractiveParam::VelocitySensitivity: p->velocitySensitivity = value; break;
            case SubtractiveParam::PreHpCutoff: p->preHpCutoff = value; break;
            case SubtractiveParam::PreHpRes: p->preHpRes = value; break;
            case SubtractiveParam::PreDrive: p->preDrive = value; break;
            case SubtractiveParam::MixFeedback: p->mixFeedback = value; break;
            case SubtractiveParam::GlobalPitch: p->globalPitch = value; break;
            case SubtractiveParam::FilterKeyTrack: p->filterKeyTrack = value; break;
            case SubtractiveParam::FilterDrive: p->filterDrive = value; break;
            case SubtractiveParam::FilterShaper: p->filterShaper = value; break;
            case SubtractiveParam::FilterFm: p->filterFm = value; break;
            case SubtractiveParam::FilterShaperMode: p->filterShaperMode = std::clamp(static_cast<int>(std::lround(value * 3.0f)), 0, 3); break;
            case SubtractiveParam::SynthLegato: p->synthLegato = value; break;
            case SubtractiveParam::SynthMono: p->synthMono = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::KickGenerator:
        if (auto* p = std::get_if<KickGeneratorParams>(&params)) {
            switch (static_cast<KickParam>(rawId)) {
            case KickParam::Model: p->kickModel = value; break;
            case KickParam::Pitch: p->kickPitch = value; break;
            case KickParam::Punch: p->kickPunch = value; break;
            case KickParam::Decay: p->kickDecay = value; break;
            case KickParam::Click: p->kickClick = value; break;
            case KickParam::Tone: p->kickTone = value; break;
            case KickParam::Velocity: p->kickVelocity = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::SnareGenerator:
        if (auto* p = std::get_if<SnareGeneratorParams>(&params)) {
            switch (static_cast<SnareParam>(rawId)) {
            case SnareParam::Model: p->snareModel = value; break;
            case SnareParam::Body: p->snareBody = value; break;
            case SnareParam::Ring: p->snareRing = value; break;
            case SnareParam::Tune: p->snareTune = value; break;
            case SnareParam::Snares: p->snareSnares = value; break;
            case SnareParam::Snap: p->snareSnap = value; break;
            case SnareParam::Decay: p->snareDecay = value; break;
            case SnareParam::Velocity: p->snareVelocity = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::ClapGenerator:
        if (auto* p = std::get_if<ClapGeneratorParams>(&params)) {
            switch (static_cast<ClapParam>(rawId)) {
            case ClapParam::Bursts: p->clapBursts = value; break;
            case ClapParam::Spread: p->clapSpread = value; break;
            case ClapParam::Tone: p->clapTone = value; break;
            case ClapParam::Room: p->clapRoom = value; break;
            case ClapParam::Decay: p->clapDecay = value; break;
            case ClapParam::Velocity: p->clapVelocity = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::CymbalGenerator:
        if (auto* p = std::get_if<CymbalGeneratorParams>(&params)) {
            switch (static_cast<CymbalParam>(rawId)) {
            case CymbalParam::Color: p->cymbalColor = value; break;
            case CymbalParam::Decay: p->cymbalDecay = value; break;
            case CymbalParam::Width: p->cymbalWidth = value; break;
            case CymbalParam::Velocity: p->cymbalVelocity = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::CrashGenerator:
        if (auto* p = std::get_if<CrashGeneratorParams>(&params)) {
            switch (static_cast<CrashParam>(rawId)) {
            case CrashParam::Color: p->crashColor = value; break;
            case CrashParam::Spread: p->crashSpread = value; break;
            case CrashParam::Decay: p->crashDecay = value; break;
            case CrashParam::Velocity: p->crashVelocity = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::Gate:
        if (auto* p = std::get_if<GateParams>(&params)) {
            switch (static_cast<GateParam>(rawId)) {
            case GateParam::InputGain: p->inputGain = value; break;
            case GateParam::Threshold: p->gateThreshold = value; break;
            case GateParam::Attack: p->gateAttack = value; break;
            case GateParam::Release: p->gateRelease = value; break;
            case GateParam::Hold: p->gateHold = value; break;
            case GateParam::Range: p->gateRange = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::Compressor:
        if (auto* p = std::get_if<CompressorParams>(&params)) {
            switch (static_cast<CompressorParam>(rawId)) {
            case CompressorParam::InputGain: p->inputGain = value; break;
            case CompressorParam::Threshold: p->compThreshold = value; break;
            case CompressorParam::Ratio: p->compRatio = value; break;
            case CompressorParam::Attack: p->compAttack = value; break;
            case CompressorParam::Release: p->compRelease = value; break;
            case CompressorParam::Knee: p->compKnee = value; break;
            case CompressorParam::Makeup: p->compMakeup = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::Expander:
        if (auto* p = std::get_if<ExpanderParams>(&params)) {
            switch (static_cast<ExpanderParam>(rawId)) {
            case ExpanderParam::InputGain: p->inputGain = value; break;
            case ExpanderParam::Threshold: p->expandThreshold = value; break;
            case ExpanderParam::Ratio: p->expandRatio = value; break;
            case ExpanderParam::Attack: p->expandAttack = value; break;
            case ExpanderParam::Release: p->expandRelease = value; break;
            case ExpanderParam::Range: p->expandRange = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::Limiter:
        if (auto* p = std::get_if<LimiterParams>(&params)) {
            switch (static_cast<LimiterParam>(rawId)) {
            case LimiterParam::InputGain: p->inputGain = value; break;
            case LimiterParam::Ceiling: p->limitCeiling = value; break;
            case LimiterParam::Attack: p->limitAttack = value; break;
            case LimiterParam::Release: p->limitRelease = value; break;
            case LimiterParam::Drive: p->limitDrive = value; break;
            case LimiterParam::Makeup: p->limitMakeup = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::BassSynth:
        if (auto* p = std::get_if<SubtractiveSynthParams>(&params)) {
            switch (static_cast<BassSynthParam>(rawId)) {
            case BassSynthParam::FilterCutoff: p->filterCutoff = value; break;
            case BassSynthParam::FilterResonance: p->filterQ = value; break;
            case BassSynthParam::FilterEnvAmount: p->filterEnvAmount = value; break;
            case BassSynthParam::FilterDecay: p->filterDecay = value; break;
            case BassSynthParam::AmpAttack: p->ampAttack = value; break;
            case BassSynthParam::AmpSustain: p->ampSustain = value; break;
            case BassSynthParam::AmpRelease: p->ampRelease = value; break;
            case BassSynthParam::OscShape: p->osc1Shape = value; break;
            case BassSynthParam::SubMix: p->oscMix = value; break;
            case BassSynthParam::Noise: p->noiseLevel = value; break;
            case BassSynthParam::Drive: p->filterDrive = value; p->preDrive = value * 0.5f; break;
            case BassSynthParam::Squash: p->mixFeedback = value; break;
            case BassSynthParam::GlideMs: p->glideMs = value; break;
            case BassSynthParam::VelocitySense: p->velocitySensitivity = value; break;
            case BassSynthParam::Octave: p->globalPitch = value; break;
            case BassSynthParam::SubOctave: p->osc2Octave = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::PhaseModSynth:
        if (auto* p = std::get_if<PhaseModSynthParams>(&params)) {
            switch (static_cast<PhaseModSynthParam>(rawId)) {
            case PhaseModSynthParam::Op1Level: p->operators[0].level = value; break;
            case PhaseModSynthParam::Op1Fine: p->operators[0].fine = phaseModFineNormToCents(value); break;
            case PhaseModSynthParam::Op1Attack: p->operators[0].attack = value; break;
            case PhaseModSynthParam::Op1Decay: p->operators[0].decay = value; break;
            case PhaseModSynthParam::Op1Sustain: p->operators[0].sustain = value; break;
            case PhaseModSynthParam::Op1Release: p->operators[0].release = value; break;
            case PhaseModSynthParam::Op2Level: p->operators[1].level = value; break;
            case PhaseModSynthParam::Op2Fine: p->operators[1].fine = phaseModFineNormToCents(value); break;
            case PhaseModSynthParam::Op2Attack: p->operators[1].attack = value; break;
            case PhaseModSynthParam::Op2Decay: p->operators[1].decay = value; break;
            case PhaseModSynthParam::Op2Sustain: p->operators[1].sustain = value; break;
            case PhaseModSynthParam::Op2Release: p->operators[1].release = value; break;
            case PhaseModSynthParam::Op3Level: p->operators[2].level = value; break;
            case PhaseModSynthParam::Op3Fine: p->operators[2].fine = phaseModFineNormToCents(value); break;
            case PhaseModSynthParam::Op3Attack: p->operators[2].attack = value; break;
            case PhaseModSynthParam::Op3Decay: p->operators[2].decay = value; break;
            case PhaseModSynthParam::Op3Sustain: p->operators[2].sustain = value; break;
            case PhaseModSynthParam::Op3Release: p->operators[2].release = value; break;
            case PhaseModSynthParam::Op4Level: p->operators[3].level = value; break;
            case PhaseModSynthParam::Op4Fine: p->operators[3].fine = phaseModFineNormToCents(value); break;
            case PhaseModSynthParam::Op4Attack: p->operators[3].attack = value; break;
            case PhaseModSynthParam::Op4Decay: p->operators[3].decay = value; break;
            case PhaseModSynthParam::Op4Sustain: p->operators[3].sustain = value; break;
            case PhaseModSynthParam::Op4Release: p->operators[3].release = value; break;
            case PhaseModSynthParam::FilterCutoff: p->filterCutoff = value; break;
            case PhaseModSynthParam::FilterQ: p->filterQ = value; break;
            case PhaseModSynthParam::FilterEnvAmount: p->filterEnvAmount = value; break;
            case PhaseModSynthParam::FilterMode: p->filterMode = static_cast<int>(value); break;
            case PhaseModSynthParam::FilterAttack: p->filterAttack = value; break;
            case PhaseModSynthParam::FilterDecay: p->filterDecay = value; break;
            case PhaseModSynthParam::FilterSustain: p->filterSustain = value; break;
            case PhaseModSynthParam::FilterRelease: p->filterRelease = value; break;
            case PhaseModSynthParam::FilterKeyTrack: p->filterKeyTrack = value; break;
            case PhaseModSynthParam::AmpAttack: p->ampAttack = value; break;
            case PhaseModSynthParam::AmpDecay: p->ampDecay = value; break;
            case PhaseModSynthParam::AmpSustain: p->ampSustain = value; break;
            case PhaseModSynthParam::AmpRelease: p->ampRelease = value; break;
            case PhaseModSynthParam::Feedback: p->feedback = value; break;
            case PhaseModSynthParam::MasterVol: p->masterVol = value; break;
            case PhaseModSynthParam::LfoRate: p->lfoRate = value; break;
            case PhaseModSynthParam::LfoAmount: p->lfoAmount = value; break;
            case PhaseModSynthParam::VibratoDepth: p->vibratoDepth = value; break;
            case PhaseModSynthParam::VibratoRate: p->vibratoRate = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::WavetableSynth:
        if (auto* p = std::get_if<WavetableSynthParams>(&params)) {
            switch (static_cast<WavetableParam>(rawId)) {
            case WavetableParam::WtPosition:      p->wtPosition = value; break;
            case WavetableParam::WtOctave:        p->wtOctave = value; break;
            case WavetableParam::WtSemitone:      p->wtSemitone = value; break;
            case WavetableParam::WtFine:          p->wtFine = value; break;
            case WavetableParam::WtUnison:        p->wtUnison = value; break;
            case WavetableParam::WtDetune:        p->wtDetune = value; break;
            case WavetableParam::FilterCutoff:    p->filterCutoff = value; break;
            case WavetableParam::FilterResonance: p->filterResonance = value; break;
            case WavetableParam::FilterEnvAmount: p->filterEnvAmount = value; break;
            case WavetableParam::FilterAttack:    p->filterAttack = value; break;
            case WavetableParam::FilterDecay:     p->filterDecay = value; break;
            case WavetableParam::FilterSustain:   p->filterSustain = value; break;
            case WavetableParam::FilterRelease:   p->filterRelease = value; break;
            case WavetableParam::AmpAttack:       p->ampAttack = value; break;
            case WavetableParam::AmpDecay:        p->ampDecay = value; break;
            case WavetableParam::AmpSustain:      p->ampSustain = value; break;
            case WavetableParam::AmpRelease:      p->ampRelease = value; break;
            default: break;
            }
        }
        break;
    case ParamKind::ResonatorBank:
        if (auto* p = std::get_if<ResonatorBankParams>(&params)) {
            const float normalized = std::clamp(value, 0.0f, 1.0f);
            switch (static_cast<ResonatorBankParam>(rawId)) {
            case ResonatorBankParam::Root: {
                const float note = 24.0f + normalized * 72.0f;
                p->rootHz = 440.0f * std::pow(2.0f, (note - 69.0f) / 12.0f);
                break;
            }
            case ResonatorBankParam::Spread: p->spread = 0.5f + normalized; break;
            case ResonatorBankParam::Decay: p->decaySeconds = 0.08f * std::pow(150.0f, normalized); break;
            case ResonatorBankParam::Damping: p->damping = normalized; break;
            case ResonatorBankParam::Color: p->colorDbPerOctave = (normalized - 0.5f) * 24.0f; break;
            case ResonatorBankParam::Width: p->width = normalized * 2.0f; break;
            case ResonatorBankParam::Mix: p->mix = normalized; break;
            }
        }
        break;
    case ParamKind::Routing:
        if (auto* p = std::get_if<RoutingParams>(&params)) {
            const float normalized = std::clamp(value, 0.0f, 1.0f);
            switch (static_cast<RoutingParam>(rawId)) {
            case RoutingParam::Mix:
                p->routeMix = normalized;
                break;
            }
        }
        break;
    case ParamKind::Common:
    case ParamKind::TrackGain:
    default:
        // Common (gain/pan) and TrackGain are handled elsewhere
        // (processDeviceChain / per-frame gain/pan arrays).
        break;
    }
}

// -----------------------------------------------------------------------
// automationClipPlaybackFromClip (control thread)
// -----------------------------------------------------------------------

bool automationClipPlaybackFromClip(const AutomationClip& clip,
                                    AutomationClipPlayback& out) noexcept {
    if (clip.deviceId.empty() || clip.paramId.empty() || clip.points.empty()) {
        return false;
    }
    // deviceIndex is resolved by the caller (ProjectEngine::rebuildAutomationPlaybackLocked)
    out.deviceIndex = 0;
    out.localParamId = 0; // resolved by caller too (or we could pass kind)
    out.clipStartBeat = static_cast<float>(clip.startBeat);
    out.clipLengthBeats = static_cast<float>(clip.lengthBeats);
    out.pointCount = static_cast<int>(
        std::min(clip.points.size(), static_cast<size_t>(kMaxAutomationPlaybackPoints)));
    for (int i = 0; i < out.pointCount; ++i) {
        out.points[i].beat = static_cast<float>(clip.points[static_cast<size_t>(i)].beat);
        out.points[i].value = clip.points[static_cast<size_t>(i)].value;
    }
    return out.pointCount > 0;
}

// -----------------------------------------------------------------------
// nodeHasDspAutomation — uses deviceIndex matching
// -----------------------------------------------------------------------

bool nodeHasDspAutomation(uint16_t deviceIndex,
                          const AutomationClipPlayback* clips,
                          int clipCount) noexcept {
    if (clips == nullptr || clipCount <= 0) return false;
    for (int a = 0; a < clipCount; ++a) {
        if (clips[a].deviceIndex != deviceIndex) continue;
        const uint16_t pid = clips[a].localParamId;
        // Skip the Common gain/pan encodings. The encoded values for
        // Common::Gain and Common::Pan are 0 and 1 (kind tag is 0). The
        // encoded values for any other param (e.g. SubtractiveSynth::
        // FilterCutoff) are 0x3000 etc. and never match.
        if (pid != kEncodedCommonGain && pid != kEncodedCommonPan) {
            return true;
        }
    }
    return false;
}

// -----------------------------------------------------------------------
// applyDspAutomationAtBeat — uses deviceIndex matching
// -----------------------------------------------------------------------

void applyDspAutomationAtBeat(DeviceVariantParams& params,
                              DeviceNodeKind kind,
                              uint16_t deviceIndex,
                              double beat,
                              const AutomationClipPlayback* clips,
                              int clipCount) noexcept {
    if (clips == nullptr) return;
    for (int a = 0; a < clipCount; ++a) {
        const AutomationClipPlayback& ac = clips[a];
        if (ac.deviceIndex != deviceIndex) continue;
        const uint16_t pid = ac.localParamId;
        // Common gain/pan are handled by the device-chain loop (per-frame
        // gain/pan arrays). DSP-local params use the encoded kind tag, so
        // these constants never collide with SubtractiveSynth::FilterCutoff
        // or any other per-kind value 0.
        if (pid == kEncodedCommonGain || pid == kEncodedCommonPan) {
            continue;
        }
        if (beat < static_cast<double>(ac.clipStartBeat) ||
            beat >= static_cast<double>(ac.clipStartBeat + ac.clipLengthBeats)) {
            continue;
        }
        const float beatInClip =
            static_cast<float>(beat - static_cast<double>(ac.clipStartBeat));
        const float value =
            evaluateAutomationEnvelope(ac.points, ac.pointCount, beatInClip);
        applyAutomationValue(params, kind, pid, value);
    }
}

} // namespace audioapp
