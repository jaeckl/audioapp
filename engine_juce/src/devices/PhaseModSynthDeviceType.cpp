#include "audioapp/devices/PhaseModSynthDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/PhaseModSynthModel.hpp"
#include "audioapp/devices/processors/PhaseModSynthProcessor.hpp"

#include <algorithm>
#include <cmath>

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

PhaseModSynthParams PhaseModSynthModel::toPlaybackParams() const {
    PhaseModSynthParams p;
    p.masterVol = masterVol;
    p.algoIndex = algoIndex;
    p.feedback = feedback;
    for (int i = 0; i < 4; ++i) {
        p.operators[i].ratio = phaseModRatioNormToValue(op[i].ratio);
        p.operators[i].fine = phaseModFineNormToCents(op[i].fine);
        p.operators[i].level = op[i].level;
        p.operators[i].wave = op[i].wave;
        p.operators[i].attack = op[i].attack;
        p.operators[i].decay = op[i].decay;
        p.operators[i].sustain = op[i].sustain;
        p.operators[i].release = op[i].release;
        p.operators[i].velocitySense = op[i].velocitySense;
        p.operators[i].keyTrack = op[i].keyTrack;
    }
    // Filter
    p.filterCutoff = filterCutoff;
    p.filterQ = filterQ;
    p.filterMode = static_cast<int>(filterMode);
    p.filterEnvAmount = filterEnvAmount;
    p.filterAttack = filterAttack;
    p.filterDecay = filterDecay;
    p.filterSustain = filterSustain;
    p.filterRelease = filterRelease;
    p.filterKeyTrack = filterKeyTrack;
    // Amp
    p.ampAttack = ampAttack;
    p.ampDecay = ampDecay;
    p.ampSustain = ampSustain;
    p.ampRelease = ampRelease;
    // Performance
    p.glideMs = glideMs;
    p.velocitySensitivity = velocitySensitivity;
    p.unisonVoices = unisonVoices;
    p.unisonDetune = unisonDetune;
    p.synthMono = synthMono;
    p.synthLegato = synthLegato;
    // LFO
    p.lfoRate = lfoRate;
    p.lfoShape = static_cast<int>(lfoShape);
    p.lfoAmount = lfoAmount;
    p.lfoDest = lfoDest;
    p.vibratoDepth = vibratoDepth;
    p.vibratoRate = vibratoRate;
    return p;
}

std::string PhaseModSynthDeviceType::typeId() const {
    return device_types::kPhaseModSynth;
}

DeviceSlot PhaseModSynthDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    PhaseModSynthModel instance;

    // Op 1 — carrier at fundamental
    instance.op[0].ratio = 0.0625f;   // ratio=1
    instance.op[0].fine = 0.5f;        // 0¢
    instance.op[0].level = 0.8f;
    instance.op[0].wave = 0.0f;        // sine
    instance.op[0].attack = 0.01f;
    instance.op[0].decay = 0.3f;
    instance.op[0].sustain = 0.8f;
    instance.op[0].release = 0.4f;
    instance.op[0].velocitySense = 1.0f;
    instance.op[0].keyTrack = 0.0f;

    // Op 2 — modulator at ratio 5
    instance.op[1].ratio = 0.4375f;    // ratio=5
    instance.op[1].fine = 0.5f;
    instance.op[1].level = 0.4f;
    instance.op[1].wave = 0.0f;
    instance.op[1].attack = 0.01f;
    instance.op[1].decay = 0.3f;
    instance.op[1].sustain = 0.8f;
    instance.op[1].release = 0.4f;
    instance.op[1].velocitySense = 1.0f;
    instance.op[1].keyTrack = 0.0f;

    // Op 3 — modulator at ratio 3, off by default
    instance.op[2].ratio = 0.75f;      // ratio=3
    instance.op[2].fine = 0.5f;
    instance.op[2].level = 0.0f;
    instance.op[2].wave = 0.0f;
    instance.op[2].attack = 0.01f;
    instance.op[2].decay = 0.3f;
    instance.op[2].sustain = 0.8f;
    instance.op[2].release = 0.4f;
    instance.op[2].velocitySense = 1.0f;
    instance.op[2].keyTrack = 0.0f;

    // Op 4 — modulator at ratio 2, off by default
    instance.op[3].ratio = 0.375f;     // ratio=2
    instance.op[3].fine = 0.5f;
    instance.op[3].level = 0.0f;
    instance.op[3].wave = 0.0f;
    instance.op[3].attack = 0.01f;
    instance.op[3].decay = 0.3f;
    instance.op[3].sustain = 0.8f;
    instance.op[3].release = 0.4f;
    instance.op[3].velocitySense = 1.0f;
    instance.op[3].keyTrack = 0.0f;

    instance.algoIndex = 0;
    instance.feedback = 0.0f;
    instance.filterCutoff = 0.85f;
    instance.filterQ = 0.25f;
    instance.ampAttack = 0.01f;
    instance.ampSustain = 0.75f;
    instance.lfoRate = 0.2f;
    instance.lfoShape = 0.0f;
    instance.lfoAmount = 0.0f;
    instance.lfoDest = 0;

    slot.config.instance = std::move(instance);

    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult PhaseModSynthDeviceType::setParameter(DeviceSlot& slot,
                                                           std::string_view parameterId,
                                                           float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<PhaseModSynthModel>(slot.config.instance);
    const uint16_t id = paramIdFromString(parameterId);
    switch (static_cast<PhaseModSynthParam>(id)) {
    // Operator 1
    case PhaseModSynthParam::Op1Level:    instance.op[0].level = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op1Fine:     instance.op[0].fine = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op1Attack:   instance.op[0].attack = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op1Decay:    instance.op[0].decay = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op1Sustain:  instance.op[0].sustain = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op1Release:  instance.op[0].release = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op1Ratio:    instance.op[0].ratio = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op1Wave:     instance.op[0].wave = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op1VelSense: instance.op[0].velocitySense = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op1KeyTrack: instance.op[0].keyTrack = std::clamp(value, 0.0f, 1.0f); break;
    // Operator 2
    case PhaseModSynthParam::Op2Level:    instance.op[1].level = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2Fine:     instance.op[1].fine = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2Attack:   instance.op[1].attack = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2Decay:    instance.op[1].decay = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2Sustain:  instance.op[1].sustain = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2Release:  instance.op[1].release = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2Ratio:    instance.op[1].ratio = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2Wave:     instance.op[1].wave = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2VelSense: instance.op[1].velocitySense = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op2KeyTrack: instance.op[1].keyTrack = std::clamp(value, 0.0f, 1.0f); break;
    // Operator 3
    case PhaseModSynthParam::Op3Level:    instance.op[2].level = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3Fine:     instance.op[2].fine = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3Attack:   instance.op[2].attack = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3Decay:    instance.op[2].decay = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3Sustain:  instance.op[2].sustain = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3Release:  instance.op[2].release = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3Ratio:    instance.op[2].ratio = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3Wave:     instance.op[2].wave = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3VelSense: instance.op[2].velocitySense = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op3KeyTrack: instance.op[2].keyTrack = std::clamp(value, 0.0f, 1.0f); break;
    // Operator 4
    case PhaseModSynthParam::Op4Level:    instance.op[3].level = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4Fine:     instance.op[3].fine = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4Attack:   instance.op[3].attack = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4Decay:    instance.op[3].decay = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4Sustain:  instance.op[3].sustain = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4Release:  instance.op[3].release = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4Ratio:    instance.op[3].ratio = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4Wave:     instance.op[3].wave = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4VelSense: instance.op[3].velocitySense = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Op4KeyTrack: instance.op[3].keyTrack = std::clamp(value, 0.0f, 1.0f); break;
    // Filter
    case PhaseModSynthParam::FilterCutoff:    instance.filterCutoff = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::FilterQ:         instance.filterQ = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::FilterEnvAmount: instance.filterEnvAmount = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::FilterAttack:    instance.filterAttack = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::FilterDecay:     instance.filterDecay = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::FilterSustain:   instance.filterSustain = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::FilterRelease:   instance.filterRelease = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::FilterKeyTrack:  instance.filterKeyTrack = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::FilterMode:
        instance.filterMode = static_cast<float>(std::clamp(
            static_cast<int>(std::lround(value)), 0, 5));
        break;
    // Amp
    case PhaseModSynthParam::AmpAttack:   instance.ampAttack = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::AmpDecay:    instance.ampDecay = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::AmpSustain:  instance.ampSustain = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::AmpRelease:  instance.ampRelease = std::clamp(value, 0.0f, 1.0f); break;
    // Global
    case PhaseModSynthParam::Feedback:    instance.feedback = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::MasterVol:   instance.masterVol = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::LfoRate:     instance.lfoRate = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::LfoAmount:   instance.lfoAmount = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::VibratoDepth: instance.vibratoDepth = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::VibratoRate:  instance.vibratoRate = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::AlgoIndex:
        instance.algoIndex = std::clamp(static_cast<int>(std::lround(value)), 0, 7);
        break;
    case PhaseModSynthParam::UnisonVoices: instance.unisonVoices = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::UnisonDetune: instance.unisonDetune = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Glide:        instance.glideMs = std::clamp(value, 0.0f, 1.0f); break;
    case PhaseModSynthParam::Mono:         instance.synthMono = value >= 0.5f ? 1.0f : 0.0f; break;
    case PhaseModSynthParam::Legato:       instance.synthLegato = value >= 0.5f ? 1.0f : 0.0f; break;
    case PhaseModSynthParam::LfoShape:
        instance.lfoShape = static_cast<float>(std::clamp(
            static_cast<int>(std::lround(value)), 0, 4));
        break;
    case PhaseModSynthParam::LfoDest:
        instance.lfoDest = std::clamp(static_cast<int>(std::lround(value)), 0, 4);
        break;
    default:
        return result;
    }

    result.handled = true;
    return result;
}

bool PhaseModSynthDeviceType::setStringParameter(DeviceSlot& slot,
                                                 std::string_view parameterId,
                                                 const std::string& value,
                                                 const PlaybackBuildContext&) const {
    if (parameterId == "pmAlgo") {
        int algoIdx = -1;
        if (value == "stack_4")           algoIdx = 0;
        else if (value == "mod_3_to_1")   algoIdx = 1;
        else if (value == "mod_3_to_2")   algoIdx = 2;
        else if (value == "dual_2_to_1")  algoIdx = 3;
        else if (value == "chain_4")      algoIdx = 4;
        else if (value == "pair_1_to_2")  algoIdx = 5;
        else if (value == "one_to_all")   algoIdx = 6;
        else if (value == "all_mod_fb")   algoIdx = 7;

        if (algoIdx >= 0) {
            auto& inst = std::get<PhaseModSynthModel>(slot.config.instance);
            inst.algoIndex = algoIdx;
            return true;
        }
    }
    return false;
}

std::vector<std::string_view> PhaseModSynthDeviceType::modulatableParams() const {
    return {
        "gain", "pan", "pmFeedback", "pmLfoRate", "pmLfoAmount",
        "pmVibratoDepth", "pmVibratoRate",
        "filterCutoff", "filterQ", "filterEnvAmount",
        "filterAttack", "filterDecay", "filterSustain", "filterRelease", "filterKeyTrack",
        "attack", "decay", "sustain", "release",
        "pmGlide", "pmUnisonDetune",
        "pmOp1Ratio", "pmOp1Fine", "pmOp1Level", "pmOp1Wave", "pmOp1Attack", "pmOp1Decay", "pmOp1Sustain", "pmOp1Release", "pmOp1VelSense", "pmOp1KeyTrack",
        "pmOp2Ratio", "pmOp2Fine", "pmOp2Level", "pmOp2Wave", "pmOp2Attack", "pmOp2Decay", "pmOp2Sustain", "pmOp2Release", "pmOp2VelSense", "pmOp2KeyTrack",
        "pmOp3Ratio", "pmOp3Fine", "pmOp3Level", "pmOp3Wave", "pmOp3Attack", "pmOp3Decay", "pmOp3Sustain", "pmOp3Release", "pmOp3VelSense", "pmOp3KeyTrack",
        "pmOp4Ratio", "pmOp4Fine", "pmOp4Level", "pmOp4Wave", "pmOp4Attack", "pmOp4Decay", "pmOp4Sustain", "pmOp4Release", "pmOp4VelSense", "pmOp4KeyTrack",
        "pmMasterVol"
    };
}

void PhaseModSynthDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                const PlaybackBuildContext&,
                                                DeviceNodePlayback& out) const {
    const auto& inst = std::get<PhaseModSynthModel>(slot.config.instance);
    auto params = inst.toPlaybackParams();
    params.gain = std::get<StereoOutputPanel>(slot.config.outputPanel).gain;
    out.kind = DeviceNodeKind::PhaseModSynth;
    out.params = params;
}

bool PhaseModSynthDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                  const PlaybackBuildContext&,
                                                  LiveInstrumentSnapshot& out) const {
    const auto& inst = std::get<PhaseModSynthModel>(slot.config.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::PhaseModSynth;
    const auto gain = std::get<StereoOutputPanel>(slot.config.outputPanel).gain;
    out.gain = gain;
    out.phaseMod = inst.toPlaybackParams();
    out.phaseMod.gain = gain;
    return true;
}

juce::var PhaseModSynthDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<PhaseModSynthModel>(slot.config.instance);

    // Operator params (pm-prefixed)
    auto setOpJson = [&](int opIdx, const char* prefix) {
        parameters->setProperty(juce::String(prefix) + "Ratio", static_cast<double>(inst.op[opIdx].ratio));
        parameters->setProperty(juce::String(prefix) + "Fine", static_cast<double>(inst.op[opIdx].fine));
        parameters->setProperty(juce::String(prefix) + "Level", static_cast<double>(inst.op[opIdx].level));
        parameters->setProperty(juce::String(prefix) + "Wave", static_cast<double>(inst.op[opIdx].wave));
        parameters->setProperty(juce::String(prefix) + "Attack", static_cast<double>(inst.op[opIdx].attack));
        parameters->setProperty(juce::String(prefix) + "Decay", static_cast<double>(inst.op[opIdx].decay));
        parameters->setProperty(juce::String(prefix) + "Sustain", static_cast<double>(inst.op[opIdx].sustain));
        parameters->setProperty(juce::String(prefix) + "Release", static_cast<double>(inst.op[opIdx].release));
        parameters->setProperty(juce::String(prefix) + "VelSense", static_cast<double>(inst.op[opIdx].velocitySense));
        parameters->setProperty(juce::String(prefix) + "KeyTrack", static_cast<double>(inst.op[opIdx].keyTrack));
    };
    setOpJson(0, "pmOp1");
    setOpJson(1, "pmOp2");
    setOpJson(2, "pmOp3");
    setOpJson(3, "pmOp4");

    // Shared filter fields
    parameters->setProperty("filterCutoff", static_cast<double>(inst.filterCutoff));
    parameters->setProperty("filterQ", static_cast<double>(inst.filterQ));
    parameters->setProperty("filterMode", static_cast<int>(inst.filterMode));
    parameters->setProperty("filterEnvAmount", static_cast<double>(inst.filterEnvAmount));
    parameters->setProperty("filterAttack", static_cast<double>(inst.filterAttack));
    parameters->setProperty("filterDecay", static_cast<double>(inst.filterDecay));
    parameters->setProperty("filterSustain", static_cast<double>(inst.filterSustain));
    parameters->setProperty("filterRelease", static_cast<double>(inst.filterRelease));
    parameters->setProperty("filterKeyTrack", static_cast<double>(inst.filterKeyTrack));

    // Shared amp fields
    parameters->setProperty("attack", static_cast<double>(inst.ampAttack));
    parameters->setProperty("decay", static_cast<double>(inst.ampDecay));
    parameters->setProperty("sustain", static_cast<double>(inst.ampSustain));
    parameters->setProperty("release", static_cast<double>(inst.ampRelease));

    // PM global
    parameters->setProperty("pmAlgoIndex", inst.algoIndex);
    parameters->setProperty("pmFeedback", static_cast<double>(inst.feedback));
    parameters->setProperty("pmUnisonVoices", static_cast<double>(inst.unisonVoices));
    parameters->setProperty("pmUnisonDetune", static_cast<double>(inst.unisonDetune));
    parameters->setProperty("pmGlide", static_cast<double>(inst.glideMs));
    parameters->setProperty("pmMono", static_cast<double>(inst.synthMono));
    parameters->setProperty("pmLegato", static_cast<double>(inst.synthLegato));
    parameters->setProperty("pmMasterVol", static_cast<double>(inst.masterVol));

    // PM LFO
    parameters->setProperty("pmLfoRate", static_cast<double>(inst.lfoRate));
    parameters->setProperty("pmLfoShape", static_cast<double>(inst.lfoShape));
    parameters->setProperty("pmLfoAmount", static_cast<double>(inst.lfoAmount));
    parameters->setProperty("pmLfoDest", inst.lfoDest);
    parameters->setProperty("pmVibratoDepth", static_cast<double>(inst.vibratoDepth));
    parameters->setProperty("pmVibratoRate", static_cast<double>(inst.vibratoRate));

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

DeviceSlot PhaseModSynthDeviceType::varToSlot(const juce::var& obj) const {
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
                if (v.isDouble() || v.isInt() || v.isInt64())
                    return static_cast<int>(std::lround(static_cast<double>(v)));
                return fallback;
            };

            if (!hasPanel) {
                const float oldGain = readFloat("gain", 1.0f);
                const float oldPan = readFloat("pan", 0.5f);
                slot.config.outputPanel = StereoOutputPanel{oldGain, oldPan};
                slot.config.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            }

            PhaseModSynthModel inst;

            auto readOpJson = [&](int opIdx, const char* prefix) {
                const auto r = [&](const char* suffix, float fb) { return readFloat((juce::String(prefix) + suffix).toRawUTF8(), fb); };
                inst.op[opIdx].ratio = r("Ratio", 0.0625f);
                inst.op[opIdx].fine = r("Fine", 0.5f);
                inst.op[opIdx].level = r("Level", 0.8f);
                inst.op[opIdx].wave = r("Wave", 0.0f);
                inst.op[opIdx].attack = r("Attack", 0.01f);
                inst.op[opIdx].decay = r("Decay", 0.3f);
                inst.op[opIdx].sustain = r("Sustain", 0.8f);
                inst.op[opIdx].release = r("Release", 0.4f);
                inst.op[opIdx].velocitySense = r("VelSense", 1.0f);
                inst.op[opIdx].keyTrack = r("KeyTrack", 0.0f);
            };
            readOpJson(0, "pmOp1");
            readOpJson(1, "pmOp2");
            readOpJson(2, "pmOp3");
            readOpJson(3, "pmOp4");

            // Shared filter fields
            inst.filterCutoff = readFloat("filterCutoff", 0.85f);
            inst.filterQ = readFloat("filterQ", 0.25f);
            inst.filterMode = static_cast<float>(readInt("filterMode", 0));
            inst.filterEnvAmount = readFloat("filterEnvAmount", 0.5f);
            inst.filterAttack = readFloat("filterAttack", 0.05f);
            inst.filterDecay = readFloat("filterDecay", 0.35f);
            inst.filterSustain = readFloat("filterSustain", 0.4f);
            inst.filterRelease = readFloat("filterRelease", 0.45f);
            inst.filterKeyTrack = readFloat("filterKeyTrack", 0.0f);

            // Shared amp fields
            inst.ampAttack = readFloat("attack", 0.01f);
            inst.ampDecay = readFloat("decay", 0.3f);
            inst.ampSustain = readFloat("sustain", 0.75f);
            inst.ampRelease = readFloat("release", 0.35f);

            // PM global
            inst.algoIndex = readInt("pmAlgoIndex", 0);
            inst.feedback = readFloat("pmFeedback", 0.0f);
            inst.unisonVoices = readFloat("pmUnisonVoices", 0.0f);
            inst.unisonDetune = readFloat("pmUnisonDetune", 0.15f);
            inst.glideMs = readFloat("pmGlide", 0.0f);
            inst.synthMono = readFloat("pmMono", 0.0f);
            inst.synthLegato = readFloat("pmLegato", 0.0f);
            inst.masterVol = readFloat("pmMasterVol", 0.85f);

            // PM LFO
            inst.lfoRate = readFloat("pmLfoRate", 0.2f);
            inst.lfoShape = readFloat("pmLfoShape", 0.0f);
            inst.lfoAmount = readFloat("pmLfoAmount", 0.0f);
            inst.lfoDest = readInt("pmLfoDest", 0);
            inst.vibratoDepth = readFloat("pmVibratoDepth", 0.0f);
            inst.vibratoRate = readFloat("pmVibratoRate", 0.3f);

            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* PhaseModSynthDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<PhaseModSynthProcessor>();
}

DeviceNodeKind PhaseModSynthDeviceType::kind() const noexcept { return DeviceNodeKind::PhaseModSynth; }

uint16_t PhaseModSynthDeviceType::paramIdFromString(std::string_view name) const noexcept {
    auto pm = [&](std::string_view n, PhaseModSynthParam pid) -> uint16_t {
        return name == n ? static_cast<uint16_t>(pid) : static_cast<uint16_t>(-1);
    };
    if (auto v = pm("pmOp1Level", PhaseModSynthParam::Op1Level); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp1Fine", PhaseModSynthParam::Op1Fine); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp1Attack", PhaseModSynthParam::Op1Attack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp1Decay", PhaseModSynthParam::Op1Decay); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp1Sustain", PhaseModSynthParam::Op1Sustain); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp1Release", PhaseModSynthParam::Op1Release); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp1Ratio", PhaseModSynthParam::Op1Ratio); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp1Wave", PhaseModSynthParam::Op1Wave); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp1VelSense", PhaseModSynthParam::Op1VelSense); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp1KeyTrack", PhaseModSynthParam::Op1KeyTrack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp2Level", PhaseModSynthParam::Op2Level); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp2Fine", PhaseModSynthParam::Op2Fine); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp2Attack", PhaseModSynthParam::Op2Attack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp2Decay", PhaseModSynthParam::Op2Decay); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp2Sustain", PhaseModSynthParam::Op2Sustain); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp2Release", PhaseModSynthParam::Op2Release); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp2Ratio", PhaseModSynthParam::Op2Ratio); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp2Wave", PhaseModSynthParam::Op2Wave); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp2VelSense", PhaseModSynthParam::Op2VelSense); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp2KeyTrack", PhaseModSynthParam::Op2KeyTrack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp3Level", PhaseModSynthParam::Op3Level); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp3Fine", PhaseModSynthParam::Op3Fine); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp3Attack", PhaseModSynthParam::Op3Attack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp3Decay", PhaseModSynthParam::Op3Decay); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp3Sustain", PhaseModSynthParam::Op3Sustain); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp3Release", PhaseModSynthParam::Op3Release); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp3Ratio", PhaseModSynthParam::Op3Ratio); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp3Wave", PhaseModSynthParam::Op3Wave); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp3VelSense", PhaseModSynthParam::Op3VelSense); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp3KeyTrack", PhaseModSynthParam::Op3KeyTrack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp4Level", PhaseModSynthParam::Op4Level); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp4Fine", PhaseModSynthParam::Op4Fine); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp4Attack", PhaseModSynthParam::Op4Attack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp4Decay", PhaseModSynthParam::Op4Decay); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp4Sustain", PhaseModSynthParam::Op4Sustain); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp4Release", PhaseModSynthParam::Op4Release); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp4Ratio", PhaseModSynthParam::Op4Ratio); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp4Wave", PhaseModSynthParam::Op4Wave); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp4VelSense", PhaseModSynthParam::Op4VelSense); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmOp4KeyTrack", PhaseModSynthParam::Op4KeyTrack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("filterCutoff", PhaseModSynthParam::FilterCutoff); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("filterQ", PhaseModSynthParam::FilterQ); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("filterEnvAmount", PhaseModSynthParam::FilterEnvAmount); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("filterMode", PhaseModSynthParam::FilterMode); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("filterAttack", PhaseModSynthParam::FilterAttack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("filterDecay", PhaseModSynthParam::FilterDecay); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("filterSustain", PhaseModSynthParam::FilterSustain); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("filterRelease", PhaseModSynthParam::FilterRelease); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("filterKeyTrack", PhaseModSynthParam::FilterKeyTrack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("attack", PhaseModSynthParam::AmpAttack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("decay", PhaseModSynthParam::AmpDecay); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("sustain", PhaseModSynthParam::AmpSustain); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("release", PhaseModSynthParam::AmpRelease); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmFeedback", PhaseModSynthParam::Feedback); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmMasterVol", PhaseModSynthParam::MasterVol); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmLfoRate", PhaseModSynthParam::LfoRate); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmLfoAmount", PhaseModSynthParam::LfoAmount); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmVibratoDepth", PhaseModSynthParam::VibratoDepth); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmVibratoRate", PhaseModSynthParam::VibratoRate); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmAlgoIndex", PhaseModSynthParam::AlgoIndex); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmUnisonVoices", PhaseModSynthParam::UnisonVoices); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmUnisonDetune", PhaseModSynthParam::UnisonDetune); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmGlide", PhaseModSynthParam::Glide); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmMono", PhaseModSynthParam::Mono); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmLegato", PhaseModSynthParam::Legato); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmLfoShape", PhaseModSynthParam::LfoShape); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = pm("pmLfoDest", PhaseModSynthParam::LfoDest); v != static_cast<uint16_t>(-1)) return v;
    return static_cast<uint16_t>(-1);
}

std::string_view PhaseModSynthDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<PhaseModSynthParam>(localId)) {
    case PhaseModSynthParam::Op1Level: return "pmOp1Level";
    case PhaseModSynthParam::Op1Fine: return "pmOp1Fine";
    case PhaseModSynthParam::Op1Attack: return "pmOp1Attack";
    case PhaseModSynthParam::Op1Decay: return "pmOp1Decay";
    case PhaseModSynthParam::Op1Sustain: return "pmOp1Sustain";
    case PhaseModSynthParam::Op1Release: return "pmOp1Release";
    case PhaseModSynthParam::Op1Ratio: return "pmOp1Ratio";
    case PhaseModSynthParam::Op1Wave: return "pmOp1Wave";
    case PhaseModSynthParam::Op1VelSense: return "pmOp1VelSense";
    case PhaseModSynthParam::Op1KeyTrack: return "pmOp1KeyTrack";
    case PhaseModSynthParam::Op2Level: return "pmOp2Level";
    case PhaseModSynthParam::Op2Fine: return "pmOp2Fine";
    case PhaseModSynthParam::Op2Attack: return "pmOp2Attack";
    case PhaseModSynthParam::Op2Decay: return "pmOp2Decay";
    case PhaseModSynthParam::Op2Sustain: return "pmOp2Sustain";
    case PhaseModSynthParam::Op2Release: return "pmOp2Release";
    case PhaseModSynthParam::Op2Ratio: return "pmOp2Ratio";
    case PhaseModSynthParam::Op2Wave: return "pmOp2Wave";
    case PhaseModSynthParam::Op2VelSense: return "pmOp2VelSense";
    case PhaseModSynthParam::Op2KeyTrack: return "pmOp2KeyTrack";
    case PhaseModSynthParam::Op3Level: return "pmOp3Level";
    case PhaseModSynthParam::Op3Fine: return "pmOp3Fine";
    case PhaseModSynthParam::Op3Attack: return "pmOp3Attack";
    case PhaseModSynthParam::Op3Decay: return "pmOp3Decay";
    case PhaseModSynthParam::Op3Sustain: return "pmOp3Sustain";
    case PhaseModSynthParam::Op3Release: return "pmOp3Release";
    case PhaseModSynthParam::Op3Ratio: return "pmOp3Ratio";
    case PhaseModSynthParam::Op3Wave: return "pmOp3Wave";
    case PhaseModSynthParam::Op3VelSense: return "pmOp3VelSense";
    case PhaseModSynthParam::Op3KeyTrack: return "pmOp3KeyTrack";
    case PhaseModSynthParam::Op4Level: return "pmOp4Level";
    case PhaseModSynthParam::Op4Fine: return "pmOp4Fine";
    case PhaseModSynthParam::Op4Attack: return "pmOp4Attack";
    case PhaseModSynthParam::Op4Decay: return "pmOp4Decay";
    case PhaseModSynthParam::Op4Sustain: return "pmOp4Sustain";
    case PhaseModSynthParam::Op4Release: return "pmOp4Release";
    case PhaseModSynthParam::Op4Ratio: return "pmOp4Ratio";
    case PhaseModSynthParam::Op4Wave: return "pmOp4Wave";
    case PhaseModSynthParam::Op4VelSense: return "pmOp4VelSense";
    case PhaseModSynthParam::Op4KeyTrack: return "pmOp4KeyTrack";
    case PhaseModSynthParam::FilterCutoff: return "filterCutoff";
    case PhaseModSynthParam::FilterQ: return "filterQ";
    case PhaseModSynthParam::FilterEnvAmount: return "filterEnvAmount";
    case PhaseModSynthParam::FilterMode: return "filterMode";
    case PhaseModSynthParam::FilterAttack: return "filterAttack";
    case PhaseModSynthParam::FilterDecay: return "filterDecay";
    case PhaseModSynthParam::FilterSustain: return "filterSustain";
    case PhaseModSynthParam::FilterRelease: return "filterRelease";
    case PhaseModSynthParam::FilterKeyTrack: return "filterKeyTrack";
    case PhaseModSynthParam::AmpAttack: return "attack";
    case PhaseModSynthParam::AmpDecay: return "decay";
    case PhaseModSynthParam::AmpSustain: return "sustain";
    case PhaseModSynthParam::AmpRelease: return "release";
    case PhaseModSynthParam::Feedback: return "pmFeedback";
    case PhaseModSynthParam::MasterVol: return "pmMasterVol";
    case PhaseModSynthParam::LfoRate: return "pmLfoRate";
    case PhaseModSynthParam::LfoAmount: return "pmLfoAmount";
    case PhaseModSynthParam::VibratoDepth: return "pmVibratoDepth";
    case PhaseModSynthParam::VibratoRate: return "pmVibratoRate";
    case PhaseModSynthParam::AlgoIndex: return "pmAlgoIndex";
    case PhaseModSynthParam::UnisonVoices: return "pmUnisonVoices";
    case PhaseModSynthParam::UnisonDetune: return "pmUnisonDetune";
    case PhaseModSynthParam::Glide: return "pmGlide";
    case PhaseModSynthParam::Mono: return "pmMono";
    case PhaseModSynthParam::Legato: return "pmLegato";
    case PhaseModSynthParam::LfoShape: return "pmLfoShape";
    case PhaseModSynthParam::LfoDest: return "pmLfoDest";
    default: return "";
    }
}

std::span<const ParamDescriptor> PhaseModSynthDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(PhaseModSynthParam::Op1Level), "pmOp1Level", "Op1 Level", 0.8f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op1Fine), "pmOp1Fine", "Op1 Fine", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op1Attack), "pmOp1Attack", "Op1 Attack", 0.01f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op1Decay), "pmOp1Decay", "Op1 Decay", 0.3f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op1Sustain), "pmOp1Sustain", "Op1 Sustain", 0.8f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(PhaseModSynthParam::Op1Release), "pmOp1Release", "Op1 Release", 0.4f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op1Ratio), "pmOp1Ratio", "Op1 Ratio", 0.0625f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op1Wave), "pmOp1Wave", "Op1 Wave", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op1VelSense), "pmOp1VelSense", "Op1 Vel Sense", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op1KeyTrack), "pmOp1KeyTrack", "Op1 Key Track", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op2Level), "pmOp2Level", "Op2 Level", 0.4f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op2Fine), "pmOp2Fine", "Op2 Fine", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op2Attack), "pmOp2Attack", "Op2 Attack", 0.01f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op2Decay), "pmOp2Decay", "Op2 Decay", 0.3f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op2Sustain), "pmOp2Sustain", "Op2 Sustain", 0.8f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(PhaseModSynthParam::Op2Release), "pmOp2Release", "Op2 Release", 0.4f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op2Ratio), "pmOp2Ratio", "Op2 Ratio", 0.4375f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op2Wave), "pmOp2Wave", "Op2 Wave", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op2VelSense), "pmOp2VelSense", "Op2 Vel Sense", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op2KeyTrack), "pmOp2KeyTrack", "Op2 Key Track", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op3Level), "pmOp3Level", "Op3 Level", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op3Fine), "pmOp3Fine", "Op3 Fine", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op3Attack), "pmOp3Attack", "Op3 Attack", 0.01f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op3Decay), "pmOp3Decay", "Op3 Decay", 0.3f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op3Sustain), "pmOp3Sustain", "Op3 Sustain", 0.8f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(PhaseModSynthParam::Op3Release), "pmOp3Release", "Op3 Release", 0.4f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op3Ratio), "pmOp3Ratio", "Op3 Ratio", 0.75f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op3Wave), "pmOp3Wave", "Op3 Wave", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op3VelSense), "pmOp3VelSense", "Op3 Vel Sense", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op3KeyTrack), "pmOp3KeyTrack", "Op3 Key Track", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op4Level), "pmOp4Level", "Op4 Level", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op4Fine), "pmOp4Fine", "Op4 Fine", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op4Attack), "pmOp4Attack", "Op4 Attack", 0.01f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op4Decay), "pmOp4Decay", "Op4 Decay", 0.3f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op4Sustain), "pmOp4Sustain", "Op4 Sustain", 0.8f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(PhaseModSynthParam::Op4Release), "pmOp4Release", "Op4 Release", 0.4f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op4Ratio), "pmOp4Ratio", "Op4 Ratio", 0.375f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op4Wave), "pmOp4Wave", "Op4 Wave", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op4VelSense), "pmOp4VelSense", "Op4 Vel Sense", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Op4KeyTrack), "pmOp4KeyTrack", "Op4 Key Track", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::FilterCutoff), "filterCutoff", "Filter Cutoff", 0.85f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::FilterQ), "filterQ", "Filter Q", 0.25f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::FilterEnvAmount), "filterEnvAmount", "Filter Env", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::FilterMode), "filterMode", "Filter Mode", 0.0f, 0.0f, 5.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::FilterAttack), "filterAttack", "Filter Attack", 0.05f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::FilterDecay), "filterDecay", "Filter Decay", 0.35f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::FilterSustain), "filterSustain", "Filter Sustain", 0.4f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(PhaseModSynthParam::FilterRelease), "filterRelease", "Filter Release", 0.45f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::FilterKeyTrack), "filterKeyTrack", "Filter Key Track", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::AmpAttack), "attack", "Attack", 0.01f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::AmpDecay), "decay", "Decay", 0.3f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::AmpSustain), "sustain", "Sustain", 0.75f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(PhaseModSynthParam::AmpRelease), "release", "Release", 0.35f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Feedback), "pmFeedback", "Feedback", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::MasterVol), "pmMasterVol", "Master Vol", 0.85f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::LfoRate), "pmLfoRate", "LFO Rate", 0.2f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::LfoAmount), "pmLfoAmount", "LFO Amount", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::VibratoDepth), "pmVibratoDepth", "Vibrato Depth", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::VibratoRate), "pmVibratoRate", "Vibrato Rate", 0.3f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::AlgoIndex), "pmAlgoIndex", "Algorithm", 0.0f, 0.0f, 7.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::UnisonVoices), "pmUnisonVoices", "Unison Voices", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::UnisonDetune), "pmUnisonDetune", "Unison Detune", 0.15f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Glide), "pmGlide", "Glide", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::Mono), "pmMono", "Mono", 0.0f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(PhaseModSynthParam::Legato), "pmLegato", "Legato", 0.0f, 0.0f, 1.0f, true, false},
        {static_cast<uint16_t>(PhaseModSynthParam::LfoShape), "pmLfoShape", "LFO Shape", 0.0f, 0.0f, 4.0f, true, true},
        {static_cast<uint16_t>(PhaseModSynthParam::LfoDest), "pmLfoDest", "LFO Dest", 0.0f, 0.0f, 4.0f, true, true},
    };
    return kParams;
}

bool PhaseModSynthDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
