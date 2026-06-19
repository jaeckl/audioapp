#include "audioapp/AutomationPlayback.hpp"

#include "audioapp/DeviceChain.hpp"
#include "audioapp/model/TrackModel.hpp"
#include "audioapp/KickGenerator.hpp"
#include "audioapp/SnareGenerator.hpp"
#include "audioapp/ClapGenerator.hpp"
#include "audioapp/CymbalGenerator.hpp"
#include "audioapp/CrashGenerator.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

bool clipDeviceIdMatches(const char* clipDeviceId, const std::string& deviceId) noexcept {
    return std::strncmp(clipDeviceId, deviceId.c_str(), 47) == 0;
}

} // namespace

// -----------------------------------------------------------------------
// paramIdFromString / paramIdToString  (control thread, string scan OK)
// -----------------------------------------------------------------------

ParamId paramIdFromString(const char* name) noexcept {
    if (name == nullptr || name[0] == '\0') return ParamId::Unknown;
    if (std::strcmp(name, "gain") == 0) return ParamId::Gain;
    if (std::strcmp(name, "pan") == 0) return ParamId::Pan;
    if (std::strcmp(name, "frequency") == 0) return ParamId::Frequency;
    if (std::strcmp(name, "filterCutoff") == 0) return ParamId::FilterCutoff;
    if (std::strcmp(name, "filterQ") == 0) return ParamId::FilterQ;
    if (std::strcmp(name, "attack") == 0) return ParamId::Attack;
    if (std::strcmp(name, "decay") == 0) return ParamId::Decay;
    if (std::strcmp(name, "sustain") == 0) return ParamId::Sustain;
    if (std::strcmp(name, "release") == 0) return ParamId::Release;
    if (std::strcmp(name, "rootPitch") == 0) return ParamId::RootPitch;
    if (std::strcmp(name, "rootFineTune") == 0) return ParamId::RootFineTune;
    if (std::strcmp(name, "filterEnvAmount") == 0) return ParamId::FilterEnvAmount;
    if (std::strcmp(name, "filterAttack") == 0) return ParamId::FilterAttack;
    if (std::strcmp(name, "filterDecay") == 0) return ParamId::FilterDecay;
    if (std::strcmp(name, "filterSustain") == 0) return ParamId::FilterSustain;
    if (std::strcmp(name, "filterRelease") == 0) return ParamId::FilterRelease;
    if (std::strcmp(name, "osc1Shape") == 0) return ParamId::Osc1Shape;
    if (std::strcmp(name, "osc2Shape") == 0) return ParamId::Osc2Shape;
    if (std::strcmp(name, "osc1Octave") == 0) return ParamId::Osc1Octave;
    if (std::strcmp(name, "osc1Semi") == 0) return ParamId::Osc1Semi;
    if (std::strcmp(name, "osc1Detune") == 0) return ParamId::Osc1Detune;
    if (std::strcmp(name, "osc2Octave") == 0) return ParamId::Osc2Octave;
    if (std::strcmp(name, "osc2Semi") == 0) return ParamId::Osc2Semi;
    if (std::strcmp(name, "osc2Detune") == 0) return ParamId::Osc2Detune;
    if (std::strcmp(name, "oscMix") == 0) return ParamId::OscMix;
    if (std::strcmp(name, "osc1Sync") == 0) return ParamId::Osc1Sync;
    if (std::strcmp(name, "osc2Sync") == 0) return ParamId::Osc2Sync;
    if (std::strcmp(name, "noiseLevel") == 0) return ParamId::NoiseLevel;
    if (std::strcmp(name, "oscMixMode") == 0) return ParamId::OscMixMode;
    if (std::strcmp(name, "unisonVoices") == 0) return ParamId::UnisonVoices;
    if (std::strcmp(name, "unisonDetune") == 0) return ParamId::UnisonDetune;
    if (std::strcmp(name, "glideMs") == 0) return ParamId::GlideMs;
    if (std::strcmp(name, "velocitySensitivity") == 0) return ParamId::VelocitySensitivity;
    if (std::strcmp(name, "preHpCutoff") == 0) return ParamId::PreHpCutoff;
    if (std::strcmp(name, "preHpRes") == 0) return ParamId::PreHpRes;
    if (std::strcmp(name, "preDrive") == 0) return ParamId::PreDrive;
    if (std::strcmp(name, "mixFeedback") == 0) return ParamId::MixFeedback;
    if (std::strcmp(name, "globalPitch") == 0) return ParamId::GlobalPitch;
    if (std::strcmp(name, "filterKeyTrack") == 0) return ParamId::FilterKeyTrack;
    if (std::strcmp(name, "filterDrive") == 0) return ParamId::FilterDrive;
    if (std::strcmp(name, "filterShaper") == 0) return ParamId::FilterShaper;
    if (std::strcmp(name, "filterFm") == 0) return ParamId::FilterFm;
    if (std::strcmp(name, "filterShaperMode") == 0) return ParamId::FilterShaperMode;
    if (std::strcmp(name, "synthLegato") == 0) return ParamId::SynthLegato;
    if (std::strcmp(name, "synthMono") == 0) return ParamId::SynthMono;
    if (std::strcmp(name, "filterMode") == 0) return ParamId::FilterMode;
    if (std::strcmp(name, "kickModel") == 0) return ParamId::KickModel;
    if (std::strcmp(name, "kickPitch") == 0) return ParamId::KickPitch;
    if (std::strcmp(name, "kickPunch") == 0) return ParamId::KickPunch;
    if (std::strcmp(name, "kickDecay") == 0) return ParamId::KickDecay;
    if (std::strcmp(name, "kickClick") == 0) return ParamId::KickClick;
    if (std::strcmp(name, "kickTone") == 0) return ParamId::KickTone;
    if (std::strcmp(name, "kickVelocity") == 0) return ParamId::KickVelocity;
    if (std::strcmp(name, "snareModel") == 0) return ParamId::SnareModel;
    if (std::strcmp(name, "snareBody") == 0) return ParamId::SnareBody;
    if (std::strcmp(name, "snareRing") == 0) return ParamId::SnareRing;
    if (std::strcmp(name, "snareTune") == 0) return ParamId::SnareTune;
    if (std::strcmp(name, "snareSnares") == 0) return ParamId::SnareSnares;
    if (std::strcmp(name, "snareSnap") == 0) return ParamId::SnareSnap;
    if (std::strcmp(name, "snareDecay") == 0) return ParamId::SnareDecay;
    if (std::strcmp(name, "snareVelocity") == 0) return ParamId::SnareVelocity;
    if (std::strcmp(name, "clapBursts") == 0) return ParamId::ClapBursts;
    if (std::strcmp(name, "clapSpread") == 0) return ParamId::ClapSpread;
    if (std::strcmp(name, "clapTone") == 0) return ParamId::ClapTone;
    if (std::strcmp(name, "clapRoom") == 0) return ParamId::ClapRoom;
    if (std::strcmp(name, "clapDecay") == 0) return ParamId::ClapDecay;
    if (std::strcmp(name, "clapVelocity") == 0) return ParamId::ClapVelocity;
    if (std::strcmp(name, "cymbalColor") == 0) return ParamId::CymbalColor;
    if (std::strcmp(name, "cymbalDecay") == 0) return ParamId::CymbalDecay;
    if (std::strcmp(name, "cymbalWidth") == 0) return ParamId::CymbalWidth;
    if (std::strcmp(name, "cymbalVelocity") == 0) return ParamId::CymbalVelocity;
    if (std::strcmp(name, "crashColor") == 0) return ParamId::CrashColor;
    if (std::strcmp(name, "crashSpread") == 0) return ParamId::CrashSpread;
    if (std::strcmp(name, "crashDecay") == 0) return ParamId::CrashDecay;
    if (std::strcmp(name, "crashVelocity") == 0) return ParamId::CrashVelocity;
    if (std::strcmp(name, "inputGain") == 0) return ParamId::InputGain;
    if (std::strcmp(name, "gateThreshold") == 0 || std::strcmp(name, "compThreshold") == 0 || std::strcmp(name, "expandThreshold") == 0) return ParamId::Threshold;
    if (std::strcmp(name, "compRatio") == 0 || std::strcmp(name, "expandRatio") == 0) return ParamId::Ratio;
    if (std::strcmp(name, "compKnee") == 0) return ParamId::CompKnee;
    if (std::strcmp(name, "compMakeup") == 0 || std::strcmp(name, "limitMakeup") == 0) return ParamId::CompMakeup;
    if (std::strcmp(name, "gateHold") == 0) return ParamId::GateHold;
    if (std::strcmp(name, "gateRange") == 0 || std::strcmp(name, "expandRange") == 0) return ParamId::GateRange;
    if (std::strcmp(name, "limitCeiling") == 0) return ParamId::LimitCeiling;
    if (std::strcmp(name, "limitDrive") == 0) return ParamId::LimitDrive;
    if (std::strcmp(name, "gateAttack") == 0 || std::strcmp(name, "compAttack") == 0 || std::strcmp(name, "expandAttack") == 0 || std::strcmp(name, "limitAttack") == 0) return ParamId::Attack;
    if (std::strcmp(name, "gateRelease") == 0 || std::strcmp(name, "compRelease") == 0 || std::strcmp(name, "expandRelease") == 0 || std::strcmp(name, "limitRelease") == 0) return ParamId::Release;
    return ParamId::Unknown;
}

const char* paramIdToString(ParamId id) noexcept {
    switch (id) {
    case ParamId::Gain: return "gain";
    case ParamId::Pan: return "pan";
    case ParamId::Frequency: return "frequency";
    case ParamId::FilterCutoff: return "filterCutoff";
    case ParamId::FilterQ: return "filterQ";
    case ParamId::Attack: return "attack";
    case ParamId::Decay: return "decay";
    case ParamId::Sustain: return "sustain";
    case ParamId::Release: return "release";
    case ParamId::RootPitch: return "rootPitch";
    case ParamId::RootFineTune: return "rootFineTune";
    case ParamId::FilterEnvAmount: return "filterEnvAmount";
    case ParamId::FilterAttack: return "filterAttack";
    case ParamId::FilterDecay: return "filterDecay";
    case ParamId::FilterSustain: return "filterSustain";
    case ParamId::FilterRelease: return "filterRelease";
    case ParamId::Osc1Shape: return "osc1Shape";
    case ParamId::Osc2Shape: return "osc2Shape";
    case ParamId::Osc1Octave: return "osc1Octave";
    case ParamId::Osc1Semi: return "osc1Semi";
    case ParamId::Osc1Detune: return "osc1Detune";
    case ParamId::Osc2Octave: return "osc2Octave";
    case ParamId::Osc2Semi: return "osc2Semi";
    case ParamId::Osc2Detune: return "osc2Detune";
    case ParamId::OscMix: return "oscMix";
    case ParamId::Osc1Sync: return "osc1Sync";
    case ParamId::Osc2Sync: return "osc2Sync";
    case ParamId::NoiseLevel: return "noiseLevel";
    case ParamId::OscMixMode: return "oscMixMode";
    case ParamId::UnisonVoices: return "unisonVoices";
    case ParamId::UnisonDetune: return "unisonDetune";
    case ParamId::GlideMs: return "glideMs";
    case ParamId::VelocitySensitivity: return "velocitySensitivity";
    case ParamId::PreHpCutoff: return "preHpCutoff";
    case ParamId::PreHpRes: return "preHpRes";
    case ParamId::PreDrive: return "preDrive";
    case ParamId::MixFeedback: return "mixFeedback";
    case ParamId::GlobalPitch: return "globalPitch";
    case ParamId::FilterKeyTrack: return "filterKeyTrack";
    case ParamId::FilterDrive: return "filterDrive";
    case ParamId::FilterShaper: return "filterShaper";
    case ParamId::FilterFm: return "filterFm";
    case ParamId::FilterShaperMode: return "filterShaperMode";
    case ParamId::SynthLegato: return "synthLegato";
    case ParamId::SynthMono: return "synthMono";
    case ParamId::FilterMode: return "filterMode";
    case ParamId::KickModel: return "kickModel";
    case ParamId::KickPitch: return "kickPitch";
    case ParamId::KickPunch: return "kickPunch";
    case ParamId::KickDecay: return "kickDecay";
    case ParamId::KickClick: return "kickClick";
    case ParamId::KickTone: return "kickTone";
    case ParamId::KickVelocity: return "kickVelocity";
    case ParamId::SnareModel: return "snareModel";
    case ParamId::SnareBody: return "snareBody";
    case ParamId::SnareRing: return "snareRing";
    case ParamId::SnareTune: return "snareTune";
    case ParamId::SnareSnares: return "snareSnares";
    case ParamId::SnareSnap: return "snareSnap";
    case ParamId::SnareDecay: return "snareDecay";
    case ParamId::SnareVelocity: return "snareVelocity";
    case ParamId::ClapBursts: return "clapBursts";
    case ParamId::ClapSpread: return "clapSpread";
    case ParamId::ClapTone: return "clapTone";
    case ParamId::ClapRoom: return "clapRoom";
    case ParamId::ClapDecay: return "clapDecay";
    case ParamId::ClapVelocity: return "clapVelocity";
    case ParamId::CymbalColor: return "cymbalColor";
    case ParamId::CymbalDecay: return "cymbalDecay";
    case ParamId::CymbalWidth: return "cymbalWidth";
    case ParamId::CymbalVelocity: return "cymbalVelocity";
    case ParamId::CrashColor: return "crashColor";
    case ParamId::CrashSpread: return "crashSpread";
    case ParamId::CrashDecay: return "crashDecay";
    case ParamId::CrashVelocity: return "crashVelocity";
    case ParamId::InputGain: return "inputGain";
    case ParamId::Threshold: return "threshold";
    case ParamId::Ratio: return "ratio";
    case ParamId::CompKnee: return "compKnee";
    case ParamId::CompMakeup: return "compMakeup";
    case ParamId::GateHold: return "gateHold";
    case ParamId::GateRange: return "gateRange";
    case ParamId::LimitCeiling: return "limitCeiling";
    case ParamId::LimitDrive: return "limitDrive";
    default: return "";
    }
}

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
        if (beatInClip < b0 || beatInClip > b1) {
            continue;
        }
        if (std::abs(b1 - b0) < 1.0e-6f) {
            return points[i + 1].value;
        }
        const float t = (beatInClip - b0) / (b1 - b0);
        return points[i].value + t * (points[i + 1].value - points[i].value);
    }
    return points[pointCount - 1].value;
}

void applyAutomationValue(DeviceVariantParams& params,
                          DeviceNodeKind kind,
                          ParamId pid,
                          float value) noexcept {
    value = std::clamp(value, 0.0f, 1.0f);
    switch (kind) {
    case DeviceNodeKind::Oscillator:
        if (auto* p = std::get_if<OscillatorParams>(&params)) {
            if (pid == ParamId::Frequency) p->frequencyHz = 20.0f + value * 1980.0f;
        }
        break;
    case DeviceNodeKind::Sampler:
        if (auto* p = std::get_if<SamplerParams>(&params)) {
            switch (pid) {
            case ParamId::FilterCutoff: p->filterCutoff = value; break;
            case ParamId::FilterQ: p->filterQ = value; break;
            case ParamId::Attack: p->attack = value; break;
            case ParamId::Decay: p->decay = value; break;
            case ParamId::Sustain: p->sustain = value; break;
            case ParamId::Release: p->release = value; break;
            case ParamId::FilterEnvAmount: p->filterEnvAmount = value; break;
            case ParamId::FilterAttack: p->filterAttack = value; break;
            case ParamId::FilterDecay: p->filterDecay = value; break;
            case ParamId::FilterSustain: p->filterSustain = value; break;
            case ParamId::FilterRelease: p->filterRelease = value; break;
            default: break;
            }
        }
        break;
    case DeviceNodeKind::SubtractiveSynth:
        if (auto* p = std::get_if<SubtractiveSynthParams>(&params)) {
            switch (pid) {
            case ParamId::Gain: p->gain = value; break;
            case ParamId::FilterCutoff: p->filterCutoff = value; break;
            case ParamId::FilterQ: p->filterQ = value; break;
            case ParamId::FilterMode: p->filterMode = std::clamp(static_cast<int>(std::lround(value * 4.0f)), 0, 4); break;
            case ParamId::Attack: p->ampAttack = value; break;
            case ParamId::Decay: p->ampDecay = value; break;
            case ParamId::Sustain: p->ampSustain = value; break;
            case ParamId::Release: p->ampRelease = value; break;
            case ParamId::Osc1Shape: p->osc1Shape = value; break;
            case ParamId::Osc2Shape: p->osc2Shape = value; break;
            case ParamId::Osc1Octave: p->osc1Octave = value; break;
            case ParamId::Osc1Semi: p->osc1Semi = value; break;
            case ParamId::Osc1Detune: p->osc1Detune = value; break;
            case ParamId::Osc2Octave: p->osc2Octave = value; break;
            case ParamId::Osc2Semi: p->osc2Semi = value; break;
            case ParamId::Osc2Detune: p->osc2Detune = value; break;
            case ParamId::OscMix: p->oscMix = value; break;
            case ParamId::Osc1Sync: p->osc1Sync = value; break;
            case ParamId::Osc2Sync: p->osc2Sync = value; break;
            case ParamId::NoiseLevel: p->noiseLevel = value; break;
            case ParamId::OscMixMode: p->oscMixMode = std::clamp(static_cast<int>(std::lround(value * 4.0f)), 0, 4); break;
            case ParamId::UnisonVoices: p->unisonVoices = value; break;
            case ParamId::UnisonDetune: p->unisonDetune = value; break;
            case ParamId::FilterEnvAmount: p->filterEnvAmount = value; break;
            case ParamId::FilterAttack: p->filterAttack = value; break;
            case ParamId::FilterDecay: p->filterDecay = value; break;
            case ParamId::FilterSustain: p->filterSustain = value; break;
            case ParamId::FilterRelease: p->filterRelease = value; break;
            case ParamId::GlideMs: p->glideMs = value; break;
            case ParamId::VelocitySensitivity: p->velocitySensitivity = value; break;
            case ParamId::PreHpCutoff: p->preHpCutoff = value; break;
            case ParamId::PreHpRes: p->preHpRes = value; break;
            case ParamId::PreDrive: p->preDrive = value; break;
            case ParamId::MixFeedback: p->mixFeedback = value; break;
            case ParamId::GlobalPitch: p->globalPitch = value; break;
            case ParamId::FilterKeyTrack: p->filterKeyTrack = value; break;
            case ParamId::FilterDrive: p->filterDrive = value; break;
            case ParamId::FilterShaper: p->filterShaper = value; break;
            case ParamId::FilterFm: p->filterFm = value; break;
            case ParamId::FilterShaperMode: p->filterShaperMode = std::clamp(static_cast<int>(std::lround(value * 3.0f)), 0, 3); break;
            case ParamId::SynthLegato: p->synthLegato = value; break;
            case ParamId::SynthMono: p->synthMono = value; break;
            default: break;
            }
        }
        break;
    case DeviceNodeKind::KickGenerator:
        if (auto* p = std::get_if<KickGeneratorParams>(&params)) {
            switch (pid) {
            case ParamId::Gain: p->gain = value; break;
            case ParamId::KickModel: p->kickModel = value; break;
            case ParamId::KickPitch: p->kickPitch = value; break;
            case ParamId::KickPunch: p->kickPunch = value; break;
            case ParamId::KickDecay: p->kickDecay = value; break;
            case ParamId::KickClick: p->kickClick = value; break;
            case ParamId::KickTone: p->kickTone = value; break;
            case ParamId::KickVelocity: p->kickVelocity = value; break;
            default: break;
            }
        }
        break;
    case DeviceNodeKind::SnareGenerator:
        if (auto* p = std::get_if<SnareGeneratorParams>(&params)) {
            switch (pid) {
            case ParamId::Gain: p->gain = value; break;
            case ParamId::SnareModel: p->snareModel = value; break;
            case ParamId::SnareBody: p->snareBody = value; break;
            case ParamId::SnareRing: p->snareRing = value; break;
            case ParamId::SnareTune: p->snareTune = value; break;
            case ParamId::SnareSnares: p->snareSnares = value; break;
            case ParamId::SnareSnap: p->snareSnap = value; break;
            case ParamId::SnareDecay: p->snareDecay = value; break;
            case ParamId::SnareVelocity: p->snareVelocity = value; break;
            default: break;
            }
        }
        break;
    case DeviceNodeKind::ClapGenerator:
        if (auto* p = std::get_if<ClapGeneratorParams>(&params)) {
            switch (pid) {
            case ParamId::Gain: p->gain = value; break;
            case ParamId::ClapBursts: p->clapBursts = value; break;
            case ParamId::ClapSpread: p->clapSpread = value; break;
            case ParamId::ClapTone: p->clapTone = value; break;
            case ParamId::ClapRoom: p->clapRoom = value; break;
            case ParamId::ClapDecay: p->clapDecay = value; break;
            case ParamId::ClapVelocity: p->clapVelocity = value; break;
            default: break;
            }
        }
        break;
    case DeviceNodeKind::CymbalGenerator:
        if (auto* p = std::get_if<CymbalGeneratorParams>(&params)) {
            switch (pid) {
            case ParamId::Gain: p->gain = value; break;
            case ParamId::CymbalColor: p->cymbalColor = value; break;
            case ParamId::CymbalDecay: p->cymbalDecay = value; break;
            case ParamId::CymbalWidth: p->cymbalWidth = value; break;
            case ParamId::CymbalVelocity: p->cymbalVelocity = value; break;
            default: break;
            }
        }
        break;
    case DeviceNodeKind::CrashGenerator:
        if (auto* p = std::get_if<CrashGeneratorParams>(&params)) {
            switch (pid) {
            case ParamId::Gain: p->gain = value; break;
            case ParamId::CrashColor: p->crashColor = value; break;
            case ParamId::CrashSpread: p->crashSpread = value; break;
            case ParamId::CrashDecay: p->crashDecay = value; break;
            case ParamId::CrashVelocity: p->crashVelocity = value; break;
            default: break;
            }
        }
        break;
    case DeviceNodeKind::Gate:
        if (auto* p = std::get_if<GateParams>(&params)) {
            switch (pid) {
            case ParamId::InputGain: p->inputGain = value; break;
            case ParamId::Threshold: p->gateThreshold = value; break;
            case ParamId::Attack: p->gateAttack = value; break;
            case ParamId::Release: p->gateRelease = value; break;
            case ParamId::GateHold: p->gateHold = value; break;
            case ParamId::GateRange: p->gateRange = value; break;
            default: break;
            }
        }
        break;
    case DeviceNodeKind::Compressor:
        if (auto* p = std::get_if<CompressorParams>(&params)) {
            switch (pid) {
            case ParamId::InputGain: p->inputGain = value; break;
            case ParamId::Threshold: p->compThreshold = value; break;
            case ParamId::Ratio: p->compRatio = value; break;
            case ParamId::Attack: p->compAttack = value; break;
            case ParamId::Release: p->compRelease = value; break;
            case ParamId::CompKnee: p->compKnee = value; break;
            case ParamId::CompMakeup: p->compMakeup = value; break;
            default: break;
            }
        }
        break;
    case DeviceNodeKind::Expander:
        if (auto* p = std::get_if<ExpanderParams>(&params)) {
            switch (pid) {
            case ParamId::InputGain: p->inputGain = value; break;
            case ParamId::Threshold: p->expandThreshold = value; break;
            case ParamId::Ratio: p->expandRatio = value; break;
            case ParamId::Attack: p->expandAttack = value; break;
            case ParamId::Release: p->expandRelease = value; break;
            case ParamId::GateRange: p->expandRange = value; break;
            default: break;
            }
        }
        break;
    case DeviceNodeKind::Limiter:
        if (auto* p = std::get_if<LimiterParams>(&params)) {
            switch (pid) {
            case ParamId::InputGain: p->inputGain = value; break;
            case ParamId::LimitCeiling: p->limitCeiling = value; break;
            case ParamId::Attack: p->limitAttack = value; break;
            case ParamId::Release: p->limitRelease = value; break;
            case ParamId::LimitDrive: p->limitDrive = value; break;
            case ParamId::CompMakeup: p->limitMakeup = value; break;
            default: break;
            }
        }
        break;
    default:
        break;
    }
}

bool automationClipPlaybackFromClip(const AutomationClip& clip,
                                    AutomationClipPlayback& out) noexcept {
    if (clip.deviceId.empty() || clip.paramId.empty() || clip.points.empty()) {
        return false;
    }

    std::memset(out.deviceId, 0, sizeof(out.deviceId));
    const size_t deviceLen = std::min(clip.deviceId.size(), sizeof(out.deviceId) - 1);
    std::memcpy(out.deviceId, clip.deviceId.data(), deviceLen);
    out.paramId = paramIdFromString(clip.paramId.c_str());
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

bool nodeHasDspAutomation(const std::string& deviceId,
                          const AutomationClipPlayback* clips,
                          int clipCount) noexcept {
    if (clips == nullptr || deviceId.empty() || clipCount <= 0) {
        return false;
    }
    for (int a = 0; a < clipCount; ++a) {
        if (!clipDeviceIdMatches(clips[a].deviceId, deviceId)) continue;
        if (clips[a].paramId != ParamId::Gain && clips[a].paramId != ParamId::Pan && clips[a].paramId != ParamId::Unknown) {
            return true;
        }
    }
    return false;
}

void applyDspAutomationAtBeat(DeviceVariantParams& params,
                              DeviceNodeKind kind,
                              const std::string& deviceId,
                              double beat,
                              const AutomationClipPlayback* clips,
                              int clipCount) noexcept {
    if (clips == nullptr || deviceId.empty()) {
        return;
    }
    for (int a = 0; a < clipCount; ++a) {
        const AutomationClipPlayback& ac = clips[a];
        if (!clipDeviceIdMatches(ac.deviceId, deviceId)) continue;
        if (ac.paramId == ParamId::Gain || ac.paramId == ParamId::Pan || ac.paramId == ParamId::Unknown) {
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
        applyAutomationValue(params, kind, ac.paramId, value);
    }
}

} // namespace audioapp