#include "audioapp/devices/DeviceRegistry.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/KickGeneratorDeviceType.hpp"
#include "audioapp/devices/SnareGeneratorDeviceType.hpp"
#include "audioapp/devices/ClapGeneratorDeviceType.hpp"
#include "audioapp/devices/CymbalGeneratorDeviceType.hpp"
#include "audioapp/devices/CrashGeneratorDeviceType.hpp"
#include "audioapp/devices/GateDeviceType.hpp"
#include "audioapp/devices/CompressorDeviceType.hpp"
#include "audioapp/devices/ExpanderDeviceType.hpp"
#include "audioapp/devices/LimiterDeviceType.hpp"
#include "audioapp/devices/OscillatorDeviceType.hpp"
#include "audioapp/devices/SamplerDeviceType.hpp"
#include "audioapp/devices/SubtractiveSynthDeviceType.hpp"
#include "audioapp/devices/BassSynthDeviceType.hpp"
#include "audioapp/devices/PhaseModSynthDeviceType.hpp"
#include "audioapp/devices/TrackGainDeviceType.hpp"
#include "audioapp/devices/FilterDeviceType.hpp"
#include "audioapp/devices/FourBandEqDeviceType.hpp"
#include "audioapp/devices/FrequencyShifterDeviceType.hpp"
#include "audioapp/devices/ResonatorBankDeviceType.hpp"
#include "audioapp/devices/WavetableSynthDeviceType.hpp"
#include "audioapp/effects/BitcrusherDeviceType.hpp"
#include "audioapp/effects/DistortionDeviceType.hpp"
#include "audioapp/effects/TremoloDeviceType.hpp"
#include "audioapp/effects/EffectDeviceRegistration.hpp"

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
    std::vector<std::string_view> views;
    views.reserve(typeIds_.size());
    for (const auto& id : typeIds_) {
        views.push_back(id);
    }
    return views;
}

const IDeviceType* DeviceRegistry::findForSlot(const DeviceSlot& slot) const {
    if (slot.config.typeId.empty()) return nullptr;
    return find(slot.config.typeId);
}

const IDeviceType* DeviceRegistry::findByKind(DeviceNodeKind kind) const {
    for (const auto& type : types_) {
        if (type->kind() == kind) {
            return type.get();
        }
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
    registry.registerType(std::make_unique<ClapGeneratorDeviceType>());
    registry.registerType(std::make_unique<CymbalGeneratorDeviceType>());
    registry.registerType(std::make_unique<CrashGeneratorDeviceType>());
    registry.registerType(std::make_unique<GateDeviceType>());
    registry.registerType(std::make_unique<CompressorDeviceType>());
    registry.registerType(std::make_unique<ExpanderDeviceType>());
    registry.registerType(std::make_unique<LimiterDeviceType>());
    registry.registerType(std::make_unique<BassSynthDeviceType>());
    registry.registerType(std::make_unique<PhaseModSynthDeviceType>());
    registry.registerType(std::make_unique<WavetableSynthDeviceType>());
    registry.registerType(std::make_unique<FilterDeviceType>());
    registry.registerType(std::make_unique<FourBandEqDeviceType>());
    registry.registerType(std::make_unique<FrequencyShifterDeviceType>());
    registry.registerType(std::make_unique<ResonatorBankDeviceType>());
    registry.registerType(std::make_unique<BitcrusherDeviceType>());
    registry.registerType(std::make_unique<DistortionDeviceType>());
    registry.registerType(std::make_unique<TremoloDeviceType>());
    registerTimeBasedEffects(registry);

    // Register all param descriptors from each device type into the param registry
    for (const auto& type : registry.types_) {
        auto descs = type->paramDescriptors();
        if (!descs.empty()) {
            registry.paramRegistry_.registerDevice(type->typeId(), descs);
        }
    }

    return registry;
}

} // namespace audioapp
