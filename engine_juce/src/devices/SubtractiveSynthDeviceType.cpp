#include "audioapp/devices/SubtractiveSynthDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"
#include "audioapp/devices/processors/SubtractiveSynthProcessor.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

std::string SubtractiveSynthDeviceType::typeId() const {
    return device_types::kSubtractiveSynth;
}

DeviceSlot SubtractiveSynthDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    SubtractiveSynthParams instance;
    instance.ampAttack = 0.02f;
    instance.ampDecay = 0.25f;
    instance.ampSustain = 0.75f;
    instance.ampRelease = 0.35f;
    instance.filterCutoff = 0.75f;
    instance.filterQ = 0.2f;
    instance.osc1Shape = 0.5f;
    instance.osc2Shape = 0.5f;
    instance.filterEnvAmount = 0.5f;
    instance.filterAttack = 0.05f;
    instance.filterDecay = 0.35f;
    instance.filterSustain = 0.4f;
    instance.filterRelease = 0.45f;
    instance.velocitySensitivity = 1.0f;
    slot.config.instance = std::move(instance);

    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult SubtractiveSynthDeviceType::setParameter(DeviceSlot& slot,
                                                               std::string_view parameterId,
                                                               float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    auto& instance = std::get<SubtractiveSynthParams>(slot.config.instance);
    if (parameterId == "attack" || parameterId == "decay" || parameterId == "release" ||
        parameterId == "sustain") {
        const float clamped = std::clamp(value, 0.0f, 1.0f);
        if (parameterId == "attack") {
            instance.ampAttack = clamped;
        } else if (parameterId == "decay") {
            instance.ampDecay = clamped;
        } else if (parameterId == "release") {
            instance.ampRelease = clamped;
        } else {
            instance.ampSustain = clamped;
        }
    } else if (parameterId == "filterCutoff" || parameterId == "filterQ" ||
               parameterId == "filterEnvAmount" || parameterId == "filterAttack" ||
               parameterId == "filterDecay" || parameterId == "filterSustain" ||
               parameterId == "filterRelease" || parameterId == "osc1Octave" ||
               parameterId == "osc1Semi" || parameterId == "osc1Detune" ||
               parameterId == "osc2Octave" || parameterId == "osc2Semi" ||
               parameterId == "osc2Detune" || parameterId == "oscMix" ||
               parameterId == "osc1Sync" || parameterId == "osc2Sync" ||
               parameterId == "noiseLevel" || parameterId == "unisonVoices" ||
               parameterId == "unisonDetune" || parameterId == "glideMs" ||
               parameterId == "velocitySensitivity" || parameterId == "preHpCutoff" ||
               parameterId == "preHpRes" || parameterId == "preDrive" ||
               parameterId == "mixFeedback" || parameterId == "globalPitch" ||
               parameterId == "filterKeyTrack" || parameterId == "filterDrive" ||
               parameterId == "filterShaper" || parameterId == "filterFm" ||
               parameterId == "synthLegato" || parameterId == "synthMono") {
        const float clamped = std::clamp(value, 0.0f, 1.0f);
        if (parameterId == "filterCutoff") {
            instance.filterCutoff = clamped;
        } else if (parameterId == "filterQ") {
            instance.filterQ = clamped;
        } else if (parameterId == "filterEnvAmount") {
            instance.filterEnvAmount = clamped;
        } else if (parameterId == "filterAttack") {
            instance.filterAttack = clamped;
        } else if (parameterId == "filterDecay") {
            instance.filterDecay = clamped;
        } else if (parameterId == "filterSustain") {
            instance.filterSustain = clamped;
        } else if (parameterId == "filterRelease") {
            instance.filterRelease = clamped;
        } else if (parameterId == "osc1Octave") {
            instance.osc1Octave = clamped;
        } else if (parameterId == "osc1Semi") {
            instance.osc1Semi = clamped;
        } else if (parameterId == "osc1Detune") {
            instance.osc1Detune = clamped;
        } else if (parameterId == "osc2Octave") {
            instance.osc2Octave = clamped;
        } else if (parameterId == "osc2Semi") {
            instance.osc2Semi = clamped;
        } else if (parameterId == "osc2Detune") {
            instance.osc2Detune = clamped;
        } else if (parameterId == "oscMix") {
            instance.oscMix = clamped;
        } else if (parameterId == "osc1Sync") {
            instance.osc1Sync = clamped;
        } else if (parameterId == "osc2Sync") {
            instance.osc2Sync = clamped;
        } else if (parameterId == "noiseLevel") {
            instance.noiseLevel = clamped;
        } else if (parameterId == "unisonVoices") {
            instance.unisonVoices = clamped;
        } else if (parameterId == "unisonDetune") {
            instance.unisonDetune = clamped;
        } else if (parameterId == "glideMs") {
            instance.glideMs = clamped;
        } else if (parameterId == "velocitySensitivity") {
            instance.velocitySensitivity = clamped;
        } else if (parameterId == "preHpCutoff") {
            instance.preHpCutoff = clamped;
        } else if (parameterId == "preHpRes") {
            instance.preHpRes = clamped;
        } else if (parameterId == "preDrive") {
            instance.preDrive = clamped;
        } else if (parameterId == "mixFeedback") {
            instance.mixFeedback = clamped;
        } else if (parameterId == "globalPitch") {
            instance.globalPitch = clamped;
        } else if (parameterId == "filterKeyTrack") {
            instance.filterKeyTrack = clamped;
        } else if (parameterId == "filterDrive") {
            instance.filterDrive = clamped;
        } else if (parameterId == "filterShaper") {
            instance.filterShaper = clamped;
        } else if (parameterId == "filterFm") {
            instance.filterFm = clamped;
        } else if (parameterId == "synthLegato") {
            instance.synthLegato = clamped;
        } else {
            instance.synthMono = clamped;
        }
    } else if (parameterId == "osc1Shape") {
        instance.osc1Shape = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "osc2Shape") {
        instance.osc2Shape = std::clamp(value, 0.0f, 1.0f);
    } else if (parameterId == "oscMixMode") {
        instance.oscMixMode = std::clamp(static_cast<int>(std::lround(value)), 0, 4);
    } else if (parameterId == "filterMode") {
        instance.filterMode = std::clamp(static_cast<int>(std::lround(value)), 0, 5);
    } else if (parameterId == "filterShaperMode") {
        instance.filterShaperMode = std::clamp(static_cast<int>(std::lround(value)), 0, 3);
    } else {
        return result;
    }

    result.handled = true;
    return result;
}

bool SubtractiveSynthDeviceType::setStringParameter(DeviceSlot&,
                                                    std::string_view,
                                                    const std::string&,
                                                    const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> SubtractiveSynthDeviceType::modulatableParams() const {
    return {
        "gain", "pan", "filterCutoff", "filterQ", "filterMode", "attack", "decay", "sustain",
        "release", "osc1Shape", "osc2Shape", "osc1Octave", "osc1Semi", "osc1Detune", "osc2Octave",
        "osc2Semi", "osc2Detune", "oscMix", "osc1Sync", "osc2Sync", "noiseLevel", "oscMixMode",
        "unisonVoices", "unisonDetune", "filterEnvAmount", "filterAttack", "filterDecay",
        "filterSustain", "filterRelease", "glideMs", "velocitySensitivity", "preHpCutoff",
        "preHpRes", "preDrive", "mixFeedback", "globalPitch", "filterKeyTrack", "filterDrive",
        "filterShaper", "filterFm", "filterShaperMode", "synthLegato", "synthMono",
    };
}

void SubtractiveSynthDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                                   const PlaybackBuildContext&,
                                                   DeviceNodePlayback& out) const {
    auto params = std::get<SubtractiveSynthParams>(slot.config.instance);
    params.gain = std::get<StereoOutputPanel>(slot.config.outputPanel).gain;
    out.kind = DeviceNodeKind::SubtractiveSynth;
    out.params = params;
}

bool SubtractiveSynthDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                                     const PlaybackBuildContext&,
                                                     LiveInstrumentSnapshot& out) const {
    auto params = std::get<SubtractiveSynthParams>(slot.config.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::SubtractiveSynth;
    const auto gain = std::get<StereoOutputPanel>(slot.config.outputPanel).gain;
    out.gain = gain;
    out.subtractive = params;
    out.subtractive.gain = gain;
    return true;
}

juce::var SubtractiveSynthDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<SubtractiveSynthParams>(slot.config.instance);

    // ADSR
    parameters->setProperty("attack", static_cast<double>(inst.ampAttack));
    parameters->setProperty("decay", static_cast<double>(inst.ampDecay));
    parameters->setProperty("sustain", static_cast<double>(inst.ampSustain));
    parameters->setProperty("release", static_cast<double>(inst.ampRelease));

    // Filter
    parameters->setProperty("filterCutoff", static_cast<double>(inst.filterCutoff));
    parameters->setProperty("filterQ", static_cast<double>(inst.filterQ));
    parameters->setProperty("filterEnvAmount", static_cast<double>(inst.filterEnvAmount));
    parameters->setProperty("filterAttack", static_cast<double>(inst.filterAttack));
    parameters->setProperty("filterDecay", static_cast<double>(inst.filterDecay));
    parameters->setProperty("filterSustain", static_cast<double>(inst.filterSustain));
    parameters->setProperty("filterRelease", static_cast<double>(inst.filterRelease));
    // Filter mode — stored as int, cast to double for JSON
    parameters->setProperty("filterMode", inst.filterMode);
    parameters->setProperty("filterKeyTrack", static_cast<double>(inst.filterKeyTrack));
    parameters->setProperty("filterDrive", static_cast<double>(inst.filterDrive));
    parameters->setProperty("filterShaper", static_cast<double>(inst.filterShaper));
    parameters->setProperty("filterFm", static_cast<double>(inst.filterFm));
    parameters->setProperty("filterShaperMode", inst.filterShaperMode);

    // Osc1
    parameters->setProperty("osc1Shape", static_cast<double>(inst.osc1Shape));
    parameters->setProperty("osc1Octave", static_cast<double>(inst.osc1Octave));
    parameters->setProperty("osc1Semi", static_cast<double>(inst.osc1Semi));
    parameters->setProperty("osc1Detune", static_cast<double>(inst.osc1Detune));
    parameters->setProperty("osc1Sync", static_cast<double>(inst.osc1Sync));

    // Osc2
    parameters->setProperty("osc2Shape", static_cast<double>(inst.osc2Shape));
    parameters->setProperty("osc2Octave", static_cast<double>(inst.osc2Octave));
    parameters->setProperty("osc2Semi", static_cast<double>(inst.osc2Semi));
    parameters->setProperty("osc2Detune", static_cast<double>(inst.osc2Detune));
    parameters->setProperty("osc2Sync", static_cast<double>(inst.osc2Sync));

    // Mix
    parameters->setProperty("oscMix", static_cast<double>(inst.oscMix));
    parameters->setProperty("oscMixMode", inst.oscMixMode);
    parameters->setProperty("noiseLevel", static_cast<double>(inst.noiseLevel));

    // Unison
    parameters->setProperty("unisonVoices", static_cast<double>(inst.unisonVoices));
    parameters->setProperty("unisonDetune", static_cast<double>(inst.unisonDetune));

    // Other
    parameters->setProperty("glideMs", static_cast<double>(inst.glideMs));
    parameters->setProperty("velocitySensitivity", static_cast<double>(inst.velocitySensitivity));
    parameters->setProperty("preHpCutoff", static_cast<double>(inst.preHpCutoff));
    parameters->setProperty("preHpRes", static_cast<double>(inst.preHpRes));
    parameters->setProperty("preDrive", static_cast<double>(inst.preDrive));
    parameters->setProperty("mixFeedback", static_cast<double>(inst.mixFeedback));
    parameters->setProperty("globalPitch", static_cast<double>(inst.globalPitch));
    parameters->setProperty("synthLegato", static_cast<double>(inst.synthLegato));
    parameters->setProperty("synthMono", static_cast<double>(inst.synthMono));

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

DeviceSlot SubtractiveSynthDeviceType::varToSlot(const juce::var& obj) const {
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

            SubtractiveSynthParams inst;

            // ADSR
            inst.ampAttack = readFloat("attack", 0.01f);
            inst.ampDecay = readFloat("decay", 0.3f);
            inst.ampSustain = readFloat("sustain", 0.7f);
            inst.ampRelease = readFloat("release", 0.4f);

            // Filter
            inst.filterCutoff = readFloat("filterCutoff", 1.0f);
            inst.filterQ = readFloat("filterQ", 0.35f);
            inst.filterEnvAmount = readFloat("filterEnvAmount", 0.5f);
            inst.filterAttack = readFloat("filterAttack", 0.05f);
            inst.filterDecay = readFloat("filterDecay", 0.35f);
            inst.filterSustain = readFloat("filterSustain", 0.4f);
            inst.filterRelease = readFloat("filterRelease", 0.45f);
            inst.filterMode = readInt("filterMode", 0);
            inst.filterKeyTrack = readFloat("filterKeyTrack", 0.0f);
            inst.filterDrive = readFloat("filterDrive", 0.0f);
            inst.filterShaper = readFloat("filterShaper", 0.0f);
            inst.filterFm = readFloat("filterFm", 0.0f);
            inst.filterShaperMode = readInt("filterShaperMode", 1);

            // Osc1 (with legacy rename)
            if (p->hasProperty("osc1Shape")) {
                inst.osc1Shape = readFloat("osc1Shape", 0.5f);
            } else {
                const int legacyWave = readInt("osc1Wave", 2);
                inst.osc1Shape = static_cast<float>(legacyWave) / 4.0f;
            }
            inst.osc1Octave = readFloat("osc1Octave", 0.5f);
            inst.osc1Semi = readFloat("osc1Semi", 0.0f);
            inst.osc1Detune = readFloat("osc1Detune", 0.5f);
            inst.osc1Sync = readFloat("osc1Sync", 0.0f);

            // Osc2 (with legacy rename)
            if (p->hasProperty("osc2Shape")) {
                inst.osc2Shape = readFloat("osc2Shape", 0.5f);
            } else {
                const int legacyWave = readInt("osc2Wave", 2);
                inst.osc2Shape = static_cast<float>(legacyWave) / 4.0f;
            }
            inst.osc2Octave = readFloat("osc2Octave", 0.5f);
            inst.osc2Semi = readFloat("osc2Semi", 0.0f);
            inst.osc2Detune = readFloat("osc2Detune", 0.5f);
            inst.osc2Sync = readFloat("osc2Sync", 0.0f);

            // Osc mix (with legacy rename)
            if (p->hasProperty("oscMix")) {
                inst.oscMix = readFloat("oscMix", 0.37f);
            } else {
                const float osc1Level = readFloat("osc1Level", 0.85f);
                const float osc2Level = readFloat("osc2Level", 0.5f);
                const float sum = osc1Level + osc2Level;
                inst.oscMix = sum > 0.001f ? osc2Level / sum : 0.37f;
            }
            inst.oscMixMode = readInt("oscMixMode", 0);
            inst.noiseLevel = readFloat("noiseLevel", 0.0f);

            // Unison
            inst.unisonVoices = readFloat("unisonVoices", 0.0f);
            inst.unisonDetune = readFloat("unisonDetune", 0.35f);

            // Other
            inst.glideMs = readFloat("glideMs", 0.0f);
            inst.velocitySensitivity = readFloat("velocitySensitivity", 1.0f);
            inst.preHpCutoff = readFloat("preHpCutoff", 0.0f);
            inst.preHpRes = readFloat("preHpRes", 0.2f);
            inst.preDrive = readFloat("preDrive", 0.0f);
            inst.mixFeedback = readFloat("mixFeedback", 0.0f);
            inst.globalPitch = readFloat("globalPitch", 0.5f);
            inst.synthLegato = readFloat("synthLegato", 0.0f);
            inst.synthMono = readFloat("synthMono", 0.0f);

            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* SubtractiveSynthDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<SubtractiveSynthProcessor>();
}

DeviceNodeKind SubtractiveSynthDeviceType::kind() const noexcept { return DeviceNodeKind::SubtractiveSynth; }

uint16_t SubtractiveSynthDeviceType::paramIdFromString(std::string_view name) const noexcept {
    auto s = [&](std::string_view n, SubtractiveParam pid) -> uint16_t {
        return name == n ? static_cast<uint16_t>(pid) : 0;
    };
    if (auto v = s("filterCutoff", SubtractiveParam::FilterCutoff)) return v;
    if (auto v = s("filterQ", SubtractiveParam::FilterQ)) return v;
    if (auto v = s("filterMode", SubtractiveParam::FilterMode)) return v;
    if (auto v = s("attack", SubtractiveParam::AmpAttack)) return v;
    if (auto v = s("decay", SubtractiveParam::AmpDecay)) return v;
    if (auto v = s("sustain", SubtractiveParam::AmpSustain)) return v;
    if (auto v = s("release", SubtractiveParam::AmpRelease)) return v;
    if (auto v = s("osc1Shape", SubtractiveParam::Osc1Shape)) return v;
    if (auto v = s("osc2Shape", SubtractiveParam::Osc2Shape)) return v;
    if (auto v = s("osc1Octave", SubtractiveParam::Osc1Octave)) return v;
    if (auto v = s("osc1Semi", SubtractiveParam::Osc1Semi)) return v;
    if (auto v = s("osc1Detune", SubtractiveParam::Osc1Detune)) return v;
    if (auto v = s("osc2Octave", SubtractiveParam::Osc2Octave)) return v;
    if (auto v = s("osc2Semi", SubtractiveParam::Osc2Semi)) return v;
    if (auto v = s("osc2Detune", SubtractiveParam::Osc2Detune)) return v;
    if (auto v = s("oscMix", SubtractiveParam::OscMix)) return v;
    if (auto v = s("oscMixMode", SubtractiveParam::OscMixMode)) return v;
    if (auto v = s("osc1Sync", SubtractiveParam::Osc1Sync)) return v;
    if (auto v = s("osc2Sync", SubtractiveParam::Osc2Sync)) return v;
    if (auto v = s("noiseLevel", SubtractiveParam::NoiseLevel)) return v;
    if (auto v = s("unisonVoices", SubtractiveParam::UnisonVoices)) return v;
    if (auto v = s("unisonDetune", SubtractiveParam::UnisonDetune)) return v;
    if (auto v = s("filterEnvAmount", SubtractiveParam::FilterEnvAmount)) return v;
    if (auto v = s("filterAttack", SubtractiveParam::FilterAttack)) return v;
    if (auto v = s("filterDecay", SubtractiveParam::FilterDecay)) return v;
    if (auto v = s("filterSustain", SubtractiveParam::FilterSustain)) return v;
    if (auto v = s("filterRelease", SubtractiveParam::FilterRelease)) return v;
    if (auto v = s("glideMs", SubtractiveParam::GlideMs)) return v;
    if (auto v = s("velocitySensitivity", SubtractiveParam::VelocitySensitivity)) return v;
    if (auto v = s("preHpCutoff", SubtractiveParam::PreHpCutoff)) return v;
    if (auto v = s("preHpRes", SubtractiveParam::PreHpRes)) return v;
    if (auto v = s("preDrive", SubtractiveParam::PreDrive)) return v;
    if (auto v = s("mixFeedback", SubtractiveParam::MixFeedback)) return v;
    if (auto v = s("globalPitch", SubtractiveParam::GlobalPitch)) return v;
    if (auto v = s("filterKeyTrack", SubtractiveParam::FilterKeyTrack)) return v;
    if (auto v = s("filterDrive", SubtractiveParam::FilterDrive)) return v;
    if (auto v = s("filterShaper", SubtractiveParam::FilterShaper)) return v;
    if (auto v = s("filterFm", SubtractiveParam::FilterFm)) return v;
    if (auto v = s("filterShaperMode", SubtractiveParam::FilterShaperMode)) return v;
    if (auto v = s("synthLegato", SubtractiveParam::SynthLegato)) return v;
    if (auto v = s("synthMono", SubtractiveParam::SynthMono)) return v;
    return 0;
}

std::string_view SubtractiveSynthDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<SubtractiveParam>(localId)) {
    case SubtractiveParam::FilterCutoff: return "filterCutoff";
    case SubtractiveParam::FilterQ: return "filterQ";
    case SubtractiveParam::FilterMode: return "filterMode";
    case SubtractiveParam::AmpAttack: return "attack";
    case SubtractiveParam::AmpDecay: return "decay";
    case SubtractiveParam::AmpSustain: return "sustain";
    case SubtractiveParam::AmpRelease: return "release";
    case SubtractiveParam::Osc1Shape: return "osc1Shape";
    case SubtractiveParam::Osc2Shape: return "osc2Shape";
    case SubtractiveParam::Osc1Octave: return "osc1Octave";
    case SubtractiveParam::Osc1Semi: return "osc1Semi";
    case SubtractiveParam::Osc1Detune: return "osc1Detune";
    case SubtractiveParam::Osc2Octave: return "osc2Octave";
    case SubtractiveParam::Osc2Semi: return "osc2Semi";
    case SubtractiveParam::Osc2Detune: return "osc2Detune";
    case SubtractiveParam::OscMix: return "oscMix";
    case SubtractiveParam::OscMixMode: return "oscMixMode";
    case SubtractiveParam::Osc1Sync: return "osc1Sync";
    case SubtractiveParam::Osc2Sync: return "osc2Sync";
    case SubtractiveParam::NoiseLevel: return "noiseLevel";
    case SubtractiveParam::UnisonVoices: return "unisonVoices";
    case SubtractiveParam::UnisonDetune: return "unisonDetune";
    case SubtractiveParam::FilterEnvAmount: return "filterEnvAmount";
    case SubtractiveParam::FilterAttack: return "filterAttack";
    case SubtractiveParam::FilterDecay: return "filterDecay";
    case SubtractiveParam::FilterSustain: return "filterSustain";
    case SubtractiveParam::FilterRelease: return "filterRelease";
    case SubtractiveParam::GlideMs: return "glideMs";
    case SubtractiveParam::VelocitySensitivity: return "velocitySensitivity";
    case SubtractiveParam::PreHpCutoff: return "preHpCutoff";
    case SubtractiveParam::PreHpRes: return "preHpRes";
    case SubtractiveParam::PreDrive: return "preDrive";
    case SubtractiveParam::MixFeedback: return "mixFeedback";
    case SubtractiveParam::GlobalPitch: return "globalPitch";
    case SubtractiveParam::FilterKeyTrack: return "filterKeyTrack";
    case SubtractiveParam::FilterDrive: return "filterDrive";
    case SubtractiveParam::FilterShaper: return "filterShaper";
    case SubtractiveParam::FilterFm: return "filterFm";
    case SubtractiveParam::FilterShaperMode: return "filterShaperMode";
    case SubtractiveParam::SynthLegato: return "synthLegato";
    case SubtractiveParam::SynthMono: return "synthMono";
    default: return "";
    }
}

std::span<const ParamDescriptor> SubtractiveSynthDeviceType::paramDescriptors() const noexcept {
    return {};
}

bool SubtractiveSynthDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
