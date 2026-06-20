#include "audioapp/devices/ExpanderDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/ExpanderInstance.hpp"

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

ExpanderInstance instanceFromSnapshot(const DeviceState& state) {
    ExpanderInstance instance;
    instance.inputGain = state.inputGain;
    instance.expandThreshold = state.expandThreshold;
    instance.expandRatio = state.expandRatio;
    instance.expandAttack = state.expandAttack;
    instance.expandRelease = state.expandRelease;
    instance.expandRange = state.expandRange;
    return instance;
}

void applyInstanceToSnapshot(const ExpanderInstance& instance, DeviceState& state) {
    state.inputGain = instance.inputGain;
    state.expandThreshold = instance.expandThreshold;
    state.expandRatio = instance.expandRatio;
    state.expandAttack = instance.expandAttack;
    state.expandRelease = instance.expandRelease;
    state.expandRange = instance.expandRange;
}

} // namespace

std::string ExpanderDeviceType::typeId() const { return device_types::kExpander; }

DeviceSlot ExpanderDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = ExpanderInstance{};
    return slot;
}

DeviceState ExpanderDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kExpander);
    applyInstanceToSnapshot(std::get<ExpanderInstance>(slot.instance), state);
    return state;
}

DeviceSlot ExpanderDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

juce::var ExpanderDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<ExpanderInstance>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("inputGain", static_cast<double>(inst.inputGain));
    parameters->setProperty("expandThreshold", static_cast<double>(inst.expandThreshold));
    parameters->setProperty("expandRatio", static_cast<double>(inst.expandRatio));
    parameters->setProperty("expandAttack", static_cast<double>(inst.expandAttack));
    parameters->setProperty("expandRelease", static_cast<double>(inst.expandRelease));
    parameters->setProperty("expandRange", static_cast<double>(inst.expandRange));

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));
    object->setProperty("parameters", juce::var(parameters));
    object->setProperty("meters", juce::var(meters));
    return juce::var(object);
}

DeviceSlot ExpanderDeviceType::varToSlot(const juce::var& obj) const {
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
            ExpanderInstance inst;
            inst.inputGain = readFloat("inputGain", 1.0f);
            inst.expandThreshold = readFloat("expandThreshold", 0.40f);
            inst.expandRatio = readFloat("expandRatio", 0.45f);
            inst.expandAttack = readFloat("expandAttack", 0.25f);
            inst.expandRelease = readFloat("expandRelease", 0.55f);
            inst.expandRange = readFloat("expandRange", 0.15f);
            slot.instance = inst;
        }
    }
    return slot;
}

DeviceParameterResult ExpanderDeviceType::setParameter(DeviceSlot& slot,
                                                       std::string_view parameterId,
                                                       float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<ExpanderInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "inputGain") {
        instance.inputGain = clamped;
    } else if (parameterId == "expandThreshold") {
        instance.expandThreshold = clamped;
    } else if (parameterId == "expandRatio") {
        instance.expandRatio = clamped;
    } else if (parameterId == "expandAttack") {
        instance.expandAttack = clamped;
    } else if (parameterId == "expandRelease") {
        instance.expandRelease = clamped;
    } else if (parameterId == "expandRange") {
        instance.expandRange = clamped;
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool ExpanderDeviceType::setStringParameter(DeviceSlot&,
                                            std::string_view,
                                            const std::string&,
                                            const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> ExpanderDeviceType::modulatableParams() const {
    return {"gain", "pan", "inputGain", "expandThreshold", "expandRatio", "expandAttack", "expandRelease",
            "expandRange"};
}

void ExpanderDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                           const PlaybackBuildContext&,
                                           DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Expander;
    out.params = std::get<ExpanderInstance>(slot.instance).toPlaybackParams();
}

bool ExpanderDeviceType::buildLiveInstrument(const DeviceSlot&,
                                             const PlaybackBuildContext&,
                                             LiveInstrumentSnapshot&) const {
    return false;
}

} // namespace audioapp
