#include "audioapp/devices/SamplerDeviceType.hpp"

#include "audioapp/SampleBank.hpp"
#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/SamplerInstance.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {
namespace {

DeviceState stripSnapshot(const DeviceSlot& slot, std::string_view typeId) {
    DeviceState state;
    state.id = slot.id;
    state.type = std::string(typeId);
    state.gain = slot.gain;
    state.pan = slot.pan;
    state.bypassed = slot.bypassed;
    return state;
}

SamplerInstance instanceFromSnapshot(const DeviceState& state) {
    SamplerInstance instance;
    instance.sampleId = state.sampleId;
    instance.attack = state.attack;
    instance.decay = state.decay;
    instance.sustain = state.sustain;
    instance.release = state.release;
    instance.filterCutoff = state.filterCutoff;
    instance.filterQ = state.filterQ;
    instance.filterMode = state.filterMode;
    instance.filterEnvAmount = state.filterEnvAmount;
    instance.filterAttack = state.filterAttack;
    instance.filterDecay = state.filterDecay;
    instance.filterSustain = state.filterSustain;
    instance.filterRelease = state.filterRelease;
    instance.trimStartSec = state.trimStartSec;
    instance.trimEndSec = state.trimEndSec;
    instance.regionStartSec = state.regionStartSec;
    instance.regionEndSec = state.regionEndSec;
    instance.rootPitch = state.rootPitch;
    instance.rootFineTune = state.rootFineTune;
    instance.playbackMode = state.playbackMode;
    return instance;
}

void applyInstanceToSnapshot(const SamplerInstance& instance, DeviceState& state) {
    state.sampleId = instance.sampleId;
    state.attack = instance.attack;
    state.decay = instance.decay;
    state.sustain = instance.sustain;
    state.release = instance.release;
    state.filterCutoff = instance.filterCutoff;
    state.filterQ = instance.filterQ;
    state.filterMode = instance.filterMode;
    state.filterEnvAmount = instance.filterEnvAmount;
    state.filterAttack = instance.filterAttack;
    state.filterDecay = instance.filterDecay;
    state.filterSustain = instance.filterSustain;
    state.filterRelease = instance.filterRelease;
    state.trimStartSec = instance.trimStartSec;
    state.trimEndSec = instance.trimEndSec;
    state.regionStartSec = instance.regionStartSec;
    state.regionEndSec = instance.regionEndSec;
    state.rootPitch = instance.rootPitch;
    state.rootFineTune = instance.rootFineTune;
    state.playbackMode = instance.playbackMode;
}

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

DeviceSlot SamplerDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = SamplerInstance{};
    return slot;
}

DeviceState SamplerDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kSampler);
    applyInstanceToSnapshot(std::get<SamplerInstance>(slot.instance), state);
    return state;
}

DeviceSlot SamplerDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult SamplerDeviceType::setParameter(DeviceSlot& slot,
                                                      std::string_view parameterId,
                                                      float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<SamplerInstance>(slot.instance);
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
    } else if (parameterId == "filterEnvAmount") {
        instance.filterEnvAmount = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "filterAttack") {
        instance.filterAttack = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "filterDecay") {
        instance.filterDecay = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "filterSustain") {
        instance.filterSustain = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "filterRelease") {
        instance.filterRelease = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "trimStartSec") {
        instance.trimStartSec = std::max(0.0f, value);
    } else if (parameterId == "trimEndSec") {
        instance.trimEndSec = std::max(0.0f, value);
    } else if (parameterId == "regionStartSec") {
        instance.regionStartSec = std::max(0.0f, value);
    } else if (parameterId == "regionEndSec") {
        instance.regionEndSec = std::max(0.0f, value);
    } else if (parameterId == "rootPitch") {
        instance.rootPitch = std::clamp(value, 0.0f, 127.0f);
    } else if (parameterId == "rootFineTune") {
        instance.rootFineTune = std::clamp(value, -100.0f, 100.0f);
    } else if (parameterId == "playbackMode") {
        instance.playbackMode = std::clamp(static_cast<int>(std::lround(value)), 0, 2);
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool SamplerDeviceType::setStringParameter(DeviceSlot& slot,
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
    std::get<SamplerInstance>(slot.instance).sampleId = value;
    return true;
}

std::vector<std::string_view> SamplerDeviceType::modulatableParams() const {
    return {"gain", "pan", "attack", "decay", "sustain", "release", "filterCutoff", "filterQ",
            "filterEnvAmount", "filterAttack", "filterDecay", "filterSustain", "filterRelease",
            "rootPitch", "rootFineTune"};
}

void SamplerDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                          const PlaybackBuildContext& context,
                                          DeviceNodePlayback& out) const {
    const auto& instance = std::get<SamplerInstance>(slot.instance);
    SamplerParams params;
    params.attack = instance.attack;
    params.decay = instance.decay;
    params.sustain = instance.sustain;
    params.release = instance.release;
    params.filterCutoff = instance.filterCutoff;
    params.filterQ = instance.filterQ;
    params.filterMode = instance.filterMode;
    params.filterEnvAmount = instance.filterEnvAmount;
    params.filterAttack = instance.filterAttack;
    params.filterDecay = instance.filterDecay;
    params.filterSustain = instance.filterSustain;
    params.filterRelease = instance.filterRelease;
    params.rootPitch = static_cast<int>(std::lround(instance.rootPitch));
    params.rootFineTune = instance.rootFineTune;
    params.playbackMode = instance.playbackMode;
    resolveSampleFrames(instance, context, params);
    out.kind = DeviceNodeKind::Sampler;
    out.params = params;
}

bool SamplerDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                            const PlaybackBuildContext& context,
                                            LiveInstrumentSnapshot& out) const {
    const auto& instance = std::get<SamplerInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::Sampler;
    out.gain = slot.gain;
    out.rootPitch = static_cast<int>(std::lround(instance.rootPitch));
    out.rootFineTune = instance.rootFineTune;
    out.playbackMode = instance.playbackMode;
    out.attack = instance.attack;
    out.decay = instance.decay;
    out.sustain = instance.sustain;
    out.release = instance.release;
    out.filterCutoff = instance.filterCutoff;
    out.filterQ = instance.filterQ;
    out.filterMode = instance.filterMode;
    out.filterEnvAmount = instance.filterEnvAmount;
    out.filterAttack = instance.filterAttack;
    out.filterDecay = instance.filterDecay;
    out.filterSustain = instance.filterSustain;
    out.filterRelease = instance.filterRelease;
    resolveLiveSampleFrames(instance, context, out);
    return true;
}

} // namespace audioapp
