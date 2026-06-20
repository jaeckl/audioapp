#include "audioapp/devices/CrashGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/CrashGeneratorInstance.hpp"

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

CrashGeneratorInstance instanceFromSnapshot(const DeviceState& state) {
    CrashGeneratorInstance instance;
    instance.crashModel = state.crashModel;
    instance.crashColor = state.crashColor;
    instance.crashSpread = state.crashSpread;
    instance.crashDecay = state.crashDecay;
    instance.crashVelocity = state.crashVelocity;
    return instance;
}

void applyInstanceToSnapshot(const CrashGeneratorInstance& instance, DeviceState& state) {
    state.crashModel = instance.crashModel;
    state.crashColor = instance.crashColor;
    state.crashSpread = instance.crashSpread;
    state.crashDecay = instance.crashDecay;
    state.crashVelocity = instance.crashVelocity;
}

} // namespace

std::string CrashGeneratorDeviceType::typeId() const {
    return device_types::kCrashGenerator;
}

DeviceSlot CrashGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = CrashGeneratorInstance{};
    return slot;
}

DeviceState CrashGeneratorDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kCrashGenerator);
    applyInstanceToSnapshot(std::get<CrashGeneratorInstance>(slot.instance), state);
    return state;
}

DeviceSlot CrashGeneratorDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult CrashGeneratorDeviceType::setParameter(DeviceSlot& slot,
                                                             std::string_view parameterId,
                                                             float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<CrashGeneratorInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "crashModel") {
        instance.crashModel = clamped;
    } else if (parameterId == "crashColor") {
        instance.crashColor = clamped;
    } else if (parameterId == "crashSpread") {
        instance.crashSpread = clamped;
    } else if (parameterId == "crashDecay") {
        instance.crashDecay = clamped;
    } else if (parameterId == "crashVelocity") {
        instance.crashVelocity = clamped;
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool CrashGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                  std::string_view,
                                                  const std::string&,
                                                  const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> CrashGeneratorDeviceType::modulatableParams() const {
    return {"gain", "pan", "crashColor", "crashSpread", "crashDecay", "crashVelocity"};
}

void CrashGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                 const PlaybackBuildContext&,
                                                 DeviceNodePlayback& out) const {
    const auto& instance = std::get<CrashGeneratorInstance>(slot.instance);
    out.kind = DeviceNodeKind::CrashGenerator;
    out.params = instance.toPlaybackParams(slot.gain);
}

bool CrashGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                   const PlaybackBuildContext&,
                                                   LiveInstrumentSnapshot& out) const {
    const auto& instance = std::get<CrashGeneratorInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::CrashGenerator;
    out.gain = slot.gain;
    out.crash = instance.toPlaybackParams(slot.gain);
    return true;
}

juce::var CrashGeneratorDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<CrashGeneratorInstance>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("crashModel", static_cast<double>(inst.crashModel));
    parameters->setProperty("crashColor", static_cast<double>(inst.crashColor));
    parameters->setProperty("crashSpread", static_cast<double>(inst.crashSpread));
    parameters->setProperty("crashDecay", static_cast<double>(inst.crashDecay));
    parameters->setProperty("crashVelocity", static_cast<double>(inst.crashVelocity));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot CrashGeneratorDeviceType::varToSlot(const juce::var& obj) const {
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
            CrashGeneratorInstance inst;
            inst.crashModel = readFloat("crashModel", 0.0f);
            if (p->hasProperty("crashColor")) {
                inst.crashColor = readFloat("crashColor", 0.62f);
            } else {
                const float wash = readFloat("crashWash", 0.60f);
                const float bright = readFloat("crashBright", 0.65f);
                inst.crashColor = (wash + bright) * 0.5f;
            }
            inst.crashSpread = readFloat("crashSpread", 0.50f);
            inst.crashDecay = readFloat("crashDecay", 0.55f);
            inst.crashVelocity = readFloat("crashVelocity", 1.0f);
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp
