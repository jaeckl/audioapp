#include "audioapp/devices/GranularDeviceType.hpp"
#include "audioapp/SampleBank.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/GranularModel.hpp"
#include "audioapp/devices/processors/GranularProcessor.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {
namespace {
constexpr const char* ids[] = {
    "position", "scan", "grainSize", "density", "spray", "grainPitch",
    "formant", "character", "regionStart", "regionEnd", "attack",
    "release", "spread", "formX", "formY", "vowel"};
constexpr float formPoints[6][2] = {
    {.5f,.05f},{.88f,.25f},{.88f,.75f},{.12f,.25f},{.12f,.75f},{.5f,.95f}};
}

std::string GranularDeviceType::typeId() const { return device_types::kGranular; }

DeviceSlot GranularDeviceType::createDefault(const std::string& id) const {
    DeviceSlot slot;
    slot.id = id;
    slot.config.typeId = typeId();
    slot.config.instance = GranularModel{};
    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    return slot;
}

uint16_t GranularDeviceType::paramIdFromString(std::string_view name) const noexcept {
    for (uint16_t i = 0; i < 16; ++i)
        if (name == ids[i]) return i;
    return static_cast<uint16_t>(-1);
}

std::string_view GranularDeviceType::paramIdToString(uint16_t id) const noexcept {
    return id < 16 ? ids[id] : "";
}

DeviceParameterResult GranularDeviceType::setParameter(
    DeviceSlot& slot, std::string_view name, float value) const {
    const auto id = paramIdFromString(name);
    if (id > 15) return {};
    auto& model = std::get<GranularModel>(slot.config.instance);
    float* values[] = {&model.position, &model.scan, &model.size, &model.density,
                       &model.spray, &model.pitch, &model.formant, &model.character,
                       &model.regionStart, &model.regionEnd, &model.attack,
                       &model.release, &model.spread,&model.formX,&model.formY};
    if (id < 15) {
        *values[id] = std::clamp(value, 0.0f, 1.0f);
        if (model.regionEnd < model.regionStart + 0.02f) {
            if (id == 8) model.regionStart = std::max(0.0f, model.regionEnd - 0.02f);
            if (id == 9) model.regionEnd = std::min(1.0f, model.regionStart + 0.02f);
        }
    } else {
        model.vowel = std::clamp(static_cast<int>(std::lround(value)), 0, 5);
        model.formX=formPoints[model.vowel][0];
        model.formY=formPoints[model.vowel][1];
    }
    return {.handled = true};
}

bool GranularDeviceType::setStringParameter(
    DeviceSlot& slot, std::string_view name, const std::string& value,
    const PlaybackBuildContext& context) const {
    if (name != "sampleId" ||
        (!value.empty() && context.sampleBank && !context.sampleBank->findSample(value)))
        return false;
    std::get<GranularModel>(slot.config.instance).sampleId = value;
    return true;
}

std::vector<std::string_view> GranularDeviceType::modulatableParams() const {
    return {"position", "scan", "grainSize", "density", "spray", "grainPitch",
            "formant", "character", "attack", "release", "spread", "formX", "formY"};
}

void GranularDeviceType::buildPlaybackNode(
    const DeviceSlot& slot, const PlaybackBuildContext& context,
    DeviceNodePlayback& output) const {
    const auto& model = std::get<GranularModel>(slot.config.instance);
    GranularParams p;
    p.position=model.position; p.scan=model.scan; p.size=model.size;
    p.density=model.density; p.spray=model.spray; p.pitch=model.pitch;
    p.formant=model.formant; p.character=model.character;
    p.regionStart=model.regionStart; p.regionEnd=model.regionEnd;
    p.attack=model.attack; p.release=model.release; p.spread=model.spread;
    p.formX=model.formX; p.formY=model.formY;
    p.vowel=model.vowel;
    if (context.sampleBank) {
        if (const auto* sample = context.sampleBank->findSample(model.sampleId)) {
            p.pcm = sample->pcm.data();
            p.frameCount = static_cast<int>(sample->pcm.size());
            p.pcmRate = sample->sampleRate;
        }
    }
    output.kind = DeviceNodeKind::Granular;
    output.params = p;
}

bool GranularDeviceType::buildLiveInstrument(
    const DeviceSlot& slot, const PlaybackBuildContext& context,
    LiveInstrumentSnapshot& output) const {
    DeviceNodePlayback node;
    buildPlaybackNode(slot, context, node);
    const auto& params = std::get<GranularParams>(node.params);
    if (params.pcm == nullptr || params.frameCount < 4) return false;
    output.kind = LiveInstrumentKind::Granular;
    output.granular = params;
    output.gain = 1.0f;
    return true;
}

juce::var GranularDeviceType::slotToVar(const DeviceSlot& slot) const {
    const auto& m = std::get<GranularModel>(slot.config.instance);
    auto* parameters = new juce::DynamicObject();
    parameters->setProperty("sampleId", juce::String(m.sampleId));
    const float values[] = {m.position,m.scan,m.size,m.density,m.spray,m.pitch,
                            m.formant,m.character,m.regionStart,m.regionEnd,
                            m.attack,m.release,m.spread,m.formX,m.formY};
    for (int i=0;i<15;++i) parameters->setProperty(ids[i], values[i]);
    parameters->setProperty("vowel", m.vowel);
    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String(slot.id));
    object->setProperty("type", juce::String(typeId()));
    object->setProperty("bypass", slot.config.bypassed);
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot GranularDeviceType::varToSlot(const juce::var& value) const {
    auto slot = createDefault("");
    if (auto* object = value.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.bypassed = static_cast<bool>(object->getProperty("bypass"));
        if (auto* p = object->getProperty("parameters").getDynamicObject()) {
            auto& m = std::get<GranularModel>(slot.config.instance);
            m.sampleId = p->getProperty("sampleId").toString().toStdString();
            for (int i=0;i<15;++i) {
                const auto v = p->getProperty(ids[i]);
                if (!v.isVoid()) setParameter(slot, ids[i], static_cast<float>(static_cast<double>(v)));
            }
            const auto vowel = p->getProperty("vowel");
            if (!vowel.isVoid() && p->getProperty("formX").isVoid())
                setParameter(slot,"vowel",static_cast<float>(static_cast<int>(vowel)));
        }
    }
    return slot;
}

DeviceProcessor* GranularDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.emplace<GranularProcessor>();
}

std::span<const ParamDescriptor> GranularDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor p[] = {
        {0,"position","Position",.25,0,1,true,true}, {1,"scan","Scan",.15,0,1,true,true},
        {2,"grainSize","Size",.35,0,1,true,true}, {3,"density","Density",.35,0,1,true,true},
        {4,"spray","Spray",.1,0,1,true,true}, {5,"grainPitch","Pitch",.5,0,1,true,true},
        {6,"formant","Formant",.5,0,1,true,true}, {7,"character","Character",.45,0,1,true,true},
        {8,"regionStart","Region Start",0,0,1,true,false}, {9,"regionEnd","Region End",1,0,1,true,false},
        {10,"attack","Attack",.02,0,1,true,true}, {11,"release","Release",.25,0,1,true,true},
        {12,"spread","Stereo Spread",.35,0,1,true,true},
        {13,"formX","Form X",.5,0,1,true,true}, {14,"formY","Form Y",.05,0,1,true,true},
        {15,"vowel","Legacy Form",0,0,5,false,false}};
    return p;
}
} // namespace audioapp
