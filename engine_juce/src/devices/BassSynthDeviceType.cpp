#include "audioapp/devices/BassSynthDeviceType.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/BassSynthModel.hpp"
#include "audioapp/devices/processors/SubtractiveSynthProcessor.hpp"

#include <algorithm>
#include <cmath>

#include "audioapp/devices/DeviceStripParams.hpp"

namespace audioapp {

SubtractiveSynthParams BassSynthModel::toPlaybackParams() const {
    SubtractiveSynthParams p;
    p.gain = 1.0f;
    // Osc 1 (main morph)
    p.osc1Shape = oscShape;
    p.osc1Octave = 0.5f;            // neutral
    p.osc1Semi = 0.0f;
    p.osc1Detune = 0.5f;
    p.osc1Sync = 0.0f;
    // Osc 2 (sub — always sine)
    p.osc2Shape = 0.0f;             // force sine
    const float subOctOffsets[] = {-1.0f, -2.0f, -3.0f};
    const float subOctNorm = (subOctOffsets[subOctave] + 4.0f) / 8.0f;
    p.osc2Octave = std::clamp(subOctNorm, 0.0f, 1.0f);
    p.osc2Semi = 0.0f;
    p.osc2Detune = 0.5f;
    p.osc2Sync = 0.0f;
    // Osc mix
    p.oscMix = subMix;
    p.oscMixMode = 0;
    p.noiseLevel = noise;
    // Filter — always LP12
    p.filterMode = 0;
    p.filterCutoff = filterCutoff;
    p.filterQ = filterResonance;
    p.filterKeyTrack = 0.67f;       // 67% key track
    p.filterEnvAmount = filterEnvAmount;
    p.filterAttack = 0.0f;
    p.filterDecay = filterDecay;
    p.filterSustain = 0.0f;         // ADR envelope
    p.filterRelease = 0.0f;
    p.filterDrive = drive;
    p.filterFm = 0.0f;
    p.filterShaper = 0.0f;
    p.filterShaperMode = 1;         // Soft
    // Amp
    p.ampAttack = ampAttack;
    p.ampDecay = 0.0f;
    p.ampSustain = ampSustain;
    p.ampRelease = ampRelease;
    // Performance
    p.glideMs = glideMs;
    p.velocitySensitivity = velocitySense;
    // Global
    const float octNormValues[5] = {0.0f, 0.125f, 0.25f, 0.375f, 0.5f};
    p.globalPitch = octNormValues[octave];
    p.synthLegato = 1.0f;
    p.synthMono = 1.0f;
    // Pre
    p.preHpCutoff = 0.0f;
    p.preHpRes = 0.2f;
    p.preDrive = drive * 0.5f;
    // Feedback
    p.mixFeedback = squash;
    // Unison
    p.unisonVoices = 0.35f;         // ~2 voices
    p.unisonDetune = 0.15f;
    return p;
}

std::string BassSynthDeviceType::typeId() const {
    return device_types::kBasSynth;
}

DeviceSlot BassSynthDeviceType::createDefault(const std::string& deviceId) const {
    DeviceSlot slot;
    slot.id = deviceId;
    slot.config.typeId = typeId();
    BassSynthModel instance;
    slot.config.instance = std::move(instance);

    slot.config.inputPanel = EmptyPanel{};
    slot.config.outputPanel = StereoOutputPanel{};
    slot.config.bypassed = false;
    return slot;
}

DeviceParameterResult BassSynthDeviceType::setParameter(DeviceSlot& slot,
                                                       std::string_view parameterId,
                                                       float value) const {
    DeviceParameterResult result;
    if (device_strip::setStripParameter(slot, parameterId, value)) {
        result.handled = true;
        return result;
    }

    const uint16_t localId = paramIdFromString(parameterId);
    if (localId == static_cast<uint16_t>(-1))
        return result;

    auto& instance = std::get<BassSynthModel>(slot.config.instance);

    switch (static_cast<BassSynthParam>(localId)) {
    case BassSynthParam::FilterCutoff:
        instance.filterCutoff = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::FilterResonance:
        instance.filterResonance = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::FilterEnvAmount:
        instance.filterEnvAmount = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::FilterDecay:
        instance.filterDecay = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::AmpAttack:
        instance.ampAttack = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::AmpSustain:
        instance.ampSustain = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::AmpRelease:
        instance.ampRelease = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::OscShape:
        instance.oscShape = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::SubMix:
        instance.subMix = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::Noise:
        instance.noise = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::Drive:
        instance.drive = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::Squash:
        instance.squash = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::GlideMs:
        instance.glideMs = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::VelocitySense:
        instance.velocitySense = std::clamp(value, 0.0f, 1.0f); break;
    case BassSynthParam::Octave:
        instance.octave = std::clamp(static_cast<int>(std::lround(value)), 0, 4); break;
    case BassSynthParam::SubOctave:
        instance.subOctave = std::clamp(static_cast<int>(std::lround(value)), 0, 2); break;
    default:
        return result;
    }

    result.handled = true;
    return result;
}

bool BassSynthDeviceType::setStringParameter(DeviceSlot&,
                                             std::string_view,
                                             const std::string&,
                                             const PlaybackBuildContext&) const {
    return false;
}

std::vector<std::string_view> BassSynthDeviceType::modulatableParams() const {
    return {
        "gain", "pan",
        "bassOscShape", "bassSubMix", "bassNoise",
        "filterCutoff", "bassFilterResonance",
        "filterEnvAmount", "filterDecay",
        "attack", "sustain", "release",
        "bassDrive", "bassSquash",
        "glideMs", "bassVelocitySense",
        "bassOctave", "bassSubOctave",
    };
}

void BassSynthDeviceType::buildPlaybackNode(const DeviceSlot& slot,
                                            const PlaybackBuildContext&,
                                            DeviceNodePlayback& out) const {
    const auto& inst = std::get<BassSynthModel>(slot.config.instance);
    auto params = inst.toPlaybackParams();
    params.gain = 1.0f; // output-panel gain is applied by the device-chain stage
    out.kind = DeviceNodeKind::BassSynth;
    out.params = params;
}

bool BassSynthDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                              const PlaybackBuildContext&,
                                              LiveInstrumentSnapshot& out) const {
    const auto& inst = std::get<BassSynthModel>(slot.config.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::BassSynth;
    const auto gain = std::get<StereoOutputPanel>(slot.config.outputPanel).gain;
    out.gain = gain;
    out.subtractive = inst.toPlaybackParams();
    out.subtractive.gain = gain;
    return true;
}

juce::var BassSynthDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<BassSynthModel>(slot.config.instance);
    parameters->setProperty("bassOscShape", static_cast<double>(inst.oscShape));
    parameters->setProperty("bassSubMix", static_cast<double>(inst.subMix));
    parameters->setProperty("bassSubOctave", inst.subOctave);
    parameters->setProperty("bassNoise", static_cast<double>(inst.noise));
    parameters->setProperty("attack", static_cast<double>(inst.ampAttack));
    parameters->setProperty("sustain", static_cast<double>(inst.ampSustain));
    parameters->setProperty("release", static_cast<double>(inst.ampRelease));
    parameters->setProperty("bassOctave", inst.octave);
    parameters->setProperty("filterCutoff", static_cast<double>(inst.filterCutoff));
    parameters->setProperty("bassFilterResonance", static_cast<double>(inst.filterResonance));
    parameters->setProperty("filterEnvAmount", static_cast<double>(inst.filterEnvAmount));
    parameters->setProperty("filterDecay", static_cast<double>(inst.filterDecay));
    parameters->setProperty("bassDrive", static_cast<double>(inst.drive));
    parameters->setProperty("bassSquash", static_cast<double>(inst.squash));
    parameters->setProperty("glideMs", static_cast<double>(inst.glideMs));
    parameters->setProperty("bassVelocitySense", static_cast<double>(inst.velocitySense));

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

DeviceSlot BassSynthDeviceType::varToSlot(const juce::var& obj) const {
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

            if (!hasPanel) {
                const float oldGain = readFloat("gain", 1.0f);
                const float oldPan = readFloat("pan", 0.5f);
                slot.config.outputPanel = StereoOutputPanel{oldGain, oldPan};
                slot.config.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            }

            BassSynthModel inst;
            inst.oscShape = readFloat("bassOscShape", 0.3f);
            inst.subMix = readFloat("bassSubMix", 0.5f);
            inst.subOctave = static_cast<int>(std::lround(readFloat("bassSubOctave", 0.0f)));
            inst.noise = readFloat("bassNoise", 0.0f);
            inst.ampAttack = readFloat("attack", 0.01f);
            inst.ampSustain = readFloat("sustain", 0.7f);
            inst.ampRelease = readFloat("release", 0.4f);
            inst.octave = static_cast<int>(std::lround(readFloat("bassOctave", 2.0f)));
            inst.filterCutoff = readFloat("filterCutoff", 1.0f);
            inst.filterResonance = readFloat("bassFilterResonance", 0.25f);
            inst.filterEnvAmount = readFloat("filterEnvAmount", 0.5f);
            inst.filterDecay = readFloat("filterDecay", 0.35f);
            inst.drive = readFloat("bassDrive", 0.0f);
            inst.squash = readFloat("bassSquash", 0.0f);
            inst.glideMs = readFloat("glideMs", 0.0f);
            inst.velocitySense = readFloat("bassVelocitySense", 1.0f);
            slot.config.instance = inst;
        }
    }
    return slot;
}

DeviceProcessor* BassSynthDeviceType::createProcessor(ProcessorArena& arena) const {
    return arena.template emplace<BassSynthProcessor>();
}

DeviceNodeKind BassSynthDeviceType::kind() const noexcept { return DeviceNodeKind::BassSynth; }

uint16_t BassSynthDeviceType::paramIdFromString(std::string_view name) const noexcept {
    auto b = [&](std::string_view n, BassSynthParam pid) -> uint16_t {
        return name == n ? static_cast<uint16_t>(pid) : static_cast<uint16_t>(-1);
    };
    if (auto v = b("filterCutoff", BassSynthParam::FilterCutoff); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("bassFilterResonance", BassSynthParam::FilterResonance); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("filterEnvAmount", BassSynthParam::FilterEnvAmount); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("filterDecay", BassSynthParam::FilterDecay); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("attack", BassSynthParam::AmpAttack); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("sustain", BassSynthParam::AmpSustain); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("release", BassSynthParam::AmpRelease); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("bassOscShape", BassSynthParam::OscShape); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("bassSubMix", BassSynthParam::SubMix); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("bassNoise", BassSynthParam::Noise); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("bassDrive", BassSynthParam::Drive); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("bassSquash", BassSynthParam::Squash); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("glideMs", BassSynthParam::GlideMs); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("bassVelocitySense", BassSynthParam::VelocitySense); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("bassOctave", BassSynthParam::Octave); v != static_cast<uint16_t>(-1)) return v;
    if (auto v = b("bassSubOctave", BassSynthParam::SubOctave); v != static_cast<uint16_t>(-1)) return v;
    return static_cast<uint16_t>(-1);
}

std::string_view BassSynthDeviceType::paramIdToString(uint16_t localId) const noexcept {
    switch (static_cast<BassSynthParam>(localId)) {
    case BassSynthParam::FilterCutoff: return "filterCutoff";
    case BassSynthParam::FilterResonance: return "bassFilterResonance";
    case BassSynthParam::FilterEnvAmount: return "filterEnvAmount";
    case BassSynthParam::FilterDecay: return "filterDecay";
    case BassSynthParam::AmpAttack: return "attack";
    case BassSynthParam::AmpSustain: return "sustain";
    case BassSynthParam::AmpRelease: return "release";
    case BassSynthParam::OscShape: return "bassOscShape";
    case BassSynthParam::SubMix: return "bassSubMix";
    case BassSynthParam::Noise: return "bassNoise";
    case BassSynthParam::Drive: return "bassDrive";
    case BassSynthParam::Squash: return "bassSquash";
    case BassSynthParam::GlideMs: return "glideMs";
    case BassSynthParam::VelocitySense: return "bassVelocitySense";
    case BassSynthParam::Octave: return "bassOctave";
    case BassSynthParam::SubOctave: return "bassSubOctave";
    default: return "";
    }
}

std::span<const ParamDescriptor> BassSynthDeviceType::paramDescriptors() const noexcept {
    static constexpr ParamDescriptor kParams[] = {
        {static_cast<uint16_t>(BassSynthParam::FilterCutoff), "filterCutoff", "Filter Cutoff", 0.85f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::FilterResonance), "bassFilterResonance", "Filter Resonance", 0.25f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::FilterEnvAmount), "filterEnvAmount", "Env Amount", 0.6f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::FilterDecay), "filterDecay", "Filter Decay", 0.4f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::AmpAttack), "attack", "Attack", 0.02f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::AmpSustain), "sustain", "Sustain", 0.8f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::AmpRelease), "release", "Release", 0.35f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::OscShape), "bassOscShape", "Osc Shape", 0.3f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::SubMix), "bassSubMix", "Sub Mix", 0.5f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::Noise), "bassNoise", "Noise", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::Drive), "bassDrive", "Drive", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::Squash), "bassSquash", "Squash", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::GlideMs), "glideMs", "Glide", 0.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::VelocitySense), "bassVelocitySense", "Velocity Sense", 1.0f, 0.0f, 1.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::Octave), "bassOctave", "Octave", 2.0f, 0.0f, 4.0f, true, true},
        {static_cast<uint16_t>(BassSynthParam::SubOctave), "bassSubOctave", "Sub Octave", 0.0f, 0.0f, 2.0f, true, true},
    };
    return kParams;
}

bool BassSynthDeviceType::usesDspAutomationSubBlocks() const noexcept { return false; }

} // namespace audioapp
