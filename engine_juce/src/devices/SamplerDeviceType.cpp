#include "audioapp/devices/SamplerDeviceType.hpp"

#include "audioapp/SampleBank.hpp"
#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/SamplerInstance.hpp"

#include <juce_core/juce_core.h>
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

DeviceSlot SamplerDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = SamplerInstance{};
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

juce::var SamplerDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<SamplerInstance>(slot.instance);

    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("sampleId", juce::String::fromUTF8(inst.sampleId.c_str()));
    parameters->setProperty("attack", static_cast<double>(inst.attack));
    parameters->setProperty("decay", static_cast<double>(inst.decay));
    parameters->setProperty("sustain", static_cast<double>(inst.sustain));
    parameters->setProperty("release", static_cast<double>(inst.release));
    parameters->setProperty("filterCutoff", static_cast<double>(inst.filterCutoff));
    parameters->setProperty("filterQ", static_cast<double>(inst.filterQ));
    parameters->setProperty("filterMode", inst.filterMode);
    parameters->setProperty("trimStartSec", static_cast<double>(inst.trimStartSec));
    parameters->setProperty("trimEndSec", static_cast<double>(inst.trimEndSec));
    parameters->setProperty("regionStartSec", static_cast<double>(inst.regionStartSec));
    parameters->setProperty("regionEndSec", static_cast<double>(inst.regionEndSec));
    parameters->setProperty("rootPitch", static_cast<double>(inst.rootPitch));
    parameters->setProperty("rootFineTune", static_cast<double>(inst.rootFineTune));
    parameters->setProperty("playbackMode", inst.playbackMode);

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot SamplerDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        const auto params = object->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {
            auto readFloat = [&](const char* key, float fallback) -> float {
                const auto v = p->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            auto readString = [&](const char* key) -> std::string {
                const auto v = p->getProperty(key);
                if (v.isString())
                    return v.toString().toStdString();
                return {};
            };
            slot.gain = readFloat("gain", 1.0f);
            slot.pan = readFloat("pan", 0.5f);
            slot.bypassed = readFloat("bypass", 0.0f) >= 0.5f;

            SamplerInstance inst;
            inst.sampleId = readString("sampleId");
            inst.attack = readFloat("attack", 0.01f);
            inst.decay = readFloat("decay", 0.3f);
            inst.sustain = readFloat("sustain", 0.7f);
            inst.release = readFloat("release", 0.4f);
            inst.filterCutoff = readFloat("filterCutoff", 1.0f);
            inst.filterQ = readFloat("filterQ", 0.35f);
            inst.filterMode = static_cast<int>(readFloat("filterMode", 0.0f));
            inst.trimStartSec = readFloat("trimStartSec", 0.0f);
            inst.trimEndSec = readFloat("trimEndSec", 0.0f);
            inst.regionStartSec = readFloat("regionStartSec", 0.0f);
            inst.regionEndSec = readFloat("regionEndSec", 0.0f);
            inst.rootPitch = readFloat("rootPitch", 60.0f);
            inst.rootFineTune = std::clamp(readFloat("rootFineTune", 0.0f), -100.0f, 100.0f);
            if (p->hasProperty("playbackMode")) {
                inst.playbackMode = static_cast<int>(readFloat("playbackMode", 0.0f));
            } else {
                inst.playbackMode = inst.regionEndSec > 0.0f ? 1 : 0;
            }
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp
