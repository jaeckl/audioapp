#include "audioapp/devices/KickGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/KickGeneratorInstance.hpp"

#include <juce_core/juce_core.h>

#include <algorithm>

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

KickGeneratorInstance instanceFromSnapshot(const DeviceState& state) {
    KickGeneratorInstance instance;
    instance.kickModel = state.kickModel;
    instance.kickPitch = state.kickPitch;
    instance.kickPunch = state.kickPunch;
    instance.kickDecay = state.kickDecay;
    instance.kickClick = state.kickClick;
    instance.kickTone = state.kickTone;
    instance.kickVelocity = state.kickVelocity;
    instance.kickKeyTrack = state.kickKeyTrack;
    return instance;
}

void applyInstanceToSnapshot(const KickGeneratorInstance& instance, DeviceState& state) {
    state.kickModel = instance.kickModel;
    state.kickPitch = instance.kickPitch;
    state.kickPunch = instance.kickPunch;
    state.kickDecay = instance.kickDecay;
    state.kickClick = instance.kickClick;
    state.kickTone = instance.kickTone;
    state.kickVelocity = instance.kickVelocity;
    state.kickKeyTrack = instance.kickKeyTrack;
}

} // namespace

std::string KickGeneratorDeviceType::typeId() const {
    return device_types::kKickGenerator;
}

DeviceSlot KickGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = KickGeneratorInstance{};
    return slot;
}

DeviceState KickGeneratorDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kKickGenerator);
    applyInstanceToSnapshot(std::get<KickGeneratorInstance>(slot.instance), state);
    return state;
}

DeviceSlot KickGeneratorDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult KickGeneratorDeviceType::setParameter(DeviceSlot& slot,
                                                            std::string_view parameterId,
                                                            float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<KickGeneratorInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "kickModel") {
        instance.kickModel = clamped;
    } else if (parameterId == "kickPitch") {
        instance.kickPitch = clamped;
    } else if (parameterId == "kickPunch") {
        instance.kickPunch = clamped;
    } else if (parameterId == "kickDecay") {
        instance.kickDecay = clamped;
    } else if (parameterId == "kickClick") {
        instance.kickClick = clamped;
    } else if (parameterId == "kickTone") {
        instance.kickTone = clamped;
    } else if (parameterId == "kickVelocity") {
        instance.kickVelocity = clamped;
    } else if (parameterId == "kickKeyTrack") {
        instance.kickKeyTrack = clamped >= 0.5f ? 1.0f : 0.0f;
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool KickGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                 std::string_view,
                                                 const std::string&,
                                                 const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> KickGeneratorDeviceType::modulatableParams() const {
    return {"gain", "pan", "kickPitch", "kickPunch", "kickDecay", "kickClick", "kickTone",
            "kickVelocity", "kickKeyTrack"};
}

void KickGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                const PlaybackBuildContext&,
                                                DeviceNodePlayback& out) const {
    const auto& instance = std::get<KickGeneratorInstance>(slot.instance);
    out.kind = DeviceNodeKind::KickGenerator;
    out.params = instance.toPlaybackParams(slot.gain);
}

bool KickGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                  const PlaybackBuildContext&,
                                                  LiveInstrumentSnapshot& out) const {
    const auto& instance = std::get<KickGeneratorInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::KickGenerator;
    out.gain = slot.gain;
    out.kick = instance.toPlaybackParams(slot.gain);
    return true;
}

juce::var KickGeneratorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<KickGeneratorInstance>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("kickModel", static_cast<double>(inst.kickModel));
    parameters->setProperty("kickPitch", static_cast<double>(inst.kickPitch));
    parameters->setProperty("kickPunch", static_cast<double>(inst.kickPunch));
    parameters->setProperty("kickDecay", static_cast<double>(inst.kickDecay));
    parameters->setProperty("kickClick", static_cast<double>(inst.kickClick));
    parameters->setProperty("kickTone", static_cast<double>(inst.kickTone));
    parameters->setProperty("kickVelocity", static_cast<double>(inst.kickVelocity));
    parameters->setProperty("kickKeyTrack", static_cast<double>(inst.kickKeyTrack));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot KickGeneratorDeviceType::varToSlot(const juce::var& obj) const {
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
            KickGeneratorInstance inst;
            inst.kickModel = readFloat("kickModel", 0.0f);
            inst.kickPitch = readFloat("kickPitch", 0.55f);
            inst.kickPunch = readFloat("kickPunch", 0.60f);
            inst.kickDecay = readFloat("kickDecay", 0.50f);
            inst.kickClick = readFloat("kickClick", 0.35f);
            inst.kickTone = readFloat("kickTone", 0.50f);
            inst.kickVelocity = readFloat("kickVelocity", 1.0f);
            inst.kickKeyTrack = readFloat("kickKeyTrack", 1.0f);
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp
