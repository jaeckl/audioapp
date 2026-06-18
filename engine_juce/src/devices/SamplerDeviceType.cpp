#include "audioapp/devices/SamplerDeviceType.hpp"

#include "audioapp/SampleBank.hpp"
#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/SamplerInstance.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {
namespace {

void resolveSampleFrames(const SamplerInstance& instance,
                         const PlaybackBuildContext& context,
                         SamplerParams& params) {
    params.samplerPcm = nullptr;
    params.samplerFrameCount = 0;
    params.samplerPcmSampleRate = 48000.0;
    params.trimStartFrame = 0;
    params.trimEndFrame = 0;
    params.regionStartFrame = 0;
    params.regionEndFrame = 0;

    if (context.sampleBank == nullptr || instance.sampleId.empty()) {
        return;
    }
    const auto* sample = context.sampleBank->findSample(instance.sampleId);
    if (sample == nullptr || sample->pcm.empty()) {
        return;
    }

    params.samplerPcm = sample->pcm.data();
    params.samplerFrameCount = static_cast<int>(sample->pcm.size());
    params.samplerPcmSampleRate = sample->sampleRate;
    const int frameCount = params.samplerFrameCount;
    params.trimStartFrame = std::clamp(static_cast<int>(instance.trimStartSec * sample->sampleRate),
                                       0,
                                       std::max(0, frameCount - 1));
    params.trimEndFrame = instance.trimEndSec > 0.0f
        ? std::clamp(static_cast<int>(instance.trimEndSec * sample->sampleRate),
                     params.trimStartFrame + 1,
                     frameCount)
        : frameCount;
    if (instance.regionEndSec > 0.0f) {
        const int rawStart = static_cast<int>(instance.regionStartSec * sample->sampleRate);
        params.regionStartFrame = std::clamp(rawStart,
                                             params.trimStartFrame,
                                             params.trimEndFrame - 1);
        const int rawEnd = static_cast<int>(instance.regionEndSec * sample->sampleRate);
        params.regionEndFrame = std::clamp(rawEnd,
                                           params.regionStartFrame + 1,
                                           params.trimEndFrame);
    }
}

void resolveLiveSampleFrames(const SamplerInstance& instance,
                             const PlaybackBuildContext& context,
                             LiveInstrumentSnapshot& out) {
    out.samplerPcm = nullptr;
    out.samplerFrameCount = 0;
    out.samplerPcmSampleRate = 48000.0;
    out.trimStartFrame = 0;
    out.trimEndFrame = 0;
    out.regionStartFrame = 0;
    out.regionEndFrame = 0;

    if (context.sampleBank == nullptr || instance.sampleId.empty()) {
        return;
    }
    const auto* sample = context.sampleBank->findSample(instance.sampleId);
    if (sample == nullptr || sample->pcm.empty()) {
        return;
    }

    out.samplerPcm = sample->pcm.data();
    out.samplerFrameCount = static_cast<int>(sample->pcm.size());
    out.samplerPcmSampleRate = sample->sampleRate;
    const double trimStartSec = std::max(0.0, static_cast<double>(instance.trimStartSec));
    const double trimEndSec = instance.trimEndSec > trimStartSec
                                  ? static_cast<double>(instance.trimEndSec)
                                  : static_cast<double>(sample->pcm.size()) / sample->sampleRate;
    out.trimStartFrame = static_cast<int>(trimStartSec * sample->sampleRate);
    out.trimEndFrame = static_cast<int>(trimEndSec * sample->sampleRate);
    if (out.trimEndFrame <= out.trimStartFrame) {
        out.trimEndFrame = out.samplerFrameCount;
    }
    if (instance.regionEndSec > 0.0f) {
        const int rawRegStart = static_cast<int>(instance.regionStartSec * sample->sampleRate);
        out.regionStartFrame = std::clamp(rawRegStart, out.trimStartFrame, out.trimEndFrame - 1);
        const int rawRegEnd = static_cast<int>(instance.regionEndSec * sample->sampleRate);
        out.regionEndFrame = std::clamp(rawRegEnd, out.regionStartFrame + 1, out.trimEndFrame);
    }
}

} // namespace

std::string SamplerDeviceType::typeId() const {
    return device_types::kSampler;
}

DeviceState SamplerDeviceType::createDefault(const std::string& deviceId) const {
    DeviceState state;
    state.id = deviceId;
    SamplerInstance{}.applyTo(state);
    return state;
}

DeviceParameterResult SamplerDeviceType::setParameter(DeviceState& state,
                                                      std::string_view parameterId,
                                                      float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(state, parameterId, value)) {
        result.handled = true;
        return result;
    }

    SamplerInstance instance = SamplerInstance::fromState(state);
    if (parameterId == "attack" || parameterId == "decay" || parameterId == "release") {
        const float clamped = std::clamp(value, 0.0f, 1.0f);
        if (parameterId == "attack") {
            instance.attack = clamped;
        } else if (parameterId == "decay") {
            instance.decay = clamped;
        } else {
            instance.release = clamped;
        }
    } else if (parameterId == "sustain") {
        instance.sustain = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "filterCutoff") {
        instance.filterCutoff = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "filterQ") {
        instance.filterQ = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "filterMode") {
        instance.filterMode = std::clamp(static_cast<int>(std::lround(value)), 0, 3);
    } else if (parameterId == "trimStartSec") {
        instance.trimStartSec = std::max(0.0f, value);
    } else if (parameterId == "trimEndSec") {
        instance.trimEndSec = std::max(0.0f, value);
    } else if (parameterId == "regionStartSec") {
        instance.regionStartSec = std::max(0.0f, value);
    } else if (parameterId == "regionEndSec") {
        instance.regionEndSec = std::max(0.0f, value);
    } else {
        return result;
    }

    instance.applyTo(state);
    result.handled = true;
    return result;
}

bool SamplerDeviceType::setStringParameter(DeviceState& state,
                                           std::string_view parameterId,
                                           const std::string& value,
                                           const PlaybackBuildContext& context) const {
    if (parameterId != "sampleId") {
        return false;
    }
    if (!value.empty() && context.sampleBank != nullptr &&
        context.sampleBank->findSample(value) == nullptr) {
        return false;
    }
    SamplerInstance instance = SamplerInstance::fromState(state);
    instance.sampleId = value;
    instance.applyTo(state);
    return true;
}

std::vector<std::string_view> SamplerDeviceType::modulatableParams() const {
    return {"gain", "pan", "attack", "decay", "sustain", "release", "filterCutoff", "filterQ"};
}

void SamplerDeviceType::buildPlaybackNode(const DeviceState& state,
                                          const PlaybackBuildContext& context,
                                          DeviceNodePlayback& out) const {
    const SamplerInstance instance = SamplerInstance::fromState(state);
    SamplerParams params;
    params.attack = instance.attack;
    params.decay = instance.decay;
    params.sustain = instance.sustain;
    params.release = instance.release;
    params.filterCutoff = instance.filterCutoff;
    params.filterQ = instance.filterQ;
    params.filterMode = instance.filterMode;
    resolveSampleFrames(instance, context, params);
    out.kind = DeviceNodeKind::Sampler;
    out.params = params;
}

bool SamplerDeviceType::buildLiveInstrument(const DeviceState& state,
                                            const PlaybackBuildContext& context,
                                            LiveInstrumentSnapshot& out) const {
    const SamplerInstance instance = SamplerInstance::fromState(state);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::Sampler;
    out.gain = state.gain;
    out.rootPitch = 60;
    out.attack = instance.attack;
    out.decay = instance.decay;
    out.sustain = instance.sustain;
    out.release = instance.release;
    out.filterCutoff = instance.filterCutoff;
    out.filterQ = instance.filterQ;
    out.filterMode = instance.filterMode;
    resolveLiveSampleFrames(instance, context, out);
    return true;
}

} // namespace audioapp
