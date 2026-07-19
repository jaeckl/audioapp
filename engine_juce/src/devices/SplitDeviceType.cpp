#include "audioapp/devices/SplitDeviceType.hpp"

#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/processors/SplitProcessor.hpp"

#include <algorithm>
#include <memory>
#include <utility>

namespace audioapp {

namespace {

void appendBranch(const std::vector<std::shared_ptr<DeviceSlot>>& branch,
                   const PlaybackBuildContext& context,
                   SplitBranchPlayback& out) {
    if (context.deviceRegistry == nullptr) return;
    for (const auto& child : branch) {
        if (!child || device_types::isSplitType(child->config.typeId) ||
            device_types::isMultibandSplitType(child->config.typeId) ||
            device_types::isSpectralLoudSplitType(child->config.typeId) ||
            child->config.typeId == device_types::kChain ||
            out.deviceCount >= 8) {
            continue;
        }
        auto& node = out.devices[out.deviceCount++];
        node.deviceId = child->id;
        node.bypassed = child->config.bypassed;
        context.deviceRegistry->buildPlaybackNode(*child, context, node);
    }
}

} // namespace

SplitDeviceType::SplitDeviceType(SplitMode mode) noexcept : mode_(mode) {}

std::string SplitDeviceType::typeId() const {
    return mode_ == SplitMode::Lr ? device_types::kLrSplit : device_types::kMsSplit;
}

DeviceSlot SplitDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    SplitModel model;
    model.mode = mode_;
    slot.config.instance = std::move(model);
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = EmptyPanel{};
    return slot;
}

DeviceParameterResult SplitDeviceType::setParameter(DeviceSlot& slot, std::string_view id,
                                                    float value) const {
    auto& model = std::get<SplitModel>(slot.config.instance);
    if (id == "branch0Gain") {
        model.branch0Gain = std::clamp(value, 0.0f, 2.0f);
        return {.handled = true};
    }
    if (id == "branch1Gain") {
        model.branch1Gain = std::clamp(value, 0.0f, 2.0f);
        return {.handled = true};
    }
    // Exclusive solo: enabling one clears the other. Neither solo → both paths out.
    if (id == "branch0Solo") {
        model.branch0Solo = value >= 0.5f;
        if (model.branch0Solo) model.branch1Solo = false;
        return {.handled = true};
    }
    if (id == "branch1Solo") {
        model.branch1Solo = value >= 0.5f;
        if (model.branch1Solo) model.branch0Solo = false;
        return {.handled = true};
    }
    return {};
}

bool SplitDeviceType::setStringParameter(DeviceSlot&, std::string_view, const std::string&,
                                         const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> SplitDeviceType::modulatableParams() const {
    return {"branch0Gain", "branch1Gain"};
}

void SplitDeviceType::buildPlaybackNode(const DeviceSlot& slot, const PlaybackBuildContext& context,
                                        DeviceNodePlayback& out) const {
    const auto& model = std::get<SplitModel>(slot.config.instance);
    auto playback = std::make_shared<SplitPlayback>();
    playback->mode = model.mode;
    playback->branch0Gain = model.branch0Gain;
    playback->branch1Gain = model.branch1Gain;
    playback->branch0Solo = model.branch0Solo;
    playback->branch1Solo = model.branch1Solo;
    appendBranch(model.branch0, context, playback->branches[0]);
    appendBranch(model.branch1, context, playback->branches[1]);
    out.kind = DeviceNodeKind::Split;
    out.params = SplitParams{playback};
}

bool SplitDeviceType::buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&,
                                          LiveInstrumentSnapshot&) const {
    return false;
}

juce::var SplitDeviceType::slotToVar(const DeviceSlot& slot) const {
    const auto& model = std::get<SplitModel>(slot.config.instance);
    auto* params = new juce::DynamicObject();
    params->setProperty("branch0Gain", static_cast<double>(model.branch0Gain));
    params->setProperty("branch1Gain", static_cast<double>(model.branch1Gain));
    params->setProperty("branch0Solo", model.branch0Solo);
    params->setProperty("branch1Solo", model.branch1Solo);
    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String(slot.id));
    object->setProperty("type", juce::String(typeId()));
    object->setProperty("bypass", slot.config.bypassed);
    object->setProperty("parameters", juce::var(params));
    return juce::var(object);
}

DeviceSlot SplitDeviceType::varToSlot(const juce::var& value) const {
    DeviceSlot slot = createDefault("");
    if (const auto* object = value.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        if (const auto* params = object->getProperty("parameters").getDynamicObject()) {
            auto& model = std::get<SplitModel>(slot.config.instance);
            if (params->hasProperty("branch0Gain"))
                model.branch0Gain = static_cast<float>(
                    static_cast<double>(params->getProperty("branch0Gain")));
            if (params->hasProperty("branch1Gain"))
                model.branch1Gain = static_cast<float>(
                    static_cast<double>(params->getProperty("branch1Gain")));
            if (params->hasProperty("branch0Solo"))
                model.branch0Solo = static_cast<bool>(params->getProperty("branch0Solo"));
            if (params->hasProperty("branch1Solo"))
                model.branch1Solo = static_cast<bool>(params->getProperty("branch1Solo"));
        }
    }
    return slot;
}

DeviceProcessor* SplitDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.emplace<SplitProcessor>();
}

DeviceNodeKind SplitDeviceType::kind() const noexcept { return DeviceNodeKind::Split; }

uint16_t SplitDeviceType::paramIdFromString(std::string_view name) const noexcept {
    if (name == "branch0Gain") return 0;
    if (name == "branch1Gain") return 1;
    if (name == "branch0Solo") return 2;
    if (name == "branch1Solo") return 3;
    return static_cast<uint16_t>(-1);
}

std::string_view SplitDeviceType::paramIdToString(uint16_t id) const noexcept {
    switch (id) {
        case 0: return "branch0Gain";
        case 1: return "branch1Gain";
        case 2: return "branch0Solo";
        case 3: return "branch1Solo";
        default: return "";
    }
}

std::span<const ParamDescriptor> SplitDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor params[] = {
        {0, "branch0Gain", "Branch A Gain", 1, 0, 2, true, true},
        {1, "branch1Gain", "Branch B Gain", 1, 0, 2, true, true},
        {2, "branch0Solo", "Branch A Solo", 0, 0, 1, false, false},
        {3, "branch1Solo", "Branch B Solo", 0, 0, 1, false, false},
    };
    return params;
}

} // namespace audioapp
