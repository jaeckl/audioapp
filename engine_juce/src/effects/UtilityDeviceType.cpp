#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/UtilityDeviceType.hpp"
#include "audioapp/effects/UtilityParams.hpp"
#include "audioapp/devices/processors/UtilityProcessor.hpp"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"

#include <algorithm>

namespace audioapp {

namespace {

void migrateLegacyPolarity(UtilityModel& inst, float pol) {
    // Legacy: 0=off, ~0.33=L, ~0.66=R, 1=both
    if (pol >= 0.83f) {
        inst.utilInvertL = 1.0f;
        inst.utilInvertR = 1.0f;
    } else if (pol >= 0.5f) {
        inst.utilInvertL = 0.0f;
        inst.utilInvertR = 1.0f;
    } else if (pol >= 0.16f) {
        inst.utilInvertL = 1.0f;
        inst.utilInvertR = 0.0f;
    } else {
        inst.utilInvertL = 0.0f;
        inst.utilInvertR = 0.0f;
    }
}

} // namespace

DeviceSlot UtilityDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = UtilityModel{};
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = EmptyPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult UtilityDeviceType::setParameter(DeviceSlot& slot,
                                                      std::string_view parameterId,
                                                      float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<UtilityModel>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1)) {
        return result;
    }
    switch (static_cast<UtilityParam>(id)) {
    case UtilityParam::Width: instance.utilWidth = clamped; break;
    case UtilityParam::InvertL: instance.utilInvertL = clamped >= 0.5f ? 1.0f : 0.0f; break;
    case UtilityParam::InvertR: instance.utilInvertR = clamped >= 0.5f ? 1.0f : 0.0f; break;
    case UtilityParam::Swap: instance.utilSwap = clamped >= 0.5f ? 1.0f : 0.0f; break;
    case UtilityParam::Trim: instance.utilTrim = clamped; break;
    case UtilityParam::Autopan: instance.utilAutopan = clamped >= 0.5f ? 1.0f : 0.0f; break;
    case UtilityParam::AutopanRate: instance.utilAutopanRate = clamped; break;
    case UtilityParam::AutopanDepth: instance.utilAutopanDepth = clamped; break;
    default: return result;
    }
    result.handled = true;
    return result;
}

bool UtilityDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&,
                                           const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> UtilityDeviceType::modulatableParams() const {
    return {"utilWidth", "utilInvertL", "utilInvertR", "utilSwap", "utilTrim", "utilAutopan",
            "utilAutopanRate", "utilAutopanDepth"};
}

void UtilityDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&,
                                          DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Utility;
    out.params = std::get<UtilityModel>(slot.config.instance).toPlaybackParams();
}

bool UtilityDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&,
                                            LiveInstrumentSnapshot&) const {
    return false;
}

juce::var UtilityDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<UtilityModel>(slot.config.instance);
    parameters->setProperty("utilWidth", static_cast<double>(inst.utilWidth));
    parameters->setProperty("utilInvertL", static_cast<double>(inst.utilInvertL));
    parameters->setProperty("utilInvertR", static_cast<double>(inst.utilInvertR));
    parameters->setProperty("utilSwap", static_cast<double>(inst.utilSwap));
    parameters->setProperty("utilTrim", static_cast<double>(inst.utilTrim));
    parameters->setProperty("utilAutopan", static_cast<double>(inst.utilAutopan));
    parameters->setProperty("utilAutopanRate", static_cast<double>(inst.utilAutopanRate));
    parameters->setProperty("utilAutopanDepth", static_cast<double>(inst.utilAutopanDepth));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));

    auto* emptyOut = new juce::DynamicObject();
    emptyOut->setProperty("type", "empty");
    object->setProperty("outputPanel", juce::var(emptyOut));
    auto* emptyIn = new juce::DynamicObject();
    emptyIn->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(emptyIn));

    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot UtilityDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot = createDefault({});
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.typeId = typeId();
        slot.config.bypassed = object->getProperty("bypass").isDouble()
            ? (static_cast<float>(static_cast<double>(object->getProperty("bypass"))) >= 0.5f)
            : false;
        if (const auto* p = object->getProperty("parameters").getDynamicObject()) {
            UtilityModel inst;
            auto read = [&](const char* key, float fallback) {
                const auto v = p->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            if (p->hasProperty("utilWidth")) {
                inst.utilWidth = read("utilWidth", 1.0f);
            } else if (p->hasProperty("utilMono")) {
                inst.utilWidth = read("utilMono", 0.0f) >= 0.5f ? 0.0f : 1.0f;
            } else {
                inst.utilWidth = 1.0f;
            }
            if (p->hasProperty("utilInvertL") || p->hasProperty("utilInvertR")) {
                inst.utilInvertL = read("utilInvertL", 0.0f) >= 0.5f ? 1.0f : 0.0f;
                inst.utilInvertR = read("utilInvertR", 0.0f) >= 0.5f ? 1.0f : 0.0f;
            } else if (p->hasProperty("utilPolarity")) {
                migrateLegacyPolarity(inst, read("utilPolarity", 0.0f));
            }
            inst.utilSwap = read("utilSwap", 0.0f) >= 0.5f ? 1.0f : 0.0f;
            inst.utilTrim = read("utilTrim", 1.0f);
            inst.utilAutopan = read("utilAutopan", 0.0f) >= 0.5f ? 1.0f : 0.0f;
            inst.utilAutopanRate = read("utilAutopanRate", 0.35f);
            inst.utilAutopanDepth = read("utilAutopanDepth", 0.5f);
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* UtilityDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<UtilityProcessor>();
}

DeviceNodeKind UtilityDeviceType::kind() const noexcept { return DeviceNodeKind::Utility; }

uint16_t UtilityDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "utilWidth" || name == "utilMono")
        return static_cast<uint16_t>(UtilityParam::Width);
    if (name == "utilInvertL") return static_cast<uint16_t>(UtilityParam::InvertL);
    if (name == "utilInvertR") return static_cast<uint16_t>(UtilityParam::InvertR);
    if (name == "utilSwap") return static_cast<uint16_t>(UtilityParam::Swap);
    if (name == "utilTrim") return static_cast<uint16_t>(UtilityParam::Trim);
    if (name == "utilAutopan") return static_cast<uint16_t>(UtilityParam::Autopan);
    if (name == "utilAutopanRate") return static_cast<uint16_t>(UtilityParam::AutopanRate);
    if (name == "utilAutopanDepth") return static_cast<uint16_t>(UtilityParam::AutopanDepth);
    return static_cast<uint16_t>(-1);
}

std::string_view UtilityDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<UtilityParam>(localId)) {
    case UtilityParam::Width: return "utilWidth";
    case UtilityParam::InvertL: return "utilInvertL";
    case UtilityParam::InvertR: return "utilInvertR";
    case UtilityParam::Swap: return "utilSwap";
    case UtilityParam::Trim: return "utilTrim";
    case UtilityParam::Autopan: return "utilAutopan";
    case UtilityParam::AutopanRate: return "utilAutopanRate";
    case UtilityParam::AutopanDepth: return "utilAutopanDepth";
    default: return "";
    }
}

std::span<const ParamDescriptor> UtilityDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(UtilityParam::Width), "utilWidth", "Width", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(UtilityParam::InvertL), "utilInvertL", "L-", 0.0f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(UtilityParam::InvertR), "utilInvertR", "R-", 0.0f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(UtilityParam::Swap), "utilSwap", "Swap", 0.0f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(UtilityParam::Trim), "utilTrim", "Trim", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(UtilityParam::Autopan), "utilAutopan", "Autopan", 0.0f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(UtilityParam::AutopanRate), "utilAutopanRate", "Rate", 0.35f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(UtilityParam::AutopanDepth), "utilAutopanDepth", "Depth", 0.5f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool UtilityDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
