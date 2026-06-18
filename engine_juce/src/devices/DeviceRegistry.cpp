#include "audioapp/devices/DeviceRegistry.hpp"

#include "audioapp/devices/OscillatorDeviceType.hpp"
#include "audioapp/devices/SamplerDeviceType.hpp"
#include "audioapp/devices/SubtractiveSynthDeviceType.hpp"
#include "audioapp/devices/TrackGainDeviceType.hpp"

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

DeviceState DeviceRegistry::createDefault(std::string_view typeId,
                                          const std::string& deviceId) const {
    const IDeviceType* type = find(typeId);
    if (type == nullptr) {
        return {};
    }
    return type->createDefault(deviceId);
}

DeviceParameterResult DeviceRegistry::setParameter(DeviceState& state,
                                                   std::string_view parameterId,
                                                   float value) const {
    const IDeviceType* type = find(state.type);
    if (type == nullptr) {
        return {};
    }
    return type->setParameter(state, parameterId, value);
}

bool DeviceRegistry::setStringParameter(DeviceState& state,
                                        std::string_view parameterId,
                                        const std::string& value,
                                        const PlaybackBuildContext& context) const {
    const IDeviceType* type = find(state.type);
    if (type == nullptr) {
        return false;
    }
    return type->setStringParameter(state, parameterId, value, context);
}

void DeviceRegistry::buildPlaybackNode(const DeviceState& state,
                                       const PlaybackBuildContext& context,
                                       DeviceNodePlayback& out) const {
    const IDeviceType* type = find(state.type);
    if (type == nullptr) {
        out.kind = DeviceNodeKind::Unknown;
        return;
    }
    type->buildPlaybackNode(state, context, out);
}

bool DeviceRegistry::buildLiveInstrument(const DeviceState& state,
                                           const PlaybackBuildContext& context,
                                           LiveInstrumentSnapshot& out) const {
    const IDeviceType* type = find(state.type);
    if (type == nullptr) {
        return false;
    }
    return type->buildLiveInstrument(state, context, out);
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
    return registry;
}

} // namespace audioapp
