#include "audioapp/devices/FourBandEqDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/FrequencyFxModel.hpp"
#include "audioapp/devices/processors/FourBandEqProcessor.hpp"

#include <algorithm>
#include <cstring>
#include <juce_core/juce_core.h>

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string FourBandEqDeviceType::typeId() const { return device_types::kFourBandEq; }

DeviceSlot FourBandEqDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = FourBandEqModel{};

    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
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
    auto& instance = std::get<FourBandEqModel>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);

    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    switch (static_cast<FourBandEqParam>(id)) {
    case FourBandEqParam::Band1Freq: instance.ffxBand1Freq = clamped; break;
    case FourBandEqParam::Band1Gain: instance.ffxBand1Gain = clamped; break;
    case FourBandEqParam::Band1Q: instance.ffxBand1Q = clamped; break;
    case FourBandEqParam::Band2Freq: instance.ffxBand2Freq = clamped; break;
    case FourBandEqParam::Band2Gain: instance.ffxBand2Gain = clamped; break;
    case FourBandEqParam::Band2Q: instance.ffxBand2Q = clamped; break;
    case FourBandEqParam::Band3Freq: instance.ffxBand3Freq = clamped; break;
    case FourBandEqParam::Band3Gain: instance.ffxBand3Gain = clamped; break;
    case FourBandEqParam::Band3Q: instance.ffxBand3Q = clamped; break;
    case FourBandEqParam::Band4Freq: instance.ffxBand4Freq = clamped; break;
    case FourBandEqParam::Band4Gain: instance.ffxBand4Gain = clamped; break;
    case FourBandEqParam::Band4Q: instance.ffxBand4Q = clamped; break;
    default: return result;
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
    out.params = std::get<FourBandEqModel>(slot.config.instance).toPlaybackParams();
}

bool FourBandEqDeviceType::buildLiveInstrument(const DeviceSlot&,
                                               const PlaybackBuildContext&,
                                               LiveInstrumentSnapshot&) const {
    return false;
}

juce::var FourBandEqDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<FourBandEqModel>(slot.config.instance);
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

    auto* outObj = new juce::DynamicObject();
    const auto& panel = std::get<StereoOutputPanel>(slot.config.outputPanel);
    outObj->setProperty("type", "stereo");
    outObj->setProperty("gain", static_cast<double>(panel.gain));
    outObj->setProperty("pan", static_cast<double>(panel.pan));
    object->setProperty("outputPanel", juce::var(outObj));

    auto* inObj = new juce::DynamicObject();
    inObj->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(inObj));

    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("parameters", juce::var(parameters));
    object->setProperty("meters", juce::var(meters));
    return juce::var(object);
}

DeviceSlot FourBandEqDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.typeId = object->getProperty("type").toString().toStdString();

        const auto outputPanelVar = object->getProperty("outputPanel");
        bool hasPanel = outputPanelVar.isObject();
        if (hasPanel) {
            const auto* panel = outputPanelVar.getDynamicObject();
            StereoOutputPanel sp;
            sp.gain = static_cast<float>(static_cast<double>(panel->getProperty("gain")));
            sp.pan = static_cast<float>(static_cast<double>(panel->getProperty("pan")));
            slot.config.outputPanel = sp;

        }

        slot.config.bypassed = object->getProperty("bypass").isDouble()
            ? (static_cast<float>(static_cast<double>(object->getProperty("bypass"))) >= 0.5f)
            : false;

        const auto params = object->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {
            auto readFloat = [&](const char* key, float fallback) -> float {
                const auto v = p->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };

            if (!hasPanel) {
                const float oldGain = readFloat("gain", 1.0f);
                const float oldPan = readFloat("pan", 0.5f);
                slot.config.outputPanel = StereoOutputPanel{oldGain, oldPan};
                slot.config.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            }

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
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* FourBandEqDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<FourBandEqProcessor>();
}

DeviceNodeKind FourBandEqDeviceType::kind() const noexcept { return DeviceNodeKind::FourBandEq; }

uint16_t FourBandEqDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "ffxBand1Freq") return static_cast<uint16_t>(FourBandEqParam::Band1Freq);
    if (name == "ffxBand1Gain") return static_cast<uint16_t>(FourBandEqParam::Band1Gain);
    if (name == "ffxBand1Q") return static_cast<uint16_t>(FourBandEqParam::Band1Q);
    if (name == "ffxBand2Freq") return static_cast<uint16_t>(FourBandEqParam::Band2Freq);
    if (name == "ffxBand2Gain") return static_cast<uint16_t>(FourBandEqParam::Band2Gain);
    if (name == "ffxBand2Q") return static_cast<uint16_t>(FourBandEqParam::Band2Q);
    if (name == "ffxBand3Freq") return static_cast<uint16_t>(FourBandEqParam::Band3Freq);
    if (name == "ffxBand3Gain") return static_cast<uint16_t>(FourBandEqParam::Band3Gain);
    if (name == "ffxBand3Q") return static_cast<uint16_t>(FourBandEqParam::Band3Q);
    if (name == "ffxBand4Freq") return static_cast<uint16_t>(FourBandEqParam::Band4Freq);
    if (name == "ffxBand4Gain") return static_cast<uint16_t>(FourBandEqParam::Band4Gain);
    if (name == "ffxBand4Q") return static_cast<uint16_t>(FourBandEqParam::Band4Q);
    return static_cast<uint16_t>(-1);
}

std::string_view FourBandEqDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<FourBandEqParam>(localId)) {
    case FourBandEqParam::Band1Freq: return "ffxBand1Freq";
    case FourBandEqParam::Band1Gain: return "ffxBand1Gain";
    case FourBandEqParam::Band1Q: return "ffxBand1Q";
    case FourBandEqParam::Band2Freq: return "ffxBand2Freq";
    case FourBandEqParam::Band2Gain: return "ffxBand2Gain";
    case FourBandEqParam::Band2Q: return "ffxBand2Q";
    case FourBandEqParam::Band3Freq: return "ffxBand3Freq";
    case FourBandEqParam::Band3Gain: return "ffxBand3Gain";
    case FourBandEqParam::Band3Q: return "ffxBand3Q";
    case FourBandEqParam::Band4Freq: return "ffxBand4Freq";
    case FourBandEqParam::Band4Gain: return "ffxBand4Gain";
    case FourBandEqParam::Band4Q: return "ffxBand4Q";
    default: return "";
    }
}

std::span<const ParamDescriptor> FourBandEqDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(FourBandEqParam::Band1Freq), "ffxBand1Freq", "Low Freq", 0.4f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(FourBandEqParam::Band1Gain), "ffxBand1Gain", "Low Gain", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(FourBandEqParam::Band1Q), "ffxBand1Q", "Low Q", 0.3f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(FourBandEqParam::Band2Freq), "ffxBand2Freq", "LM Freq", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(FourBandEqParam::Band2Gain), "ffxBand2Gain", "LM Gain", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(FourBandEqParam::Band2Q), "ffxBand2Q", "LM Q", 0.3f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(FourBandEqParam::Band3Freq), "ffxBand3Freq", "HM Freq", 0.7f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(FourBandEqParam::Band3Gain), "ffxBand3Gain", "HM Gain", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(FourBandEqParam::Band3Q), "ffxBand3Q", "HM Q", 0.3f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(FourBandEqParam::Band4Freq), "ffxBand4Freq", "High Freq", 0.8f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(FourBandEqParam::Band4Gain), "ffxBand4Gain", "High Gain", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(FourBandEqParam::Band4Q), "ffxBand4Q", "High Q", 0.3f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

} // namespace audioapp