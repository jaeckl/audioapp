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

// Realtime-safe char-array comparison (no std::string allocation).
bool clipDeviceIdMatches(const char* clipDeviceId, const std::string& deviceId) noexcept {
    return std::strncmp(clipDeviceId, deviceId.c_str(), 47) == 0;
}

bool clipParamIdIs(const char* clipParamId, const char* name) noexcept {
    return std::strncmp(clipParamId, name, 47) == 0;
}

} // namespace

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
                          const char* pid,
                          float value) noexcept {
    value = std::clamp(value, 0.0f, 1.0f);
    switch (kind) {
    case DeviceNodeKind::Oscillator:
        if (auto* p = std::get_if<OscillatorParams>(&params)) {
            if (std::strcmp(pid, "frequency") == 0) {
                p->frequencyHz = 20.0f + value * 1980.0f;
            }
        }
        break;
    case DeviceNodeKind::Sampler:
        if (auto* p = std::get_if<SamplerParams>(&params)) {
            if (std::strcmp(pid, "filterCutoff") == 0) p->filterCutoff = value;
            else if (std::strcmp(pid, "filterQ") == 0) p->filterQ = value;
            else if (std::strcmp(pid, "attack") == 0) p->attack = value;
            else if (std::strcmp(pid, "decay") == 0) p->decay = value;
            else if (std::strcmp(pid, "sustain") == 0) p->sustain = value;
            else if (std::strcmp(pid, "release") == 0) p->release = value;
            else if (std::strcmp(pid, "filterEnvAmount") == 0) p->filterEnvAmount = value;
            else if (std::strcmp(pid, "filterAttack") == 0) p->filterAttack = value;
            else if (std::strcmp(pid, "filterDecay") == 0) p->filterDecay = value;
            else if (std::strcmp(pid, "filterSustain") == 0) p->filterSustain = value;
            else if (std::strcmp(pid, "filterRelease") == 0) p->filterRelease = value;
        }
        break;
    case DeviceNodeKind::SubtractiveSynth:
        if (auto* p = std::get_if<SubtractiveSynthParams>(&params)) {
            if (std::strcmp(pid, "gain") == 0) p->gain = value;
            else if (std::strcmp(pid, "filterCutoff") == 0) p->filterCutoff = value;
            else if (std::strcmp(pid, "filterQ") == 0) p->filterQ = value;
            else if (std::strcmp(pid, "filterMode") == 0) p->filterMode = std::clamp(static_cast<int>(std::lround(value * 4.0f)), 0, 4);
            else if (std::strcmp(pid, "attack") == 0) p->ampAttack = value;
            else if (std::strcmp(pid, "decay") == 0) p->ampDecay = value;
            else if (std::strcmp(pid, "sustain") == 0) p->ampSustain = value;
            else if (std::strcmp(pid, "release") == 0) p->ampRelease = value;
            else if (std::strcmp(pid, "osc1Shape") == 0) p->osc1Shape = value;
            else if (std::strcmp(pid, "osc2Shape") == 0) p->osc2Shape = value;
            else if (std::strcmp(pid, "osc1Octave") == 0) p->osc1Octave = value;
            else if (std::strcmp(pid, "osc1Semi") == 0) p->osc1Semi = value;
            else if (std::strcmp(pid, "osc1Detune") == 0) p->osc1Detune = value;
            else if (std::strcmp(pid, "osc2Octave") == 0) p->osc2Octave = value;
            else if (std::strcmp(pid, "osc2Semi") == 0) p->osc2Semi = value;
            else if (std::strcmp(pid, "osc2Detune") == 0) p->osc2Detune = value;
            else if (std::strcmp(pid, "oscMix") == 0) p->oscMix = value;
            else if (std::strcmp(pid, "osc1Sync") == 0) p->osc1Sync = value;
            else if (std::strcmp(pid, "osc2Sync") == 0) p->osc2Sync = value;
            else if (std::strcmp(pid, "noiseLevel") == 0) p->noiseLevel = value;
            else if (std::strcmp(pid, "oscMixMode") == 0) p->oscMixMode = std::clamp(static_cast<int>(std::lround(value * 4.0f)), 0, 4);
            else if (std::strcmp(pid, "unisonVoices") == 0) p->unisonVoices = value;
            else if (std::strcmp(pid, "unisonDetune") == 0) p->unisonDetune = value;
            else if (std::strcmp(pid, "filterEnvAmount") == 0) p->filterEnvAmount = value;
            else if (std::strcmp(pid, "filterAttack") == 0) p->filterAttack = value;
            else if (std::strcmp(pid, "filterDecay") == 0) p->filterDecay = value;
            else if (std::strcmp(pid, "filterSustain") == 0) p->filterSustain = value;
            else if (std::strcmp(pid, "filterRelease") == 0) p->filterRelease = value;
            else if (std::strcmp(pid, "glideMs") == 0) p->glideMs = value;
            else if (std::strcmp(pid, "velocitySensitivity") == 0) p->velocitySensitivity = value;
            else if (std::strcmp(pid, "preHpCutoff") == 0) p->preHpCutoff = value;
            else if (std::strcmp(pid, "preHpRes") == 0) p->preHpRes = value;
            else if (std::strcmp(pid, "preDrive") == 0) p->preDrive = value;
            else if (std::strcmp(pid, "mixFeedback") == 0) p->mixFeedback = value;
            else if (std::strcmp(pid, "globalPitch") == 0) p->globalPitch = value;
            else if (std::strcmp(pid, "filterKeyTrack") == 0) p->filterKeyTrack = value;
            else if (std::strcmp(pid, "filterDrive") == 0) p->filterDrive = value;
            else if (std::strcmp(pid, "filterShaper") == 0) p->filterShaper = value;
            else if (std::strcmp(pid, "filterFm") == 0) p->filterFm = value;
            else if (std::strcmp(pid, "filterShaperMode") == 0) p->filterShaperMode = std::clamp(static_cast<int>(std::lround(value * 3.0f)), 0, 3);
            else if (std::strcmp(pid, "synthLegato") == 0) p->synthLegato = value;
            else if (std::strcmp(pid, "synthMono") == 0) p->synthMono = value;
        }
        break;
    case DeviceNodeKind::KickGenerator:
        if (auto* p = std::get_if<KickGeneratorParams>(&params)) {
            if (std::strcmp(pid, "gain") == 0) p->gain = value;
            else if (std::strcmp(pid, "kickModel") == 0) p->kickModel = value;
            else if (std::strcmp(pid, "kickPitch") == 0) p->kickPitch = value;
            else if (std::strcmp(pid, "kickPunch") == 0) p->kickPunch = value;
            else if (std::strcmp(pid, "kickDecay") == 0) p->kickDecay = value;
            else if (std::strcmp(pid, "kickClick") == 0) p->kickClick = value;
            else if (std::strcmp(pid, "kickTone") == 0) p->kickTone = value;
            else if (std::strcmp(pid, "kickVelocity") == 0) p->kickVelocity = value;
        }
        break;
    case DeviceNodeKind::SnareGenerator:
        if (auto* p = std::get_if<SnareGeneratorParams>(&params)) {
            if (std::strcmp(pid, "gain") == 0) p->gain = value;
            else if (std::strcmp(pid, "snareModel") == 0) p->snareModel = value;
            else if (std::strcmp(pid, "snareBody") == 0) p->snareBody = value;
            else if (std::strcmp(pid, "snareRing") == 0) p->snareRing = value;
            else if (std::strcmp(pid, "snareTune") == 0) p->snareTune = value;
            else if (std::strcmp(pid, "snareSnares") == 0) p->snareSnares = value;
            else if (std::strcmp(pid, "snareSnap") == 0) p->snareSnap = value;
            else if (std::strcmp(pid, "snareDecay") == 0) p->snareDecay = value;
            else if (std::strcmp(pid, "snareVelocity") == 0) p->snareVelocity = value;
        }
        break;
    case DeviceNodeKind::ClapGenerator:
        if (auto* p = std::get_if<ClapGeneratorParams>(&params)) {
            if (std::strcmp(pid, "gain") == 0) p->gain = value;
            else if (std::strcmp(pid, "clapBursts") == 0) p->clapBursts = value;
            else if (std::strcmp(pid, "clapSpread") == 0) p->clapSpread = value;
            else if (std::strcmp(pid, "clapTone") == 0) p->clapTone = value;
            else if (std::strcmp(pid, "clapRoom") == 0) p->clapRoom = value;
            else if (std::strcmp(pid, "clapDecay") == 0) p->clapDecay = value;
            else if (std::strcmp(pid, "clapVelocity") == 0) p->clapVelocity = value;
        }
        break;
    case DeviceNodeKind::CymbalGenerator:
        if (auto* p = std::get_if<CymbalGeneratorParams>(&params)) {
            if (std::strcmp(pid, "gain") == 0) p->gain = value;
            else if (std::strcmp(pid, "cymbalColor") == 0) p->cymbalColor = value;
            else if (std::strcmp(pid, "cymbalDecay") == 0) p->cymbalDecay = value;
            else if (std::strcmp(pid, "cymbalWidth") == 0) p->cymbalWidth = value;
            else if (std::strcmp(pid, "cymbalVelocity") == 0) p->cymbalVelocity = value;
        }
        break;
    case DeviceNodeKind::CrashGenerator:
        if (auto* p = std::get_if<CrashGeneratorParams>(&params)) {
            if (std::strcmp(pid, "gain") == 0) p->gain = value;
            else if (std::strcmp(pid, "crashColor") == 0) p->crashColor = value;
            else if (std::strcmp(pid, "crashSpread") == 0) p->crashSpread = value;
            else if (std::strcmp(pid, "crashDecay") == 0) p->crashDecay = value;
            else if (std::strcmp(pid, "crashVelocity") == 0) p->crashVelocity = value;
        }
        break;
    case DeviceNodeKind::Gate:
        if (auto* p = std::get_if<GateParams>(&params)) {
            if (std::strcmp(pid, "inputGain") == 0) p->inputGain = value;
            else if (std::strcmp(pid, "gateThreshold") == 0) p->gateThreshold = value;
            else if (std::strcmp(pid, "gateAttack") == 0) p->gateAttack = value;
            else if (std::strcmp(pid, "gateRelease") == 0) p->gateRelease = value;
            else if (std::strcmp(pid, "gateHold") == 0) p->gateHold = value;
            else if (std::strcmp(pid, "gateRange") == 0) p->gateRange = value;
        }
        break;
    case DeviceNodeKind::Compressor:
        if (auto* p = std::get_if<CompressorParams>(&params)) {
            if (std::strcmp(pid, "inputGain") == 0) p->inputGain = value;
            else if (std::strcmp(pid, "compThreshold") == 0) p->compThreshold = value;
            else if (std::strcmp(pid, "compRatio") == 0) p->compRatio = value;
            else if (std::strcmp(pid, "compAttack") == 0) p->compAttack = value;
            else if (std::strcmp(pid, "compRelease") == 0) p->compRelease = value;
            else if (std::strcmp(pid, "compKnee") == 0) p->compKnee = value;
            else if (std::strcmp(pid, "compMakeup") == 0) p->compMakeup = value;
        }
        break;
    case DeviceNodeKind::Expander:
        if (auto* p = std::get_if<ExpanderParams>(&params)) {
            if (std::strcmp(pid, "inputGain") == 0) p->inputGain = value;
            else if (std::strcmp(pid, "expandThreshold") == 0) p->expandThreshold = value;
            else if (std::strcmp(pid, "expandRatio") == 0) p->expandRatio = value;
            else if (std::strcmp(pid, "expandAttack") == 0) p->expandAttack = value;
            else if (std::strcmp(pid, "expandRelease") == 0) p->expandRelease = value;
            else if (std::strcmp(pid, "expandRange") == 0) p->expandRange = value;
        }
        break;
    case DeviceNodeKind::Limiter:
        if (auto* p = std::get_if<LimiterParams>(&params)) {
            if (std::strcmp(pid, "inputGain") == 0) p->inputGain = value;
            else if (std::strcmp(pid, "limitCeiling") == 0) p->limitCeiling = value;
            else if (std::strcmp(pid, "limitAttack") == 0) p->limitAttack = value;
            else if (std::strcmp(pid, "limitRelease") == 0) p->limitRelease = value;
            else if (std::strcmp(pid, "limitKnee") == 0) p->limitKnee = value;
            else if (std::strcmp(pid, "limitDrive") == 0) p->limitDrive = value;
            else if (std::strcmp(pid, "limitMakeup") == 0) p->limitMakeup = value;
        }
        break;
    case DeviceNodeKind::TrackGain:
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
    std::memset(out.paramId, 0, sizeof(out.paramId));
    const size_t deviceLen = std::min(clip.deviceId.size(), sizeof(out.deviceId) - 1);
    const size_t paramLen = std::min(clip.paramId.size(), sizeof(out.paramId) - 1);
    std::memcpy(out.deviceId, clip.deviceId.data(), deviceLen);
    std::memcpy(out.paramId, clip.paramId.data(), paramLen);
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
        const char* pid = clips[a].paramId;
        if (pid[0] != '\0' && !clipParamIdIs(pid, "gain") && !clipParamIdIs(pid, "pan")) {
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
        const char* pid = ac.paramId;
        if (pid[0] == '\0' || clipParamIdIs(pid, "gain") || clipParamIdIs(pid, "pan")) {
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