#include "audioapp/devices/WavetableSynthDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/WavetableBank.hpp"
#include "audioapp/WavetableSynthAlgorithm.hpp"
#include "audioapp/devices/processors/WavetableSynthProcessor.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string WavetableSynthDeviceType::typeId() const {
    return device_types::kWavetableSynth;
}

DeviceSlot WavetableSynthDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    WavetableSynthParams instance;
    instance.wavetableId = "sine_64";
    instance.ampAttack = 0.01f;
    instance.ampDecay = 0.2f;
    instance.ampSustain = 0.8f;
    instance.ampRelease = 0.3f;
    instance.filterCutoff = 1.0f;
    instance.filterResonance = 0.2f;
    instance.filterEnvAmount = 0.5f;
    instance.filterAttack = 0.1f;
    instance.filterDecay = 0.3f;
    instance.filterSustain = 0.5f;
    instance.filterRelease = 0.5f;
    instance.wtPosition = 0.0f;
    instance.wtOctave = 0.5f;
    instance.wtSemitone = 0.5f;
    instance.wtFine = 0.5f;
    instance.wtUnison = 0.0f;
    instance.wtDetune = 0.0f;
    slot.config.instance = std::move(instance);

    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult WavetableSynthDeviceType::setParameter(DeviceSlot& slot,
                                                             std::string_view parameterId,
                                                             float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<WavetableSynthParams>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    switch (static_cast<WavetableParam>(id)) {
    case WavetableParam::AmpAttack:   instance.ampAttack = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::AmpDecay:    instance.ampDecay = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::AmpSustain:  instance.ampSustain = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::AmpRelease:  instance.ampRelease = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::FilterCutoff:    instance.filterCutoff = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::FilterResonance: instance.filterResonance = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::FilterEnvAmount: instance.filterEnvAmount = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::FilterAttack:    instance.filterAttack = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::FilterDecay:     instance.filterDecay = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::FilterSustain:   instance.filterSustain = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::FilterRelease:   instance.filterRelease = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::WtPosition:  instance.wtPosition = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::WtOctave:    instance.wtOctave = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::WtSemitone:  instance.wtSemitone = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::WtFine:      instance.wtFine = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::WtUnison:    instance.wtUnison = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::WtDetune:    instance.wtDetune = std::clamp(value, 0.0f, 1.0f); break;
    case WavetableParam::FilterMode:  instance.filterMode = std::clamp(static_cast<int>(std::lround(value)), 0, 3); break;
    default:
        return result;
    }

    result.handled = true;
    return result;
}

bool WavetableSynthDeviceType::setStringParameter(DeviceSlot& slot,
                                                   std::string_view parameterId,
                                                   const std::string& value,
                                                   const PlaybackBuildContext& context) const {
    if (parameterId == "wavetable") {
        auto& instance = std::get<WavetableSynthParams>(slot.config.instance);
        if (context.wavetableBank != nullptr && context.wavetableBank->findByName(value) >= 0) {
            instance.wavetableId = value;
            return true;
        }
        // Allow setting ID even if not in bank yet (will resolve at playback)
        instance.wavetableId = value;
        return true;
    }
    return false;
}

std::vector<std::string_view> WavetableSynthDeviceType::modulatableParams() const {
    return {
        "gain", "pan", "filterCutoff", "filterResonance", "filterMode",
        "wtPosition", "wtOctave", "wtSemitone", "wtFine",
        "wtUnison", "wtDetune", "filterEnvAmount",
        "attack", "decay", "sustain", "release",
        "filterAttack", "filterDecay", "filterSustain", "filterRelease",
    };
}

void WavetableSynthDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                  const PlaybackBuildContext&,
                                                  DeviceNodePlayback& out) const {
    auto params = std::get<WavetableSynthParams>(slot.config.instance);
    params.gain = 1.0f; // output-panel gain is applied by the device-chain stage
    out.kind = DeviceNodeKind::WavetableSynth;
    out.params = params;
}

bool WavetableSynthDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                    const PlaybackBuildContext& ctx,
                                                    LiveInstrumentSnapshot& out) const {
    auto params = std::get<WavetableSynthParams>(slot.config.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::WavetableSynth;
    const auto gain = std::get<StereoOutputPanel>(slot.config.outputPanel).gain;
    out.gain = gain;
    out.wavetable = params;
    out.wavetable.gain = gain;
    // Resolve wavetable PCM at noteOn time
    out.wavetablePcm = nullptr;
    out.wavetablePcmFrameCount = 0;
    out.wavetablePcmFrameLength = 0;
    if (ctx.wavetableBank != nullptr) {
        const auto& wtId = params.wavetableId;
        int bankIdx = -1;
        if (!wtId.empty()) {
            bankIdx = ctx.wavetableBank->findByName(wtId);
        }
        if (bankIdx < 0) {
            bankIdx = 0;
        }
        const auto* entry = ctx.wavetableBank->get(bankIdx);
        if (entry != nullptr && !entry->pcm.empty()) {
            out.wavetablePcm = entry->pcm.data();
            out.wavetablePcmFrameCount = entry->frameCount;
            out.wavetablePcmFrameLength = entry->frameLength;
        }
    }
    return true;
}

juce::var WavetableSynthDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<WavetableSynthParams>(slot.config.instance);

    // ADSR
    parameters->setProperty("attack", static_cast<double>(inst.ampAttack));
    parameters->setProperty("decay", static_cast<double>(inst.ampDecay));
    parameters->setProperty("sustain", static_cast<double>(inst.ampSustain));
    parameters->setProperty("release", static_cast<double>(inst.ampRelease));

    // Filter
    parameters->setProperty("filterCutoff", static_cast<double>(inst.filterCutoff));
    parameters->setProperty("filterResonance", static_cast<double>(inst.filterResonance));
    parameters->setProperty("filterEnvAmount", static_cast<double>(inst.filterEnvAmount));
    parameters->setProperty("filterAttack", static_cast<double>(inst.filterAttack));
    parameters->setProperty("filterDecay", static_cast<double>(inst.filterDecay));
    parameters->setProperty("filterSustain", static_cast<double>(inst.filterSustain));
    parameters->setProperty("filterRelease", static_cast<double>(inst.filterRelease));
    parameters->setProperty("filterMode", inst.filterMode);

    // WT id
    parameters->setProperty("wavetableId", juce::String::fromUTF8(inst.wavetableId.c_str()));

    // WT params
    parameters->setProperty("wtPosition", static_cast<double>(inst.wtPosition));
    parameters->setProperty("wtOctave", static_cast<double>(inst.wtOctave));
    parameters->setProperty("wtSemitone", static_cast<double>(inst.wtSemitone));
    parameters->setProperty("wtFine", static_cast<double>(inst.wtFine));
    parameters->setProperty("wtUnison", static_cast<double>(inst.wtUnison));
    parameters->setProperty("wtDetune", static_cast<double>(inst.wtDetune));

    auto* object = new juce::DynamicObject();
    object->setProperty("id", juce::String::fromUTF8(slot.id.c_str()));
    object->setProperty("type", juce::String::fromUTF8(typeId().c_str()));

    auto* outObj = new juce::DynamicObject();
    const auto& panel = std::get<StereoOutputPanel>(slot.config.outputPanel);
    outObj->setProperty("type", "stereo");
    outObj->setProperty("gain", static_cast<double>(panel.gain));
    outObj->setProperty("pan", static_cast<double>(panel.pan));
    object->setProperty("outputPanel", juce::var(outObj));

    auto* inObj = new juce::DynamicObject();
    inObj->setProperty("type", "empty");
    object->setProperty("inputPanel", juce::var(inObj));

    object->setProperty("bypass", slot.config.bypassed ? 1.0 : 0.0);
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot WavetableSynthDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
        slot.config.typeId = object->getProperty("type").toString().toStdString();

        const auto outputPanelVar = object->getProperty("outputPanel");
        bool hasPanel = outputPanelVar.isObject();
        if (hasPanel) {
            const auto* panel = outputPanelVar.getDynamicObject();
            StereoOutputPanel sp;
            sp.gain = static_cast<float>(static_cast<double>(panel->getProperty("gain")));
            sp.pan = static_cast<float>(static_cast<double>(panel->getProperty("pan")));
            slot.config.outputPanel = sp;
        }

        slot.config.bypassed = object->getProperty("bypass").isDouble()
            ? (static_cast<float>(static_cast<double>(object->getProperty("bypass"))) >= 0.5f)
            : false;

        const auto params = object->getProperty("parameters");
        if (const auto* p = params.getDynamicObject()) {
            auto readFloat = [&](const char* key, float fallback) -> float {
                const auto v = p->getProperty(key);
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<float>(static_cast<double>(v));
                return fallback;
            };
            auto readInt = [&](const char* key, int fallback) -> int {
                const auto v = p->getProperty(key);
                if (v.isInt() || v.isInt64())
                    return static_cast<int>(v);
                if (v.isDouble())
                    return static_cast<int>(static_cast<double>(v));
                return fallback;
            };

            if (!hasPanel) {
                const float oldGain = readFloat("gain", 1.0f);
                const float oldPan = readFloat("pan", 0.5f);
                slot.config.outputPanel = StereoOutputPanel{oldGain, oldPan};
                slot.config.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            }

            WavetableSynthParams inst;

            inst.wavetableId = p->getProperty("wavetableId").toString().toStdString();
            inst.ampAttack = readFloat("attack", 0.01f);
            inst.ampDecay = readFloat("decay", 0.3f);
            inst.ampSustain = readFloat("sustain", 0.7f);
            inst.ampRelease = readFloat("release", 0.4f);

            inst.filterCutoff = readFloat("filterCutoff", 1.0f);
            inst.filterResonance = readFloat("filterResonance", 0.0f);
            inst.filterEnvAmount = readFloat("filterEnvAmount", 0.0f);
            inst.filterAttack = readFloat("filterAttack", 0.1f);
            inst.filterDecay = readFloat("filterDecay", 0.3f);
            inst.filterSustain = readFloat("filterSustain", 0.5f);
            inst.filterRelease = readFloat("filterRelease", 0.5f);
            inst.filterMode = readInt("filterMode", 0);

            inst.wtPosition = readFloat("wtPosition", 0.0f);
            inst.wtOctave = readFloat("wtOctave", 0.5f);
            inst.wtSemitone = readFloat("wtSemitone", 0.5f);
            inst.wtFine = readFloat("wtFine", 0.5f);
            inst.wtUnison = readFloat("wtUnison", 0.0f);
            inst.wtDetune = readFloat("wtDetune", 0.0f);

            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* WavetableSynthDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<WavetableSynthProcessor>();
}

DeviceNodeKind WavetableSynthDeviceType::kind() const noexcept { return DeviceNodeKind::WavetableSynth; }

uint16_t WavetableSynthDeviceType::paramIdFromString(std::string_view name) const noexcept {
    auto s = [&](std::string_view n, WavetableParam pid) -> uint16_t {
        return name == n ? static_cast<uint16_t>(pid) : static_cast<uint16_t>(-1);
    };
    if (auto v = s("filterCutoff", WavetableParam::FilterCutoff); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("filterResonance", WavetableParam::FilterResonance); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("filterMode", WavetableParam::FilterMode); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("attack", WavetableParam::AmpAttack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("decay", WavetableParam::AmpDecay); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("sustain", WavetableParam::AmpSustain); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("release", WavetableParam::AmpRelease); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("wtPosition", WavetableParam::WtPosition); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("wtOctave", WavetableParam::WtOctave); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("wtSemitone", WavetableParam::WtSemitone); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("wtFine", WavetableParam::WtFine); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("wtUnison", WavetableParam::WtUnison); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("wtDetune", WavetableParam::WtDetune); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("filterEnvAmount", WavetableParam::FilterEnvAmount); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("filterAttack", WavetableParam::FilterAttack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("filterDecay", WavetableParam::FilterDecay); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("filterSustain", WavetableParam::FilterSustain); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = s("filterRelease", WavetableParam::FilterRelease); v != static_cast<uint16_t>(-1)) return v;
    return static_cast<uint16_t>(-1);
}

std::string_view WavetableSynthDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<WavetableParam>(localId)) {
    case WavetableParam::FilterCutoff: return "filterCutoff";
    case WavetableParam::FilterResonance: return "filterResonance";
    case WavetableParam::FilterMode: return "filterMode";
    case WavetableParam::AmpAttack: return "attack";
    case WavetableParam::AmpDecay: return "decay";
    case WavetableParam::AmpSustain: return "sustain";
    case WavetableParam::AmpRelease: return "release";
    case WavetableParam::WtPosition: return "wtPosition";
    case WavetableParam::WtOctave: return "wtOctave";
    case WavetableParam::WtSemitone: return "wtSemitone";
    case WavetableParam::WtFine: return "wtFine";
    case WavetableParam::WtUnison: return "wtUnison";
    case WavetableParam::WtDetune: return "wtDetune";
    case WavetableParam::FilterEnvAmount: return "filterEnvAmount";
    case WavetableParam::FilterAttack: return "filterAttack";
    case WavetableParam::FilterDecay: return "filterDecay";
    case WavetableParam::FilterSustain: return "filterSustain";
    case WavetableParam::FilterRelease: return "filterRelease";
    default: return "";
    }
}

std::span<const ParamDescriptor> WavetableSynthDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(WavetableParam::FilterCutoff), "filterCutoff", "Filter Cutoff", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::FilterResonance), "filterResonance", "Filter Res", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::FilterMode), "filterMode", "Filter Mode", 0.0f, 0.0f, 3.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::AmpAttack), "attack", "Attack", 0.01f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::AmpDecay), "decay", "Decay", 0.2f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::AmpSustain), "sustain", "Sustain", 0.8f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(WavetableParam::AmpRelease), "release", "Release", 0.3f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::WtPosition), "wtPosition", "Wavetable Pos", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::WtOctave), "wtOctave", "Octave", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::WtSemitone), "wtSemitone", "Semitone", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::WtFine), "wtFine", "Fine", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::WtUnison), "wtUnison", "Unison", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::WtDetune), "wtDetune", "Detune", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::FilterEnvAmount), "filterEnvAmount", "Filter Env Amt", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::FilterAttack), "filterAttack", "Filter Attack", 0.1f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::FilterDecay), "filterDecay", "Filter Decay", 0.3f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(WavetableParam::FilterSustain), "filterSustain", "Filter Sustain", 0.5f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(WavetableParam::FilterRelease), "filterRelease", "Filter Release", 0.5f, 0.0f, 1.0f, true, true},
    };
    return kParams;
}

bool WavetableSynthDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
