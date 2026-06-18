#include "audioapp/devices/DeviceRegistry.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/IDeviceType.hpp"

namespace audioapp {
namespace {

DeviceState baseState(const std::string& deviceId, const char* typeId) {
    DeviceState state;
    state.id = deviceId;
    state.type = typeId;
    return state;
}

class OscillatorDeviceType final : public IDeviceType {
public:
    std::string typeId() const override { return device_types::kOscillator; }

    DeviceState createDefault(const std::string& deviceId) const override {
        DeviceState state = baseState(deviceId, device_types::kOscillator);
        state.frequencyHz = 440.0f;
        return state;
    }
};

class SamplerDeviceType final : public IDeviceType {
public:
    std::string typeId() const override { return device_types::kSampler; }

    DeviceState createDefault(const std::string& deviceId) const override {
        return baseState(deviceId, device_types::kSampler);
    }
};

class TrackGainDeviceType final : public IDeviceType {
public:
    std::string typeId() const override { return device_types::kTrackGain; }

    DeviceState createDefault(const std::string& deviceId) const override {
        DeviceState state = baseState(deviceId, device_types::kTrackGain);
        state.gain = 1.0f;
        return state;
    }
};

class SubtractiveSynthDeviceType final : public IDeviceType {
public:
    std::string typeId() const override { return device_types::kSubtractiveSynth; }

    DeviceState createDefault(const std::string& deviceId) const override {
        DeviceState state = baseState(deviceId, device_types::kSubtractiveSynth);
        state.attack = 0.02f;
        state.decay = 0.25f;
        state.sustain = 0.75f;
        state.release = 0.35f;
        state.filterCutoff = 0.75f;
        state.filterQ = 0.2f;
        state.osc1Wave = 2;
        state.osc2Wave = 2;
        state.osc1Shape = 0.5f;
        state.osc2Shape = 0.5f;
        state.osc1Level = 0.85f;
        state.osc2Level = 0.5f;
        state.filterEnvAmount = 0.5f;
        state.filterAttack = 0.05f;
        state.filterDecay = 0.35f;
        state.filterSustain = 0.4f;
        state.filterRelease = 0.45f;
        state.velocitySensitivity = 1.0f;
        return state;
    }
};

} // namespace

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

DeviceRegistry DeviceRegistry::createBuiltIn() {
    DeviceRegistry registry;
    registry.registerType(std::make_unique<OscillatorDeviceType>());
    registry.registerType(std::make_unique<SamplerDeviceType>());
    registry.registerType(std::make_unique<TrackGainDeviceType>());
    registry.registerType(std::make_unique<SubtractiveSynthDeviceType>());
    return registry;
}

} // namespace audioapp
