#include "audioapp/devices/DedicatedPercussionDeviceTypes.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/processors/DedicatedPercussionProcessors.hpp"

#include <algorithm>

namespace audioapp {
namespace {

float readFloat(const juce::DynamicObject* object, const char* key, float fallback) {
    const auto value = object->getProperty(key);
    return value.isDouble() || value.isInt() || value.isInt64()
        ? static_cast<float>(static_cast<double>(value)) : fallback;
}

juce::var baseObject(const DeviceSlot& slot, const std::string& typeId,
                     juce::DynamicObject* parameters) {
    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId.c_str()));
    object->setProperty("parameters", juce::var(parameters));
    auto* output = new juce::DynamicObject();
    output->setProperty("type", "mono");
    output->setProperty("gain", static_cast<double>(std::get<MonoOutputPanel>(slot.config.outputPanel).gain));
    object->setProperty("outputPanel", juce::var(output));
    auto* input = new juce::DynamicObject();
    input->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(input));
    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    return juce::var(object);
}

void readCommonSlot(const juce::DynamicObject* object, DeviceSlot& slot) {
    slot.id = object->getProperty("id").toString().toStdString();
    slot.config.typeId = object->getProperty("type").toString().toStdString();
    slot.config.outputPanel = MonoOutputPanel{};
    if (const auto* output = object->getProperty("outputPanel").getDynamicObject())
        slot.config.outputPanel = MonoOutputPanel{readFloat(output, "gain", 1.0f)};
    slot.config.bypassed = static_cast<bool>(object->getProperty("bypass"));
}

template <typename Enum>
uint16_t findParam(std::string_view name, std::span<const ParamDescriptor> descriptors) {
    for (const auto& descriptor : descriptors)
        if (name == descriptor.stableName) return descriptor.localParamId;
    return static_cast<uint16_t>(-1);
}

} // namespace

std::string DedicatedPercussionDeviceType::typeId() const {
    switch (percussionKind_) {
    case DedicatedPercussionKind::Hihat: return device_types::kHihatGenerator;
    case DedicatedPercussionKind::Ride: return device_types::kRideGenerator;
    case DedicatedPercussionKind::Tom: return device_types::kTomGenerator;
    case DedicatedPercussionKind::Rimshot: return device_types::kRimshotGenerator;
    }
    return {};
}

DeviceNodeKind DedicatedPercussionDeviceType::kind() const noexcept {
    switch (percussionKind_) {
    case DedicatedPercussionKind::Hihat: return DeviceNodeKind::HihatGenerator;
    case DedicatedPercussionKind::Ride: return DeviceNodeKind::RideGenerator;
    case DedicatedPercussionKind::Tom: return DeviceNodeKind::TomGenerator;
    case DedicatedPercussionKind::Rimshot: return DeviceNodeKind::RimshotGenerator;
    }
    return DeviceNodeKind::Unknown;
}

DeviceSlot DedicatedPercussionDeviceType::createDefault(const std::string& id) const {
    DeviceSlot slot;
    slot.id = id;
    slot.config.typeId = typeId();
    slot.config.outputPanel = MonoOutputPanel{};
    switch (percussionKind_) {
    case DedicatedPercussionKind::Hihat: slot.config.instance = HihatGeneratorParams{}; break;
    case DedicatedPercussionKind::Ride: slot.config.instance = RideGeneratorParams{}; break;
    case DedicatedPercussionKind::Tom: slot.config.instance = TomGeneratorParams{}; break;
    case DedicatedPercussionKind::Rimshot: slot.config.instance = RimshotGeneratorParams{}; break;
    }
    return slot;
}

DeviceParameterResult DedicatedPercussionDeviceType::setParameter(DeviceSlot& slot,
        std::string_view id, float value) const {
    if (device_strip::setStripParameter(slot, id, value)) return {true, false};
    const float v = std::clamp(value, 0.0f, 1.0f);
    const auto pid = paramIdFromString(id);
    if (pid == static_cast<uint16_t>(-1)) return {};
    switch (percussionKind_) {
    case DedicatedPercussionKind::Hihat: {
        auto& p = std::get<HihatGeneratorParams>(slot.config.instance);
        switch (static_cast<HihatParam>(pid)) { case HihatParam::Pitch:p.hihatPitch=v;break; case HihatParam::Color:p.hihatColor=v;break; case HihatParam::Decay:p.hihatDecay=v;break; case HihatParam::Tightness:p.hihatTightness=v;break; case HihatParam::Noise:p.hihatNoise=v;break; case HihatParam::Width:p.hihatWidth=v;break; case HihatParam::Velocity:p.hihatVelocity=v;break; case HihatParam::KeyTrack:p.hihatKeyTrack=v>=.5f;break; }
        break;
    }
    case DedicatedPercussionKind::Ride: {
        auto& p = std::get<RideGeneratorParams>(slot.config.instance);
        switch (static_cast<RideParam>(pid)) { case RideParam::Pitch:p.ridePitch=v;break; case RideParam::Brightness:p.rideBrightness=v;break; case RideParam::Decay:p.rideDecay=v;break; case RideParam::Bell:p.rideBell=v;break; case RideParam::Damping:p.rideDamping=v;break; case RideParam::Width:p.rideWidth=v;break; case RideParam::Velocity:p.rideVelocity=v;break; case RideParam::KeyTrack:p.rideKeyTrack=v>=.5f;break; }
        break;
    }
    case DedicatedPercussionKind::Tom: {
        auto& p = std::get<TomGeneratorParams>(slot.config.instance);
        switch (static_cast<TomParam>(pid)) { case TomParam::Pitch:p.tomPitch=v;break; case TomParam::Decay:p.tomDecay=v;break; case TomParam::Bend:p.tomBend=v;break; case TomParam::Body:p.tomBody=v;break; case TomParam::Attack:p.tomAttack=v;break; case TomParam::Noise:p.tomNoise=v;break; case TomParam::Velocity:p.tomVelocity=v;break; case TomParam::KeyTrack:p.tomKeyTrack=v>=.5f;break; }
        break;
    }
    case DedicatedPercussionKind::Rimshot: {
        auto& p = std::get<RimshotGeneratorParams>(slot.config.instance);
        switch (static_cast<RimshotParam>(pid)) { case RimshotParam::Pitch:p.rimshotPitch=v;break; case RimshotParam::Decay:p.rimshotDecay=v;break; case RimshotParam::Tone:p.rimshotTone=v;break; case RimshotParam::Snap:p.rimshotSnap=v;break; case RimshotParam::Body:p.rimshotBody=v;break; case RimshotParam::Velocity:p.rimshotVelocity=v;break; case RimshotParam::KeyTrack:p.rimshotKeyTrack=v>=.5f;break; }
        break;
    }
    }
    return {true, false};
}

std::vector<std::string_view> DedicatedPercussionDeviceType::modulatableParams() const {
    std::vector<std::string_view> result{"gain"};
    for (const auto& descriptor : paramDescriptors())
        if (descriptor.modulatable) result.push_back(descriptor.stableName);
    return result;
}

void DedicatedPercussionDeviceType::buildPlaybackNode(const DeviceSlot& slot,
        const PlaybackBuildContext&, DeviceNodePlayback& out) const {
    out.kind = kind();
    switch (percussionKind_) {
    case DedicatedPercussionKind::Hihat: { auto p=std::get<HihatGeneratorParams>(slot.config.instance);p.gain=1;out.params=p;break; }
    case DedicatedPercussionKind::Ride: { auto p=std::get<RideGeneratorParams>(slot.config.instance);p.gain=1;out.params=p;break; }
    case DedicatedPercussionKind::Tom: { auto p=std::get<TomGeneratorParams>(slot.config.instance);p.gain=1;out.params=p;break; }
    case DedicatedPercussionKind::Rimshot: { auto p=std::get<RimshotGeneratorParams>(slot.config.instance);p.gain=1;out.params=p;break; }
    }
}

bool DedicatedPercussionDeviceType::buildLiveInstrument(const DeviceSlot& slot,
        const PlaybackBuildContext&, LiveInstrumentSnapshot& out) const {
    out = {};
    const float gain = std::get<MonoOutputPanel>(slot.config.outputPanel).gain;
    out.gain = gain;
    switch (percussionKind_) {
    case DedicatedPercussionKind::Hihat: out.kind=LiveInstrumentKind::HihatGenerator; out.hihat=std::get<HihatGeneratorParams>(slot.config.instance); out.hihat.gain=gain; break;
    case DedicatedPercussionKind::Ride: out.kind=LiveInstrumentKind::RideGenerator; out.ride=std::get<RideGeneratorParams>(slot.config.instance); out.ride.gain=gain; break;
    case DedicatedPercussionKind::Tom: out.kind=LiveInstrumentKind::TomGenerator; out.tom=std::get<TomGeneratorParams>(slot.config.instance); out.tom.gain=gain; break;
    case DedicatedPercussionKind::Rimshot: out.kind=LiveInstrumentKind::RimshotGenerator; out.rimshot=std::get<RimshotGeneratorParams>(slot.config.instance); out.rimshot.gain=gain; break;
    }
    return true;
}

juce::var DedicatedPercussionDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* p = new juce::DynamicObject();
    for (const auto& d : paramDescriptors()) {
        float value = d.defaultValue;
        switch (percussionKind_) {
        case DedicatedPercussionKind::Hihat: { const auto& x=std::get<HihatGeneratorParams>(slot.config.instance); const float a[]={x.hihatPitch,x.hihatColor,x.hihatDecay,x.hihatTightness,x.hihatNoise,x.hihatWidth,x.hihatVelocity,x.hihatKeyTrack}; value=a[d.localParamId]; break; }
        case DedicatedPercussionKind::Ride: { const auto& x=std::get<RideGeneratorParams>(slot.config.instance); const float a[]={x.ridePitch,x.rideBrightness,x.rideDecay,x.rideBell,x.rideDamping,x.rideWidth,x.rideVelocity,x.rideKeyTrack}; value=a[d.localParamId]; break; }
        case DedicatedPercussionKind::Tom: { const auto& x=std::get<TomGeneratorParams>(slot.config.instance); const float a[]={x.tomPitch,x.tomDecay,x.tomBend,x.tomBody,x.tomAttack,x.tomNoise,x.tomVelocity,x.tomKeyTrack}; value=a[d.localParamId]; break; }
        case DedicatedPercussionKind::Rimshot: { const auto& x=std::get<RimshotGeneratorParams>(slot.config.instance); const float a[]={x.rimshotPitch,x.rimshotDecay,x.rimshotTone,x.rimshotSnap,x.rimshotBody,x.rimshotVelocity,x.rimshotKeyTrack}; value=a[d.localParamId]; break; }
        }
        p->setProperty(d.stableName, static_cast<double>(value));
    }
    return baseObject(slot, typeId(), p);
}

DeviceSlot DedicatedPercussionDeviceType::varToSlot(const juce::var& value) const {
    DeviceSlot slot = createDefault({});
    const auto* object = value.getDynamicObject();
    if (!object) return {};
    readCommonSlot(object, slot);
    const auto* p = object->getProperty("parameters").getDynamicObject();
    if (!p) return slot;
    for (const auto& d : paramDescriptors())
        setParameter(slot, d.stableName, readFloat(p, d.stableName, d.defaultValue));
    return slot;
}

DeviceProcessor* DedicatedPercussionDeviceType::createProcessor(ProcessorArena& arena) const {
    switch (percussionKind_) {
    case DedicatedPercussionKind::Hihat: return arena.emplace<HihatProcessor>();
    case DedicatedPercussionKind::Ride: return arena.emplace<RideProcessor>();
    case DedicatedPercussionKind::Tom: return arena.emplace<TomProcessor>();
    case DedicatedPercussionKind::Rimshot: return arena.emplace<RimshotProcessor>();
    }
    return nullptr;
}

uint16_t DedicatedPercussionDeviceType::paramIdFromString(std::string_view name) const noexcept {
    for (const auto& d : paramDescriptors()) if (name == d.stableName) return d.localParamId;
    return static_cast<uint16_t>(-1);
}

std::string_view DedicatedPercussionDeviceType::paramIdToString(uint16_t id) const noexcept {
    for (const auto& d : paramDescriptors()) if (id == d.localParamId) return d.stableName;
    return {};
}

std::span<const ParamDescriptor> DedicatedPercussionDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor hat[] = {
        {0,"hihatPitch","Pitch",.50f,0,1,true,true},{1,"hihatColor","Color",.68f,0,1,true,true},{2,"hihatDecay","Decay",.28f,0,1,true,true},{3,"hihatTightness","Tightness",.72f,0,1,true,true},{4,"hihatNoise","Noise",.34f,0,1,true,true},{5,"hihatWidth","Width",.25f,0,1,true,true},{6,"hihatVelocity","Velocity",1,0,1,true,true},{7,"hihatKeyTrack","Key Track",0,0,1,true,true,ParameterUpdateRate::Discrete}};
    static constexpr ParamDescriptor ride[] = {
        {0,"ridePitch","Pitch",.50f,0,1,true,true},{1,"rideBrightness","Brightness",.62f,0,1,true,true},{2,"rideDecay","Decay",.62f,0,1,true,true},{3,"rideBell","Bell",.28f,0,1,true,true},{4,"rideDamping","Damping",.35f,0,1,true,true},{5,"rideWidth","Width",.30f,0,1,true,true},{6,"rideVelocity","Velocity",1,0,1,true,true},{7,"rideKeyTrack","Key Track",0,0,1,true,true,ParameterUpdateRate::Discrete}};
    static constexpr ParamDescriptor tom[] = {
        {0,"tomPitch","Pitch",.42f,0,1,true,true},{1,"tomDecay","Decay",.42f,0,1,true,true},{2,"tomBend","Bend",.38f,0,1,true,true},{3,"tomBody","Body",.72f,0,1,true,true},{4,"tomAttack","Attack",.35f,0,1,true,true},{5,"tomNoise","Noise",.16f,0,1,true,true},{6,"tomVelocity","Velocity",1,0,1,true,true},{7,"tomKeyTrack","Key Track",0,0,1,true,true,ParameterUpdateRate::Discrete}};
    static constexpr ParamDescriptor rim[] = {
        {0,"rimshotPitch","Pitch",.52f,0,1,true,true},{1,"rimshotDecay","Decay",.24f,0,1,true,true},{2,"rimshotTone","Tone",.62f,0,1,true,true},{3,"rimshotSnap","Snap",.74f,0,1,true,true},{4,"rimshotBody","Body",.38f,0,1,true,true},{5,"rimshotVelocity","Velocity",1,0,1,true,true},{6,"rimshotKeyTrack","Key Track",0,0,1,true,true,ParameterUpdateRate::Discrete}};
    switch (percussionKind_) { case DedicatedPercussionKind::Hihat:return hat; case DedicatedPercussionKind::Ride:return ride; case DedicatedPercussionKind::Tom:return tom; case DedicatedPercussionKind::Rimshot:return rim; }
    return {};
}

} // namespace audioapp
