#include "audioapp/devices/PhaseModSynthDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/PhaseModSynthInstance.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

PhaseModSynthParams PhaseModSynthInstance::toPlaybackParams() const {
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
    PhaseModSynthInstance instance;

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

    slot.instance = std::move(instance);
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

    auto& instance = std::get<PhaseModSynthInstance>(slot.instance);

    // Shared filter/amp fields (same IDs as other devices)
    if (parameterId == "filterCutoff" || parameterId == "filterQ" ||
        parameterId == "filterEnvAmount" || parameterId == "filterAttack" ||
        parameterId == "filterDecay" || parameterId == "filterSustain" ||
        parameterId == "filterRelease" || parameterId == "filterKeyTrack") {
        const float clamped = std::clamp(value, 0.0f, 1.0f);
        if (parameterId == "filterCutoff")        instance.filterCutoff = clamped;
        else if (parameterId == "filterQ")         instance.filterQ = clamped;
        else if (parameterId == "filterEnvAmount") instance.filterEnvAmount = clamped;
        else if (parameterId == "filterAttack")    instance.filterAttack = clamped;
        else if (parameterId == "filterDecay")     instance.filterDecay = clamped;
        else if (parameterId == "filterSustain")   instance.filterSustain = clamped;
        else if (parameterId == "filterRelease")   instance.filterRelease = clamped;
        else if (parameterId == "filterKeyTrack")  instance.filterKeyTrack = clamped;
        result.handled = true;
        return result;
    }

    if (parameterId == "attack" || parameterId == "decay" ||
        parameterId == "sustain" || parameterId == "release") {
        const float clamped = std::clamp(value, 0.0f, 1.0f);
        if (parameterId == "attack")       instance.ampAttack = clamped;
        else if (parameterId == "decay")   instance.ampDecay = clamped;
        else if (parameterId == "sustain") instance.ampSustain = clamped;
        else if (parameterId == "release") instance.ampRelease = clamped;
        result.handled = true;
        return result;
    }

    if (parameterId == "filterMode") {
        instance.filterMode = static_cast<float>(std::clamp(
            static_cast<int>(std::lround(value)), 0, 5));
        result.handled = true;
        return result;
    }

    // PM operator params: pmOp{1-4}{ParamName}
    auto setOpParam = [&](int opIdx, const std::string_view& paramSuffix, float val) {
        if (opIdx < 0 || opIdx > 3) return false;
        if (paramSuffix == "Ratio") {
            instance.op[opIdx].ratio = std::clamp(val, 0.0f, 1.0f);
        } else if (paramSuffix == "Fine") {
            instance.op[opIdx].fine = std::clamp(val, 0.0f, 1.0f);
        } else if (paramSuffix == "Level") {
            instance.op[opIdx].level = std::clamp(val, 0.0f, 1.0f);
        } else if (paramSuffix == "Wave") {
            instance.op[opIdx].wave = std::clamp(val, 0.0f, 1.0f);
        } else if (paramSuffix == "Attack") {
            instance.op[opIdx].attack = std::clamp(val, 0.0f, 1.0f);
        } else if (paramSuffix == "Decay") {
            instance.op[opIdx].decay = std::clamp(val, 0.0f, 1.0f);
        } else if (paramSuffix == "Sustain") {
            instance.op[opIdx].sustain = std::clamp(val, 0.0f, 1.0f);
        } else if (paramSuffix == "Release") {
            instance.op[opIdx].release = std::clamp(val, 0.0f, 1.0f);
        } else if (paramSuffix == "VelSense") {
            instance.op[opIdx].velocitySense = std::clamp(val, 0.0f, 1.0f);
        } else if (paramSuffix == "KeyTrack") {
            instance.op[opIdx].keyTrack = std::clamp(val, 0.0f, 1.0f);
        } else {
            return false;
        }
        return true;
    };

    // Check for pmOp{N}{Param} pattern
    const std::string id(parameterId);
    if (id.size() > 7 && id.substr(0, 4) == "pmOp") {
        const int opIdx = id[4] - '1';  // '1'→0, '2'→1, '3'→2, '4'→3
        const std::string_view suffix(std::next(id.data(), 5), id.size() - 5);
        if (setOpParam(opIdx, suffix, value)) {
            result.handled = true;
            return result;
        }
    }

    // PM global params
    if (parameterId == "pmAlgoIndex") {
        instance.algoIndex = std::clamp(static_cast<int>(std::lround(value)), 0, 7);
    } else if (parameterId == "pmFeedback") {
        instance.feedback = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "pmUnisonVoices") {
        instance.unisonVoices = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "pmUnisonDetune") {
        instance.unisonDetune = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "pmGlide") {
        instance.glideMs = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "pmMono") {
        instance.synthMono = value >= 0.5f ? 1.0f : 0.0f;
    } else if (parameterId == "pmLegato") {
        instance.synthLegato = value >= 0.5f ? 1.0f : 0.0f;
    } else if (parameterId == "pmMasterVol") {
        instance.masterVol = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "pmLfoRate") {
        instance.lfoRate = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "pmLfoShape") {
        instance.lfoShape = static_cast<float>(std::clamp(
            static_cast<int>(std::lround(value)), 0, 4));
    } else if (parameterId == "pmLfoAmount") {
        instance.lfoAmount = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "pmLfoDest") {
        instance.lfoDest = std::clamp(static_cast<int>(std::lround(value)), 0, 4);
    } else if (parameterId == "pmVibratoDepth") {
        instance.vibratoDepth = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "pmVibratoRate") {
        instance.vibratoRate = std::clamp(value, 0.0f, 1.0f);
    } else {
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
            auto& inst = std::get<PhaseModSynthInstance>(slot.instance);
            inst.algoIndex = algoIdx;
            return true;
        }
    }
    return false;
}

std::vector<std::string_view> PhaseModSynthDeviceType::modulatableParams() const {
    return {
        "gain", "pmFeedback", "pmLfoRate", "pmLfoAmount",
        "pmVibratoDepth", "pmVibratoRate",
        "filterCutoff", "filterQ", "filterEnvAmount",
        "filterAttack", "filterDecay",
        "attack", "decay", "sustain", "release",
        "pmOp1Level", "pmOp2Level", "pmOp3Level", "pmOp4Level",
        "pmOp1Fine", "pmOp2Fine", "pmOp3Fine", "pmOp4Fine",
        "pmMasterVol",
    };
}

void PhaseModSynthDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                const PlaybackBuildContext&,
                                                DeviceNodePlayback& out) const {
    const auto& inst = std::get<PhaseModSynthInstance>(slot.instance);
    auto params = inst.toPlaybackParams();
    params.gain = slot.gain;
    out.kind = DeviceNodeKind::PhaseModSynth;
    out.params = params;
}

bool PhaseModSynthDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                  const PlaybackBuildContext&,
                                                  LiveInstrumentSnapshot& out) const {
    const auto& inst = std::get<PhaseModSynthInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::PhaseModSynth;
    out.gain = slot.gain;
    out.phaseMod = inst.toPlaybackParams();
    out.phaseMod.gain = slot.gain;
    return true;
}

juce::var PhaseModSynthDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<PhaseModSynthInstance>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);

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
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot PhaseModSynthDeviceType::varToSlot(const juce::var& obj) const {
    DeviceSlot slot;
    if (const auto* object = obj.getDynamicObject()) {
        slot.id = object->getProperty("id").toString().toStdString();
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

            slot.gain = readFloat("gain", 1.0f);
            slot.pan = readFloat("pan", 0.5f);
            slot.bypassed = readFloat("bypass", 0.0f) >= 0.5f;

            PhaseModSynthInstance inst;

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

            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp