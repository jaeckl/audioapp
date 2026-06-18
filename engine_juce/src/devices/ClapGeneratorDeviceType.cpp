#include "audioapp/devices/ClapGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/ClapGeneratorInstance.hpp"

#include <algorithm>

namespace audioapp {
namespace {

DeviceState stripSnapshot(const DeviceSlot& slot, std::string_view typeId) {
    DeviceState state;
    state.id = slot.id;
    state.type = std::string(typeId);
    state.gain = slot.gain;
    state.pan = slot.pan;
    state.bypassed = slot.bypassed;
    return state;
}

ClapGeneratorInstance instanceFromSnapshot(const DeviceState& state) {
    ClapGeneratorInstance instance;
    instance.clapBursts = state.clapBursts;
    instance.clapSpread = state.clapSpread;
    instance.clapTone = state.clapTone;
    instance.clapRoom = state.clapRoom;
    instance.clapDecay = state.clapDecay;
    return instance;
}

void applyInstanceToSnapshot(const ClapGeneratorInstance& instance, DeviceState& state) {
    state.clapBursts = instance.clapBursts;
    state.clapSpread = instance.clapSpread;
    state.clapTone = instance.clapTone;
    state.clapRoom = instance.clapRoom;
    state.clapDecay = instance.clapDecay;
}

} // namespace

std::string ClapGeneratorDeviceType::typeId() const {
    return device_types::kClapGenerator;
}

DeviceSlot ClapGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = ClapGeneratorInstance{};
    return slot;
}

DeviceState ClapGeneratorDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kClapGenerator);
    applyInstanceToSnapshot(std::get<ClapGeneratorInstance>(slot.instance), state);
    return state;
}

DeviceSlot ClapGeneratorDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult ClapGeneratorDeviceType::setParameter(DeviceSlot& slot,
                                                            std::string_view parameterId,
                                                            float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<ClapGeneratorInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "clapBursts") {
        instance.clapBursts = clamped;
    } else if (parameterId == "clapSpread") {
        instance.clapSpread = clamped;
    } else if (parameterId == "clapTone") {
        instance.clapTone = clamped;
    } else if (parameterId == "clapRoom") {
        instance.clapRoom = clamped;
    } else if (parameterId == "clapDecay") {
        instance.clapDecay = clamped;
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool ClapGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                 std::string_view,
                                                 const std::string&,
                                                 const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> ClapGeneratorDeviceType::modulatableParams() const {
    return {"gain", "pan", "clapBursts", "clapSpread", "clapTone", "clapRoom", "clapDecay"};
}

void ClapGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                const PlaybackBuildContext&,
                                                DeviceNodePlayback& out) const {
    const auto& instance = std::get<ClapGeneratorInstance>(slot.instance);
    out.kind = DeviceNodeKind::ClapGenerator;
    out.params = instance.toPlaybackParams(slot.gain);
}

bool ClapGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                  const PlaybackBuildContext&,
                                                  LiveInstrumentSnapshot& out) const {
    const auto& instance = std::get<ClapGeneratorInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::ClapGenerator;
    out.gain = slot.gain;
    out.clap = instance.toPlaybackParams(slot.gain);
    return true;
}

} // namespace audioapp
