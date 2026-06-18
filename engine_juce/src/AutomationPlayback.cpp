#include "audioapp/AutomationPlayback.hpp"

#include "audioapp/DeviceChain.hpp"
#include "audioapp/model/TrackModel.hpp"
#include "audioapp/KickGenerator.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

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
                          const std::string& paramId,
                          float value) noexcept {
    value = std::clamp(value, 0.0f, 1.0f);
    switch (kind) {
    case DeviceNodeKind::Oscillator:
        if (auto* p = std::get_if<OscillatorParams>(&params)) {
            if (paramId == "frequency") {
                p->frequencyHz = 20.0f + value * 1980.0f;
            }
        }
        break;
    case DeviceNodeKind::Sampler:
        if (auto* p = std::get_if<SamplerParams>(&params)) {
            if (paramId == "filterCutoff") {
                p->filterCutoff = value;
            } else if (paramId == "filterQ") {
                p->filterQ = value;
            } else if (paramId == "attack") {
                p->attack = value;
            } else if (paramId == "decay") {
                p->decay = value;
            } else if (paramId == "sustain") {
                p->sustain = value;
            } else if (paramId == "release") {
                p->release = value;
            }
        }
        break;
    case DeviceNodeKind::SubtractiveSynth:
        if (auto* p = std::get_if<SubtractiveSynthParams>(&params)) {
            if (paramId == "gain") {
                p->gain = value;
            } else if (paramId == "filterCutoff") {
                p->filterCutoff = value;
            } else if (paramId == "filterQ") {
                p->filterQ = value;
            } else if (paramId == "filterMode") {
                p->filterMode = std::clamp(static_cast<int>(std::lround(value * 4.0f)), 0, 4);
            } else if (paramId == "attack") {
                p->ampAttack = value;
            } else if (paramId == "decay") {
                p->ampDecay = value;
            } else if (paramId == "sustain") {
                p->ampSustain = value;
            } else if (paramId == "release") {
                p->ampRelease = value;
            } else if (paramId == "osc1Shape") {
                p->osc1Shape = value;
            } else if (paramId == "osc2Shape") {
                p->osc2Shape = value;
            } else if (paramId == "osc1Octave") {
                p->osc1Octave = value;
            } else if (paramId == "osc1Semi") {
                p->osc1Semi = value;
            } else if (paramId == "osc1Detune") {
                p->osc1Detune = value;
            } else if (paramId == "osc2Octave") {
                p->osc2Octave = value;
            } else if (paramId == "osc2Semi") {
                p->osc2Semi = value;
            } else if (paramId == "osc2Detune") {
                p->osc2Detune = value;
            } else if (paramId == "oscMix") {
                p->oscMix = value;
            } else if (paramId == "osc1Sync") {
                p->osc1Sync = value;
            } else if (paramId == "osc2Sync") {
                p->osc2Sync = value;
            } else if (paramId == "noiseLevel") {
                p->noiseLevel = value;
            } else if (paramId == "oscMixMode") {
                p->oscMixMode = std::clamp(static_cast<int>(std::lround(value * 4.0f)), 0, 4);
            } else if (paramId == "unisonVoices") {
                p->unisonVoices = value;
            } else if (paramId == "unisonDetune") {
                p->unisonDetune = value;
            } else if (paramId == "filterEnvAmount") {
                p->filterEnvAmount = value;
            } else if (paramId == "filterAttack") {
                p->filterAttack = value;
            } else if (paramId == "filterDecay") {
                p->filterDecay = value;
            } else if (paramId == "filterSustain") {
                p->filterSustain = value;
            } else if (paramId == "filterRelease") {
                p->filterRelease = value;
            } else if (paramId == "glideMs") {
                p->glideMs = value;
            } else if (paramId == "velocitySensitivity") {
                p->velocitySensitivity = value;
            }
        }
        break;
    case DeviceNodeKind::KickGenerator:
        if (auto* p = std::get_if<KickGeneratorParams>(&params)) {
            if (paramId == "gain") {
                p->gain = value;
            } else if (paramId == "kickPitch") {
                p->kickPitch = value;
            } else if (paramId == "kickPunch") {
                p->kickPunch = value;
            } else if (paramId == "kickDecay") {
                p->kickDecay = value;
            } else if (paramId == "kickClick") {
                p->kickClick = value;
            } else if (paramId == "kickTone") {
                p->kickTone = value;
            } else if (paramId == "kickVelocity") {
                p->kickVelocity = value;
            }
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

    out.pointCount = static_cast<int>(std::min(clip.points.size(), sizeof(out.points) / sizeof(out.points[0])));
    for (int i = 0; i < out.pointCount; ++i) {
        out.points[i].beat = static_cast<float>(clip.points[static_cast<size_t>(i)].beat);
        out.points[i].value = clip.points[static_cast<size_t>(i)].value;
    }
    return out.pointCount > 0;
}

} // namespace audioapp
