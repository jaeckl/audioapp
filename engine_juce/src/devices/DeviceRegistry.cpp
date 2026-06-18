#include "audioapp/devices/DeviceRegistry.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/KickGeneratorDeviceType.hpp"
#include "audioapp/devices/SnareGeneratorDeviceType.hpp"
#include "audioapp/devices/OscillatorDeviceType.hpp"
#include "audioapp/devices/SamplerDeviceType.hpp"
#include "audioapp/devices/SubtractiveSynthDeviceType.hpp"
#include "audioapp/devices/TrackGainDeviceType.hpp"
#include "audioapp/devices/instances/KickGeneratorInstance.hpp"
#include "audioapp/devices/instances/SnareGeneratorInstance.hpp"
#include "audioapp/devices/instances/OscillatorInstance.hpp"
#include "audioapp/devices/instances/SamplerInstance.hpp"
#include "audioapp/devices/instances/SubtractiveSynthInstance.hpp"
#include "audioapp/devices/instances/TrackGainInstance.hpp"

namespace audioapp {

DeviceRegistry::DeviceRegistry() = default;

void DeviceRegistry::registerType(std::unique_ptr<IDeviceType> type) {
    if (type == nullptr) {
        return;
    }
    typeIds_.push_back(type->typeId());
    types_.push_back(std::move(type));
}

const IDeviceType* DeviceRegistry::find(std::string_view typeId) const {
    for (const auto& type : types_) {
        if (type->typeId() == typeId) {
            return type.get();
        }
    }
    return nullptr;
}

bool DeviceRegistry::isKnownType(std::string_view typeId) const {
    return find(typeId) != nullptr;
}

std::vector<std::string_view> DeviceRegistry::knownTypes() const {
    return typeIds_;
}

const IDeviceType* DeviceRegistry::findForSlot(const DeviceSlot& slot) const {
    if (std::holds_alternative<OscillatorInstance>(slot.instance)) {
        return find(device_types::kOscillator);
    }
    if (std::holds_alternative<SamplerInstance>(slot.instance)) {
        return find(device_types::kSampler);
    }
    if (std::holds_alternative<TrackGainInstance>(slot.instance)) {
        return find(device_types::kTrackGain);
    }
    if (std::holds_alternative<SubtractiveSynthInstance>(slot.instance)) {
        return find(device_types::kSubtractiveSynth);
    }
    if (std::holds_alternative<KickGeneratorInstance>(slot.instance)) {
        return find(device_types::kKickGenerator);
    }
    if (std::holds_alternative<SnareGeneratorInstance>(slot.instance)) {
        return find(device_types::kSnareGenerator);
    }
    return nullptr;
}

DeviceSlot DeviceRegistry::createDefault(std::string_view typeId,
                                         const std::string& deviceId) const {
    const IDeviceType* type = find(typeId);
    if (type == nullptr) {
        return {};
    }
    return type->createDefault(deviceId);
}

DeviceState DeviceRegistry::toSnapshotState(const DeviceSlot& slot) const {
    const IDeviceType* type = findForSlot(slot);
    if (type == nullptr) {
        return {};
    }
    return type->toSnapshotState(slot);
}

DeviceSlot DeviceRegistry::slotFromSnapshot(const DeviceState& state) const {
    const IDeviceType* type = find(state.type);
    if (type == nullptr) {
        return {};
    }
    return type->slotFromSnapshot(state);
}

DeviceParameterResult DeviceRegistry::setParameter(DeviceSlot& slot,
                                                   std::string_view parameterId,
                                                   float value) const {
    const IDeviceType* type = findForSlot(slot);
    if (type == nullptr) {
        return {};
    }
    return type->setParameter(slot, parameterId, value);
}

bool DeviceRegistry::setStringParameter(DeviceSlot& slot,
                                        std::string_view parameterId,
                                        const std::string& value,
                                        const PlaybackBuildContext& context) const {
    const IDeviceType* type = findForSlot(slot);
    if (type == nullptr) {
        return false;
    }
    return type->setStringParameter(slot, parameterId, value, context);
}

void DeviceRegistry::buildPlaybackNode(const DeviceSlot& slot,
                                       const PlaybackBuildContext& context,
                                       DeviceNodePlayback& out) const {
    const IDeviceType* type = findForSlot(slot);
    if (type == nullptr) {
        out.kind = DeviceNodeKind::Unknown;
        return;
    }
    type->buildPlaybackNode(slot, context, out);
}

bool DeviceRegistry::buildLiveInstrument(const DeviceSlot& slot,
                                         const PlaybackBuildContext& context,
                                         LiveInstrumentSnapshot& out) const {
    const IDeviceType* type = findForSlot(slot);
    if (type == nullptr) {
        return false;
    }
    return type->buildLiveInstrument(slot, context, out);
}

std::vector<std::string_view> DeviceRegistry::modulatableParams(std::string_view typeId) const {
    const IDeviceType* type = find(typeId);
    if (type == nullptr) {
        return {};
    }
    return type->modulatableParams();
}

DeviceRegistry DeviceRegistry::createBuiltIn() {
    DeviceRegistry registry;
    registry.registerType(std::make_unique<OscillatorDeviceType>());
    registry.registerType(std::make_unique<SamplerDeviceType>());
    registry.registerType(std::make_unique<TrackGainDeviceType>());
    registry.registerType(std::make_unique<SubtractiveSynthDeviceType>());
    registry.registerType(std::make_unique<KickGeneratorDeviceType>());
    registry.registerType(std::make_unique<SnareGeneratorDeviceType>());
    return registry;
}

} // namespace audioapp
