#include "audioapp/devices/LimiterDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/LimiterInstance.hpp"

#include <algorithm>
#include <juce_core/juce_core.h>

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

LimiterInstance instanceFromSnapshot(const DeviceState& state) {
    LimiterInstance instance;
    instance.inputGain = state.inputGain;
    instance.limitCeiling = state.limitCeiling;
    instance.limitAttack = state.limitAttack;
    instance.limitRelease = state.limitRelease;
    instance.limitKnee = state.limitKnee;
    instance.limitDrive = state.limitDrive;
    instance.limitMakeup = state.limitMakeup;
    return instance;
}

void applyInstanceToSnapshot(const LimiterInstance& instance, DeviceState& state) {
    state.inputGain = instance.inputGain;
    state.limitCeiling = instance.limitCeiling;
    state.limitAttack = instance.limitAttack;
    state.limitRelease = instance.limitRelease;
    state.limitKnee = instance.limitKnee;
    state.limitDrive = instance.limitDrive;
    state.limitMakeup = instance.limitMakeup;
}

} // namespace

std::string LimiterDeviceType::typeId() const { return device_types::kLimiter; }

DeviceSlot LimiterDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = LimiterInstance{};
    return slot;
}

DeviceState LimiterDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kLimiter);
    applyInstanceToSnapshot(std::get<LimiterInstance>(slot.instance), state);
    return state;
}

DeviceSlot LimiterDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult LimiterDeviceType::setParameter(DeviceSlot& slot,
                                                      std::string_view parameterId,
                                                      float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<LimiterInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "inputGain") {
        instance.inputGain = clamped;
    } else if (parameterId == "limitCeiling") {
        instance.limitCeiling = clamped;
    } else if (parameterId == "limitAttack") {
        instance.limitAttack = clamped;
    } else if (parameterId == "limitRelease") {
        instance.limitRelease = clamped;
    } else if (parameterId == "limitKnee") {
        instance.limitKnee = clamped;
    } else if (parameterId == "limitDrive") {
        instance.limitDrive = clamped;
    } else if (parameterId == "limitMakeup") {
        instance.limitMakeup = clamped;
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool LimiterDeviceType::setStringParameter(DeviceSlot&,
                                           std::string_view,
                                           const std::string&,
                                           const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> LimiterDeviceType::modulatableParams() const {
    return {"gain", "pan", "inputGain", "limitCeiling", "limitAttack", "limitRelease", "limitKnee",
            "limitDrive", "limitMakeup"};
}

void LimiterDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                          const PlaybackBuildContext&,
                                          DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Limiter;
    out.params = std::get<LimiterInstance>(slot.instance).toPlaybackParams();
}

bool LimiterDeviceType::buildLiveInstrument(const DeviceSlot&,
                                            const PlaybackBuildContext&,
                                            LiveInstrumentSnapshot&) const {
    return false;
}

juce::var LimiterDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<LimiterInstance>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("inputGain", static_cast<double>(inst.inputGain));
    parameters->setProperty("limitCeiling", static_cast<double>(inst.limitCeiling));
    parameters->setProperty("limitAttack", static_cast<double>(inst.limitAttack));
    parameters->setProperty("limitRelease", static_cast<double>(inst.limitRelease));
    parameters->setProperty("limitKnee", static_cast<double>(inst.limitKnee));
    parameters->setProperty("limitDrive", static_cast<double>(inst.limitDrive));
    parameters->setProperty("limitMakeup", static_cast<double>(inst.limitMakeup));

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String(slot.id));
    object->setProperty("type", juce::String(typeId()));
    object->setProperty("parameters", juce::var(parameters));
    object->setProperty("meters", juce::var(meters));
    return juce::var(object);
}

DeviceSlot LimiterDeviceType::varToSlot(const juce::var& obj) const {
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
            slot.gain = readFloat("gain", 1.0f);
            slot.pan = readFloat("pan", 0.5f);
            slot.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            LimiterInstance inst;
            inst.inputGain = readFloat("inputGain", 1.0f);
            inst.limitCeiling = readFloat("limitCeiling", 0.85f);
            inst.limitAttack = readFloat("limitAttack", 0.10f);
            inst.limitRelease = readFloat("limitRelease", 0.40f);
            inst.limitKnee = readFloat("limitKnee", 0.0f);
            inst.limitDrive = readFloat("limitDrive", 0.0f);
            inst.limitMakeup = readFloat("limitMakeup", 0.0f);
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp
