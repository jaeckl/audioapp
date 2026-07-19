#include "audioapp/devices/SpectralLoudSplitDeviceType.hpp"

#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/SpectralLoudSplitModel.hpp"
#include "audioapp/devices/processors/SpectralLoudSplitProcessor.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <memory>
#include <utility>

namespace audioapp {
namespace {

constexpr float kMinDb = -80.0f;
constexpr float kMaxDb = 0.0f;
constexpr float kMinGapDb = 6.0f;

void appendBranch(const std::vector<std::shared_ptr<DeviceSlot>>& devices,
                  const PlaybackBuildContext& context, SplitBranchPlayback& out) {
    if (context.deviceRegistry == nullptr) return;
    for (const auto& child : devices) {
        if (!child || out.deviceCount >= 8) continue;
        auto& node = out.devices[out.deviceCount++];
        node.deviceId = child->id;
        node.bypassed = child->config.bypassed;
        context.deviceRegistry->buildPlaybackNode(*child, context, node);
    }
}

float clampHighDb(const SpectralLoudSplitModel& model, float value) noexcept {
    return std::clamp(value, model.lowDb + kMinGapDb, kMaxDb);
}

float clampLowDb(const SpectralLoudSplitModel& model, float value) noexcept {
    return std::clamp(value, kMinDb, model.highDb - kMinGapDb);
}

} // namespace

std::string SpectralLoudSplitDeviceType::typeId() const {
    return device_types::kSpectralLoudSplit;
}

DeviceSlot SpectralLoudSplitDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    slot.config.instance = SpectralLoudSplitModel::withDefaults();
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = PrePostMixOutputPanel{};
    return slot;
}

DeviceParameterResult SpectralLoudSplitDeviceType::setParameter(DeviceSlot& slot,
                                                                std::string_view id,
                                                                float value) const {
    if (device_strip::setStripParameter(slot, id, value)) return {.handled = true};

    auto& model = std::get<SpectralLoudSplitModel>(slot.config.instance);
    if (id == "highDb") {
        model.highDb = clampHighDb(model, value);
        return {.handled = true};
    }
    if (id == "lowDb") {
        model.lowDb = clampLowDb(model, value);
        return {.handled = true};
    }
    if (id.size() == 9 && id.starts_with("band") && id.ends_with("Gain")) {
        const int band = id[4] - '0';
        if (band >= 0 && band < kSpectralLoudBands) {
            model.bandGain[band] = std::clamp(value, 0.0f, 2.0f);
            return {.handled = true};
        }
    }
    if (id.size() == 9 && id.starts_with("band") && id.ends_with("Solo")) {
        const int band = id[4] - '0';
        if (band >= 0 && band < kSpectralLoudBands) {
            const bool enable = value >= 0.5f;
            if (enable) {
                for (int i = 0; i < kSpectralLoudBands; ++i)
                    model.bandSolo[i] = (i == band) ? 1.0f : 0.0f;
            } else {
                model.bandSolo[band] = 0.0f;
            }
            return {.handled = true};
        }
    }
    return {};
}

bool SpectralLoudSplitDeviceType::setStringParameter(DeviceSlot&, std::string_view,
                                                     const std::string&,
                                                     const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> SpectralLoudSplitDeviceType::modulatableParams() const {
    return {"highDb", "lowDb", "band0Gain", "band1Gain", "band2Gain"};
}

void SpectralLoudSplitDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                    const PlaybackBuildContext& context,
                                                    DeviceNodePlayback& out) const {
    const auto& model = std::get<SpectralLoudSplitModel>(slot.config.instance);
    auto playback = std::make_shared<SpectralLoudSplitPlayback>();
    playback->highDb = model.highDb;
    playback->lowDb = model.lowDb;
    std::memcpy(playback->bandGain, model.bandGain, sizeof(playback->bandGain));
    std::memcpy(playback->bandSolo, model.bandSolo, sizeof(playback->bandSolo));
    appendBranch(model.preFxDevices, context, playback->preFx);
    appendBranch(model.postFxDevices, context, playback->postFx);
    for (int b = 0; b < kSpectralLoudBands; ++b)
        appendBranch(model.bands[b], context, playback->bands[b]);
    out.kind = DeviceNodeKind::SpectralLoudSplit;
    out.params = SpectralLoudSplitParams{playback};
}

bool SpectralLoudSplitDeviceType::buildLiveInstrument(const DeviceSlot&,
                                                      const PlaybackBuildContext&,
                                                      LiveInstrumentSnapshot&) const {
    return false;
}

juce::var SpectralLoudSplitDeviceType::slotToVar(const DeviceSlot& slot) const {
    const auto& model = std::get<SpectralLoudSplitModel>(slot.config.instance);
    auto* params = new juce::DynamicObject();
    params->setProperty("highDb", static_cast<double>(model.highDb));
    params->setProperty("lowDb", static_cast<double>(model.lowDb));
    for (int b = 0; b < kSpectralLoudBands; ++b) {
        params->setProperty("band" + juce::String(b) + "Gain",
                            static_cast<double>(model.bandGain[b]));
        params->setProperty("band" + juce::String(b) + "Solo",
                            static_cast<double>(model.bandSolo[b]));
    }
    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String(slot.id));
    object->setProperty("type", juce::String(typeId()));
    object->setProperty("bypass", slot.config.bypassed);
    object->setProperty("parameters", juce::var(params));
    const auto& panel = std::get<PrePostMixOutputPanel>(slot.config.outputPanel);
    auto* outObj = new juce::DynamicObject();
    outObj->setProperty("type", "pre_post_mix");
    outObj->setProperty("outputMix", static_cast<double>(panel.outputMix));
    object->setProperty("outputPanel", juce::var(outObj));
    auto* inObj = new juce::DynamicObject();
    inObj->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(inObj));
    return juce::var(object);
}

DeviceSlot SpectralLoudSplitDeviceType::varToSlot(const juce::var& value) const {
    DeviceSlot slot = createDefault("");
    if (const auto* object = value.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.bypassed = static_cast<bool>(object->getProperty("bypass"));
        if (const auto* params = object->getProperty("parameters").getDynamicObject()) {
            auto& model = std::get<SpectralLoudSplitModel>(slot.config.instance);
            if (params->hasProperty("highDb"))
                model.highDb = static_cast<float>(static_cast<double>(params->getProperty("highDb")));
            if (params->hasProperty("lowDb"))
                model.lowDb = static_cast<float>(static_cast<double>(params->getProperty("lowDb")));
            model.highDb = clampHighDb(model, model.highDb);
            model.lowDb = clampLowDb(model, model.lowDb);
            for (int b = 0; b < kSpectralLoudBands; ++b) {
                const auto gKey = "band" + juce::String(b) + "Gain";
                const auto sKey = "band" + juce::String(b) + "Solo";
                if (params->hasProperty(gKey))
                    model.bandGain[b] = std::clamp(
                        static_cast<float>(static_cast<double>(params->getProperty(gKey))),
                        0.0f, 2.0f);
                if (params->hasProperty(sKey))
                    model.bandSolo[b] =
                        static_cast<float>(static_cast<double>(params->getProperty(sKey))) >= 0.5f
                            ? 1.0f
                            : 0.0f;
            }
        }
        if (const auto* panel = object->getProperty("outputPanel").getDynamicObject()) {
            PrePostMixOutputPanel p;
            if (panel->hasProperty("outputMix"))
                p.outputMix =
                    static_cast<float>(static_cast<double>(panel->getProperty("outputMix")));
            slot.config.outputPanel = p;
        }
    }
    return slot;
}

DeviceProcessor* SpectralLoudSplitDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.emplace<SpectralLoudSplitProcessor>();
}

DeviceNodeKind SpectralLoudSplitDeviceType::kind() const noexcept {
    return DeviceNodeKind::SpectralLoudSplit;
}

uint16_t SpectralLoudSplitDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "highDb") return 0;
    if (name == "lowDb") return 1;
    if (name == "band0Gain") return 2;
    if (name == "band1Gain") return 3;
    if (name == "band2Gain") return 4;
    if (name == "band0Solo") return 5;
    if (name == "band1Solo") return 6;
    if (name == "band2Solo") return 7;
    return static_cast<uint16_t>(-1);
}

std::string_view SpectralLoudSplitDeviceType::paramIdToString(uint16_t id) const noexcept {
    switch (id) {
        case 0: return "highDb";
        case 1: return "lowDb";
        case 2: return "band0Gain";
        case 3: return "band1Gain";
        case 4: return "band2Gain";
        case 5: return "band0Solo";
        case 6: return "band1Solo";
        case 7: return "band2Solo";
        default: return "";
    }
}

std::span<const ParamDescriptor> SpectralLoudSplitDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor params[] = {
        {0, "highDb", "High Threshold", -18, -80, 0, true, true},
        {1, "lowDb", "Low Threshold", -40, -80, 0, true, true},
        {2, "band0Gain", "Loud Gain", 1, 0, 2, true, true},
        {3, "band1Gain", "Mid Gain", 1, 0, 2, true, true},
        {4, "band2Gain", "Quiet Gain", 1, 0, 2, true, true},
        {5, "band0Solo", "Loud Solo", 0, 0, 1, false, false},
        {6, "band1Solo", "Mid Solo", 0, 0, 1, false, false},
        {7, "band2Solo", "Quiet Solo", 0, 0, 1, false, false},
    };
    return params;
}

} // namespace audioapp
