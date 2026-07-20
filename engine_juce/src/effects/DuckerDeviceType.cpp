#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/DuckerDeviceType.hpp"
#include "audioapp/effects/DuckerParams.hpp"
#include "audioapp/devices/processors/DuckerProcessor.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/devices/DevicePanelTypes.hpp"
#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <memory>

namespace audioapp {

DeviceSlot DuckerDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = DuckerModel{};
    slot.config.inputPanel = DynamicsInputPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult DuckerDeviceType::setParameter(DeviceSlot& slot,
                                                     std::string_view parameterId,
                                                     float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<DuckerModel>(slot.config.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1)) {
        return result;
    }
    switch (static_cast<DuckerParam>(id)) {
    case DuckerParam::Threshold: instance.duckThreshold = clamped; break;
    case DuckerParam::Depth: instance.duckDepth = clamped; break;
    case DuckerParam::Attack: instance.duckAttack = clamped; break;
    case DuckerParam::Release: instance.duckRelease = clamped; break;
    case DuckerParam::SidechainGain: instance.sidechainGain = clamped; break;
    default: return result;
    }
    result.handled = true;
    return result;
}

bool DuckerDeviceType::setStringParameter(DeviceSlot& slot,
                                          std::string_view parameterId,
                                          const std::string& value,
                                          const PlaybackBuildContext&) const {
    if (parameterId != "sidechainSourceId") {
        return false;
    }
    std::get<DuckerModel>(slot.config.instance).sidechainSourceId = value;
    return true;
}

std::vector<std::string_view> DuckerDeviceType::modulatableParams() const {
    return {"gain", "pan", "duckThreshold", "duckDepth", "duckAttack", "duckRelease",
            "sidechainGain"};
}

void DuckerDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                         const PlaybackBuildContext& context,
                                         DeviceNodePlayback& out) const {
    auto params = std::get<DuckerModel>(slot.config.instance).toPlaybackParams();
    const auto& inPanel = std::get<DynamicsInputPanel>(slot.config.inputPanel);
    params.inputGain = inPanel.trim;
    if (context.deviceRegistry != nullptr && !slot.audioFxDevices.empty()) {
        auto fx = std::make_shared<ChainPlayback>();
        for (const auto& child : slot.audioFxDevices) {
            if (child == nullptr || fx->deviceCount >= 8) {
                continue;
            }
            auto& node = fx->devices[fx->deviceCount++];
            node.deviceId = child->id;
            node.bypassed = child->config.bypassed;
            context.deviceRegistry->buildPlaybackNode(*child, context, node);
        }
        if (fx->deviceCount > 0) {
            params.sidechainFx = std::move(fx);
        }
    }
    out.kind = DeviceNodeKind::Ducker;
    out.params = params;
}

bool DuckerDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&,
                                           LiveInstrumentSnapshot&) const {
    return false;
}

juce::var DuckerDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<DuckerModel>(slot.config.instance);
    parameters->setProperty("duckThreshold", static_cast<double>(inst.duckThreshold));
    parameters->setProperty("duckDepth", static_cast<double>(inst.duckDepth));
    parameters->setProperty("duckAttack", static_cast<double>(inst.duckAttack));
    parameters->setProperty("duckRelease", static_cast<double>(inst.duckRelease));
    parameters->setProperty("sidechainGain", static_cast<double>(inst.sidechainGain));
    parameters->setProperty("sidechainSourceId",
                            juce::String::fromUTF8(inst.sidechainSourceId.c_str()));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));

    auto* outObj = new juce::DynamicObject();
    const auto& panel = std::get<StereoOutputPanel>(slot.config.outputPanel);
    outObj->setProperty("type", "stereo");
    outObj->setProperty("gain", static_cast<double>(panel.gain));
    outObj->setProperty("pan", static_cast<double>(panel.pan));
    outObj->setProperty("outputMix", static_cast<double>(panel.outputMix));
    outObj->setProperty("outputWidth", static_cast<double>(panel.outputWidth));
    object->setProperty("outputPanel", juce::var(outObj));

    auto* inObj = new juce::DynamicObject();
    const auto& inPanel = std::get<DynamicsInputPanel>(slot.config.inputPanel);
    inObj->setProperty("type", "dynamics");
    inObj->setProperty("trim", static_cast<double>(inPanel.trim));
    object->setProperty("inputPanel", juce::var(inObj));

    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("parameters", juce::var(parameters));

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);
    object->setProperty("meters", juce::var(meters));
    return juce::var(object);
}

DeviceSlot DuckerDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot = createDefault({});
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.typeId = typeId();
        slot.config.bypassed = object->getProperty("bypass").isDouble()
            ? (static_cast<float>(static_cast<double>(object->getProperty("bypass"))) >= 0.5f)
            : false;

        if (const auto* panel = object->getProperty("outputPanel").getDynamicObject()) {
            StereoOutputPanel sp;
            sp.gain = static_cast<float>(static_cast<double>(panel->getProperty("gain")));
            sp.pan = static_cast<float>(static_cast<double>(panel->getProperty("pan")));
            if (panel->hasProperty("outputMix"))
                sp.outputMix = static_cast<float>(static_cast<double>(panel->getProperty("outputMix")));
            if (panel->hasProperty("outputWidth"))
                sp.outputWidth = static_cast<float>(static_cast<double>(panel->getProperty("outputWidth")));
            slot.config.outputPanel = sp;
        }
        if (const auto* inPanel = object->getProperty("inputPanel").getDynamicObject()) {
            DynamicsInputPanel ip;
            if (inPanel->hasProperty("trim"))
                ip.trim = static_cast<float>(static_cast<double>(inPanel->getProperty("trim")));
            slot.config.inputPanel = ip;
        }
        if (const auto* p = object->getProperty("parameters").getDynamicObject()) {
            DuckerModel inst;
            auto read = [&](const char* key, float fallback) {
                const auto v = p->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            inst.duckThreshold = read("duckThreshold", 0.45f);
            inst.duckDepth = read("duckDepth", 0.75f);
            inst.duckAttack = read("duckAttack", 0.15f);
            inst.duckRelease = read("duckRelease", 0.45f);
            inst.sidechainGain = read("sidechainGain", 1.0f);
            inst.sidechainSourceId = p->getProperty("sidechainSourceId").toString().toStdString();
            slot.config.instance = std::move(inst);
        }
    }
    return slot;
}

DeviceProcessor* DuckerDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<DuckerProcessor>();
}

DeviceNodeKind DuckerDeviceType::kind() const noexcept { return DeviceNodeKind::Ducker; }

uint16_t DuckerDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "duckThreshold") return static_cast<uint16_t>(DuckerParam::Threshold);
    if (name == "duckDepth") return static_cast<uint16_t>(DuckerParam::Depth);
    if (name == "duckAttack") return static_cast<uint16_t>(DuckerParam::Attack);
    if (name == "duckRelease") return static_cast<uint16_t>(DuckerParam::Release);
    if (name == "sidechainGain") return static_cast<uint16_t>(DuckerParam::SidechainGain);
    return static_cast<uint16_t>(-1);
}

std::string_view DuckerDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<DuckerParam>(localId)) {
    case DuckerParam::Threshold: return "duckThreshold";
    case DuckerParam::Depth: return "duckDepth";
    case DuckerParam::Attack: return "duckAttack";
    case DuckerParam::Release: return "duckRelease";
    case DuckerParam::SidechainGain: return "sidechainGain";
    default: return "";
    }
}

std::span<const ParamDescriptor> DuckerDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(DuckerParam::Threshold), "duckThreshold", "Thresh", 0.45f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DuckerParam::Depth), "duckDepth", "Depth", 0.75f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DuckerParam::Attack), "duckAttack", "Attack", 0.15f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DuckerParam::Release), "duckRelease", "Release", 0.45f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(DuckerParam::SidechainGain), "sidechainGain", "SC Gain", 1.0f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool DuckerDeviceType::usesDspAutomationSubBlocks() const noexcept { return true; }

} // namespace audioapp
