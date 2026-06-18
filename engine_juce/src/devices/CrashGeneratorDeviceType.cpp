#include "audioapp/devices/CrashGeneratorDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/CrashGeneratorInstance.hpp"

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

CrashGeneratorInstance instanceFromSnapshot(const DeviceState& state) {
    CrashGeneratorInstance instance;
    instance.crashModel = state.crashModel;
    instance.crashWash = state.crashWash;
    instance.crashBright = state.crashBright;
    instance.crashSpread = state.crashSpread;
    instance.crashDecay = state.crashDecay;
    instance.crashVelocity = state.crashVelocity;
    return instance;
}

void applyInstanceToSnapshot(const CrashGeneratorInstance& instance, DeviceState& state) {
    state.crashModel = instance.crashModel;
    state.crashWash = instance.crashWash;
    state.crashBright = instance.crashBright;
    state.crashSpread = instance.crashSpread;
    state.crashDecay = instance.crashDecay;
    state.crashVelocity = instance.crashVelocity;
}

} // namespace

std::string CrashGeneratorDeviceType::typeId() const {
    return device_types::kCrashGenerator;
}

DeviceSlot CrashGeneratorDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.instance = CrashGeneratorInstance{};
    return slot;
}

DeviceState CrashGeneratorDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kCrashGenerator);
    applyInstanceToSnapshot(std::get<CrashGeneratorInstance>(slot.instance), state);
    return state;
}

DeviceSlot CrashGeneratorDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
    return slot;
}

DeviceParameterResult CrashGeneratorDeviceType::setParameter(DeviceSlot& slot,
                                                             std::string_view parameterId,
                                                             float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<CrashGeneratorInstance>(slot.instance);
    const float clamped = std::clamp(value, 0.0f, 1.0f);
    if (parameterId == "crashModel") {
        instance.crashModel = clamped;
    } else if (parameterId == "crashWash") {
        instance.crashWash = clamped;
    } else if (parameterId == "crashBright") {
        instance.crashBright = clamped;
    } else if (parameterId == "crashSpread") {
        instance.crashSpread = clamped;
    } else if (parameterId == "crashDecay") {
        instance.crashDecay = clamped;
    } else if (parameterId == "crashVelocity") {
        instance.crashVelocity = clamped;
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool CrashGeneratorDeviceType::setStringParameter(DeviceSlot&,
                                                  std::string_view,
                                                  const std::string&,
                                                  const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> CrashGeneratorDeviceType::modulatableParams() const {
    return {"gain", "pan", "crashWash", "crashBright", "crashSpread", "crashDecay",
            "crashVelocity"};
}

void CrashGeneratorDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                 const PlaybackBuildContext&,
                                                 DeviceNodePlayback& out) const {
    const auto& instance = std::get<CrashGeneratorInstance>(slot.instance);
    out.kind = DeviceNodeKind::CrashGenerator;
    out.params = instance.toPlaybackParams(slot.gain);
}

bool CrashGeneratorDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                   const PlaybackBuildContext&,
                                                   LiveInstrumentSnapshot& out) const {
    const auto& instance = std::get<CrashGeneratorInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::CrashGenerator;
    out.gain = slot.gain;
    out.crash = instance.toPlaybackParams(slot.gain);
    return true;
}

} // namespace audioapp
