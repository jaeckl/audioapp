#include "audioapp/devices/FourBandEqDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/FrequencyFxModel.hpp"

#include <algorithm>
#include <cstring>
#include <juce_core/juce_core.h>

namespace audioapp {

std::string FourBandEqDeviceType::typeId() const { return device_types::kFourBandEq; }

DeviceSlot FourBandEqDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = FourBandEqModel{};
    return slot;
}


DeviceParameterResult FourBandEqDeviceType::setParameter(DeviceSlot& slot,
                                                        std::string_view parameterId,
                                                        float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<FourBandEqModel>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "ffxBand1Freq") {
        instance.ffxBand1Freq = clamped;
    } else if (parameterId == "ffxBand1Gain") {
        instance.ffxBand1Gain = clamped;
    } else if (parameterId == "ffxBand1Q") {
        instance.ffxBand1Q = clamped;
    } else if (parameterId == "ffxBand2Freq") {
        instance.ffxBand2Freq = clamped;
    } else if (parameterId == "ffxBand2Gain") {
        instance.ffxBand2Gain = clamped;
    } else if (parameterId == "ffxBand2Q") {
        instance.ffxBand2Q = clamped;
    } else if (parameterId == "ffxBand3Freq") {
        instance.ffxBand3Freq = clamped;
    } else if (parameterId == "ffxBand3Gain") {
        instance.ffxBand3Gain = clamped;
    } else if (parameterId == "ffxBand3Q") {
        instance.ffxBand3Q = clamped;
    } else if (parameterId == "ffxBand4Freq") {
        instance.ffxBand4Freq = clamped;
    } else if (parameterId == "ffxBand4Gain") {
        instance.ffxBand4Gain = clamped;
    } else if (parameterId == "ffxBand4Q") {
        instance.ffxBand4Q = clamped;
    } else {
        return result;
    }
    result.handled = true;
    return result;
}

bool FourBandEqDeviceType::setStringParameter(DeviceSlot&,
                                              std::string_view,
                                              const std::string&,
                                              const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> FourBandEqDeviceType::modulatableParams() const {
    return {"gain", "pan",
            "ffxBand1Freq", "ffxBand1Gain", "ffxBand1Q",
            "ffxBand2Freq", "ffxBand2Gain", "ffxBand2Q",
            "ffxBand3Freq", "ffxBand3Gain", "ffxBand3Q",
            "ffxBand4Freq", "ffxBand4Gain", "ffxBand4Q"};
}

void FourBandEqDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                             const PlaybackBuildContext&,
                                             DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::FourBandEq;
    out.params = std::get<FourBandEqModel>(slot.instance).toPlaybackParams();
}

bool FourBandEqDeviceType::buildLiveInstrument(const DeviceSlot&,
                                               const PlaybackBuildContext&,
                                               LiveInstrumentSnapshot&) const {
    return false;
}

juce::var FourBandEqDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<FourBandEqModel>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
    parameters->setProperty("ffxBand1Freq", static_cast<double>(inst.ffxBand1Freq));
    parameters->setProperty("ffxBand1Gain", static_cast<double>(inst.ffxBand1Gain));
    parameters->setProperty("ffxBand1Q", static_cast<double>(inst.ffxBand1Q));
    parameters->setProperty("ffxBand2Freq", static_cast<double>(inst.ffxBand2Freq));
    parameters->setProperty("ffxBand2Gain", static_cast<double>(inst.ffxBand2Gain));
    parameters->setProperty("ffxBand2Q", static_cast<double>(inst.ffxBand2Q));
    parameters->setProperty("ffxBand3Freq", static_cast<double>(inst.ffxBand3Freq));
    parameters->setProperty("ffxBand3Gain", static_cast<double>(inst.ffxBand3Gain));
    parameters->setProperty("ffxBand3Q", static_cast<double>(inst.ffxBand3Q));
    parameters->setProperty("ffxBand4Freq", static_cast<double>(inst.ffxBand4Freq));
    parameters->setProperty("ffxBand4Gain", static_cast<double>(inst.ffxBand4Gain));
    parameters->setProperty("ffxBand4Q", static_cast<double>(inst.ffxBand4Q));

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

DeviceSlot FourBandEqDeviceType::varToSlot(const juce::var& obj) const {
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
            FourBandEqModel inst;
            inst.ffxBand1Freq = readFloat("ffxBand1Freq", 0.15f);
            inst.ffxBand1Gain = readFloat("ffxBand1Gain", 0.5f);
            inst.ffxBand1Q = readFloat("ffxBand1Q", 0.5f);
            inst.ffxBand2Freq = readFloat("ffxBand2Freq", 0.35f);
            inst.ffxBand2Gain = readFloat("ffxBand2Gain", 0.5f);
            inst.ffxBand2Q = readFloat("ffxBand2Q", 0.5f);
            inst.ffxBand3Freq = readFloat("ffxBand3Freq", 0.6f);
            inst.ffxBand3Gain = readFloat("ffxBand3Gain", 0.5f);
            inst.ffxBand3Q = readFloat("ffxBand3Q", 0.5f);
            inst.ffxBand4Freq = readFloat("ffxBand4Freq", 0.85f);
            inst.ffxBand4Gain = readFloat("ffxBand4Gain", 0.5f);
            inst.ffxBand4Q = readFloat("ffxBand4Q", 0.5f);
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp