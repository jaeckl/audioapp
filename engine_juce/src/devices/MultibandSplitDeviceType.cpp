#include "audioapp/devices/MultibandSplitDeviceType.hpp"

#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/MultibandSplitModel.hpp"
#include "audioapp/devices/processors/MultibandSplitProcessor.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <memory>
#include <utility>

namespace audioapp {
namespace {

constexpr float kMinCrossoverHz = 40.0f;
constexpr float kMaxCrossoverHz = 18000.0f;
constexpr float kCrossoverGap = 1.25f;

bool isForbiddenNestedType(std::string_view typeId) noexcept {
    return device_types::isSplitType(typeId) || device_types::isMultibandSplitType(typeId) ||
           typeId == device_types::kChain;
}

void appendBand(const std::vector<std::shared_ptr<DeviceSlot>>& band,
                const PlaybackBuildContext& context, SplitBranchPlayback& out) {
    if (context.deviceRegistry == nullptr) return;
    for (const auto& child : band) {
        if (!child || isForbiddenNestedType(child->config.typeId) || out.deviceCount >= 8)
            continue;
        auto& node = out.devices[out.deviceCount++];
        node.deviceId = child->id;
        node.bypassed = child->config.bypassed;
        context.deviceRegistry->buildPlaybackNode(*child, context, node);
    }
}

void writeOutputPanel(juce::DynamicObject* object, const StereoOutputPanel& panel) {
    auto* outObj = new juce::DynamicObject();
    outObj->setProperty("type", "stereo");
    outObj->setProperty("gain", static_cast<double>(panel.gain));
    outObj->setProperty("pan", static_cast<double>(panel.pan));
    outObj->setProperty("outputMix", static_cast<double>(panel.outputMix));
    outObj->setProperty("outputWidth", static_cast<double>(panel.outputWidth));
    object->setProperty("outputPanel", juce::var(outObj));
}

float clampCrossover(const MultibandSplitModel& model, int index, float value) noexcept {
    const int xoCount = model.bandCount - 1;
    float lo = kMinCrossoverHz;
    float hi = kMaxCrossoverHz;
    if (index > 0) lo = std::max(lo, model.crossoverHz[index - 1] * kCrossoverGap);
    if (index + 1 < xoCount) hi = std::min(hi, model.crossoverHz[index + 1] / kCrossoverGap);
    if (lo > hi) return model.crossoverHz[index];
    return std::clamp(value, lo, hi);
}

} // namespace

MultibandSplitDeviceType::MultibandSplitDeviceType(int bandCount) noexcept
    : bandCount_(std::clamp(bandCount, 2, kMaxMbBands)) {}

std::string MultibandSplitDeviceType::typeId() const {
    if (bandCount_ == 3) return device_types::kMbSplit3;
    if (bandCount_ == 4) return device_types::kMbSplit4;
    return device_types::kMbSplit2;
}

DeviceSlot MultibandSplitDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = MultibandSplitModel::withDefaults(bandCount_);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    return slot;
}

DeviceParameterResult MultibandSplitDeviceType::setParameter(DeviceSlot& slot,
                                                             std::string_view id,
                                                             float value) const {
    if (device_strip::setStripParameter(slot, id, value)) return {.handled = true};

    auto& model = std::get<MultibandSplitModel>(slot.config.instance);
    if (id.size() == 9 && id.starts_with("band") && id.ends_with("Gain")) {
        const int band = id[4] - '0';
        if (band >= 0 && band < kMaxMbBands) {
            model.bandGain[band] = std::clamp(value, 0.0f, 2.0f);
            return {.handled = true};
        }
    }
    if (id.size() == 10 && id.starts_with("crossover")) {
        const int index = id[9] - '0';
        if (index >= 0 && index < model.bandCount - 1) {
            model.crossoverHz[index] = clampCrossover(model, index, value);
            return {.handled = true};
        }
    }
    return {};
}

bool MultibandSplitDeviceType::setStringParameter(DeviceSlot&, std::string_view,
                                                  const std::string&,
                                                  const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> MultibandSplitDeviceType::modulatableParams() const {
    return {"band0Gain", "band1Gain", "band2Gain", "band3Gain",
            "crossover0", "crossover1", "crossover2"};
}

void MultibandSplitDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                 const PlaybackBuildContext& context,
                                                 DeviceNodePlayback& out) const {
    const auto& model = std::get<MultibandSplitModel>(slot.config.instance);
    auto playback = std::make_shared<MultibandSplitPlayback>();
    playback->bandCount = model.bandCount;
    std::memcpy(playback->crossoverHz, model.crossoverHz, sizeof(playback->crossoverHz));
    std::memcpy(playback->bandGain, model.bandGain, sizeof(playback->bandGain));
    for (int b = 0; b < model.bandCount && b < kMaxMbBands; ++b)
        appendBand(model.bands[b], context, playback->bands[b]);
    out.kind = DeviceNodeKind::MultibandSplit;
    out.params = MultibandSplitParams{playback};
}

bool MultibandSplitDeviceType::buildLiveInstrument(const DeviceSlot&,
                                                   const PlaybackBuildContext&,
                                                   LiveInstrumentSnapshot&) const {
    return false;
}

juce::var MultibandSplitDeviceType::slotToVar(const DeviceSlot& slot) const {
    const auto& model = std::get<MultibandSplitModel>(slot.config.instance);
    auto* params = new juce::DynamicObject();
    for (int b = 0; b < kMaxMbBands; ++b) {
        const auto key = "band" + juce::String(b) + "Gain";
        params->setProperty(key, static_cast<double>(model.bandGain[b]));
    }
    for (int i = 0; i < 3; ++i) {
        const auto key = "crossover" + juce::String(i);
        params->setProperty(key, static_cast<double>(model.crossoverHz[i]));
    }
    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String(slot.id));
    object->setProperty("type", juce::String(typeId()));
    object->setProperty("bypass", slot.config.bypassed);
    object->setProperty("parameters", juce::var(params));
    writeOutputPanel(object, std::get<StereoOutputPanel>(slot.config.outputPanel));
    auto* inObj = new juce::DynamicObject();
    inObj->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(inObj));
    return juce::var(object);
}

DeviceSlot MultibandSplitDeviceType::varToSlot(const juce::var& value) const {
    DeviceSlot slot = createDefault("");
    if (const auto* object = value.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.bypassed = static_cast<bool>(object->getProperty("bypass"));
        if (const auto* params = object->getProperty("parameters").getDynamicObject()) {
            auto& model = std::get<MultibandSplitModel>(slot.config.instance);
            for (int b = 0; b < kMaxMbBands; ++b) {
                const auto key = "band" + juce::String(b) + "Gain";
                if (params->hasProperty(key))
                    model.bandGain[b] = std::clamp(
                        static_cast<float>(static_cast<double>(params->getProperty(key))),
                        0.0f, 2.0f);
            }
            for (int i = 0; i < model.bandCount - 1; ++i) {
                const auto key = "crossover" + juce::String(i);
                if (params->hasProperty(key))
                    model.crossoverHz[i] = clampCrossover(
                        model, i,
                        static_cast<float>(static_cast<double>(params->getProperty(key))));
            }
        }
        if (const auto* panel = object->getProperty("outputPanel").getDynamicObject()) {
            StereoOutputPanel sp;
            sp.gain = static_cast<float>(static_cast<double>(panel->getProperty("gain")));
            sp.pan = static_cast<float>(static_cast<double>(panel->getProperty("pan")));
            if (panel->hasProperty("outputMix"))
                sp.outputMix =
                    static_cast<float>(static_cast<double>(panel->getProperty("outputMix")));
            if (panel->hasProperty("outputWidth"))
                sp.outputWidth =
                    static_cast<float>(static_cast<double>(panel->getProperty("outputWidth")));
            slot.config.outputPanel = sp;
        }
    }
    return slot;
}

DeviceProcessor* MultibandSplitDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.emplace<MultibandSplitProcessor>();
}

DeviceNodeKind MultibandSplitDeviceType::kind() const noexcept {
    return DeviceNodeKind::MultibandSplit;
}

uint16_t MultibandSplitDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "band0Gain") return 0;
    if (name == "band1Gain") return 1;
    if (name == "band2Gain") return 2;
    if (name == "band3Gain") return 3;
    if (name == "crossover0") return 4;
    if (name == "crossover1") return 5;
    if (name == "crossover2") return 6;
    return static_cast<uint16_t>(-1);
}

std::string_view MultibandSplitDeviceType::paramIdToString(uint16_t id) const noexcept {
    switch (id) {
        case 0: return "band0Gain";
        case 1: return "band1Gain";
        case 2: return "band2Gain";
        case 3: return "band3Gain";
        case 4: return "crossover0";
        case 5: return "crossover1";
        case 6: return "crossover2";
        default: return "";
    }
}

std::span<const ParamDescriptor> MultibandSplitDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor params[] = {
        {0, "band0Gain", "Band 1 Gain", 1, 0, 2, true, true},
        {1, "band1Gain", "Band 2 Gain", 1, 0, 2, true, true},
        {2, "band2Gain", "Band 3 Gain", 1, 0, 2, true, true},
        {3, "band3Gain", "Band 4 Gain", 1, 0, 2, true, true},
        {4, "crossover0", "Crossover 1", 1000, 40, 18000, true, true},
        {5, "crossover1", "Crossover 2", 2000, 40, 18000, true, true},
        {6, "crossover2", "Crossover 3", 500, 40, 18000, true, true},
    };
    return params;
}

} // namespace audioapp
