#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/effects/ChorusDeviceType.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceParameterResult.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/effects/ChorusParams.hpp"
#include "juce_dsp/juce_dsp.h"
#include "audioapp/devices/processors/ChorusProcessor.hpp"

namespace audioapp {

namespace {
constexpr const char* kParamNames[] = {
    "modeMorph",
    "classicRate", "classicDepth", "classicDelay", "classicFeedback", "classicPhase", "classicShape",
    "ensembleRate", "ensembleDepth", "ensembleVoices", "ensembleSpread", "ensembleDrift", "ensembleTone",
    "dimensionAmount", "dimensionDelay", "dimensionSpread", "dimensionMotion", "dimensionLowCut", "dimensionHighCut",
    "driftSpeed", "driftDepth", "driftWander", "driftDelay", "driftStereo", "driftTone",
};

bool bankSlot(ChorusParam param, int& mode, int& slot) noexcept {
    const int raw = static_cast<int>(param) - 1;
    if (raw < 0 || raw >= ChorusParams::kModeCount * ChorusParams::kParamsPerMode) return false;
    mode = raw / ChorusParams::kParamsPerMode;
    slot = raw % ChorusParams::kParamsPerMode;
    return true;
}
}

DeviceSlot ChorusDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    ChorusParams instance;
    slot.config.instance = std::move(instance);
    slot.config.inputPanel = EmptyPanel{};
    StereoOutputPanel output;
    output.outputMix = 0.4f;
    slot.config.outputPanel = output;
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult ChorusDeviceType::setParameter(DeviceSlot& slot,
                                                     std::string_view parameterId,
                                                     float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }
    auto& instance = std::get<ChorusParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    if (id == static_cast<uint16_t>(-1))
        return result;
    const auto localId = static_cast<ChorusParam>(id);
    if (localId == ChorusParam::ModeMorph) {
        instance.modeMorph = juce::jlimit(0.0, 3.0, static_cast<double>(value));
    } else {
        int mode = 0, parameter = 0;
        if (!bankSlot(localId, mode, parameter)) return result;
        instance.bank(mode)[static_cast<size_t>(parameter)] =
            juce::jlimit(0.0, 1.0, static_cast<double>(value));
    }
    result.handled = true;
    return result;
}

bool ChorusDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&, const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> ChorusDeviceType::modulatableParams() const {
    std::vector<std::string_view> result{"gain", "pan"};
    for (const char* name : kParamNames) result.emplace_back(name);
    return result;
}

void ChorusDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = DeviceNodeKind::Chorus;
    const auto& inst = std::get<ChorusParams>(slot.config.instance);
    ChorusParamsPlayback p;
    p.modeMorph = static_cast<float>(inst.modeMorph);
    for (int mode = 0; mode < ChorusParams::kModeCount; ++mode)
        for (int parameter = 0; parameter < ChorusParams::kParamsPerMode; ++parameter)
            p.modeParams[mode][parameter] =
                static_cast<float>(inst.bank(mode)[static_cast<size_t>(parameter)]);
    p.inputGain = 1.0f;
    out.params = p;
}

bool ChorusDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&, LiveInstrumentSnapshot&) const { return false; }

juce::var ChorusDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<ChorusParams>(slot.config.instance);
    parameters->setProperty("modeMorph", inst.modeMorph);
    parameters->setProperty("classic", ChorusParams::bankToVar(inst.classic));
    parameters->setProperty("ensemble", ChorusParams::bankToVar(inst.ensemble));
    parameters->setProperty("dimension", ChorusParams::bankToVar(inst.dimension));
    parameters->setProperty("drift", ChorusParams::bankToVar(inst.drift));

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
    inObj->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(inObj));

    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("parameters", juce::var(parameters));

    auto* meters = new juce::DynamicObject();
    meters->setProperty("gainReductionDb", 0.0);
    meters->setProperty("inputLevel", 0.0);
    object->setProperty("meters", juce::var(meters));

    return juce::var(object);
}

DeviceSlot ChorusDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.typeId = object->getProperty("type").toString().toStdString();

        const auto outputPanelVar = object->getProperty("outputPanel");
        bool hasPanel = outputPanelVar.isObject();
        if (hasPanel) {
            const auto* panel = outputPanelVar.getDynamicObject();
            auto readPanel = [&](const char* key, float fallback) -> float {
                const auto v = panel->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            StereoOutputPanel sp;
            sp.gain = readPanel("gain", 1.0f);
            sp.pan = readPanel("pan", 0.5f);
            sp.outputMix = readPanel("outputMix", 1.0f);
            sp.outputWidth = readPanel("outputWidth", 1.0f);
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
                StereoOutputPanel sp;
                sp.gain = oldGain;
                sp.pan = oldPan;
                sp.outputMix = readFloat("outputMix", 1.0f);
                sp.outputWidth = readFloat("outputWidth", 1.0f);
                slot.config.outputPanel = sp;
                slot.config.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            }

            const bool legacy = !p->hasProperty("classic");
            slot.config.instance = ChorusParams::fromJson(params);
            if (legacy && std::holds_alternative<StereoOutputPanel>(slot.config.outputPanel))
                std::get<StereoOutputPanel>(slot.config.outputPanel).outputMix *= 0.4f;
            
        }
    }
    return slot;
}

DeviceProcessor* ChorusDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<ChorusProcessor>();
}

DeviceNodeKind ChorusDeviceType::kind() const noexcept { return DeviceNodeKind::Chorus; }

uint16_t ChorusDeviceType::paramIdFromString(std::string_view name) const noexcept {
    for (uint16_t i = 0; i < static_cast<uint16_t>(std::size(kParamNames)); ++i)
        if (name == kParamNames[i]) return i;
    // Legacy names edit the Classic anchor.
    if (name == "rateHz" || name == "chorusRateHz") return static_cast<uint16_t>(ChorusParam::ClassicRate);
    if (name == "depth" || name == "chorusDepth") return static_cast<uint16_t>(ChorusParam::ClassicDepth);
    if (name == "centreDelayMs" || name == "chorusCentreDelayMs") return static_cast<uint16_t>(ChorusParam::ClassicDelay);
    if (name == "feedback" || name == "chorusFeedback") return static_cast<uint16_t>(ChorusParam::ClassicFeedback);
    return static_cast<uint16_t>(-1);
}

std::string_view ChorusDeviceType::paramIdToString(uint16_t localId) const noexcept {
    return localId < std::size(kParamNames) ? kParamNames[localId] : "";
}

std::span<const ParamDescriptor> ChorusDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {0, "modeMorph", "Mode Morph", 0.0f, 0.0f, 3.0f, true, true},
        {1, "classicRate", "Classic Rate", .286f, 0, 1, true, true}, {2, "classicDepth", "Classic Depth", .25f, 0, 1, true, true},
        {3, "classicDelay", "Classic Delay", .30f, 0, 1, true, true}, {4, "classicFeedback", "Classic Feedback", 0, 0, 1, true, true},
        {5, "classicPhase", "Classic Phase", .5f, 0, 1, true, true}, {6, "classicShape", "Classic Shape", 0, 0, 1, true, true},
        {7, "ensembleRate", "Ensemble Rate", .25f, 0, 1, true, true}, {8, "ensembleDepth", "Ensemble Depth", .5f, 0, 1, true, true},
        {9, "ensembleVoices", "Ensemble Voices", .5f, 0, 1, true, true}, {10, "ensembleSpread", "Ensemble Spread", .65f, 0, 1, true, true},
        {11, "ensembleDrift", "Ensemble Drift", .25f, 0, 1, true, true}, {12, "ensembleTone", "Ensemble Tone", .65f, 0, 1, true, true},
        {13, "dimensionAmount", "Dimension Amount", .5f, 0, 1, true, true}, {14, "dimensionDelay", "Dimension Delay", .35f, 0, 1, true, true},
        {15, "dimensionSpread", "Dimension Spread", .8f, 0, 1, true, true}, {16, "dimensionMotion", "Dimension Motion", .25f, 0, 1, true, true},
        {17, "dimensionLowCut", "Dimension Low Cut", 0, 0, 1, true, true}, {18, "dimensionHighCut", "Dimension High Cut", .9f, 0, 1, true, true},
        {19, "driftSpeed", "Drift Speed", .3f, 0, 1, true, true}, {20, "driftDepth", "Drift Depth", .5f, 0, 1, true, true},
        {21, "driftWander", "Drift Wander", .4f, 0, 1, true, true}, {22, "driftDelay", "Drift Delay", .4f, 0, 1, true, true},
        {23, "driftStereo", "Drift Stereo", .7f, 0, 1, true, true}, {24, "driftTone", "Drift Tone", .6f, 0, 1, true, true},
    };
    return kParams;
}

bool ChorusDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
