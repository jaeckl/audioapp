#include "audioapp/devices/BassSynthDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/BassSynthInstance.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

SubtractiveSynthParams BassSynthInstance::toPlaybackParams() const {
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
    BassSynthInstance instance;
    slot.instance = std::move(instance);
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

    auto& instance = std::get<BassSynthInstance>(slot.instance);

    if (parameterId == "attack" || parameterId == "sustain" || parameterId == "release") {
        const float clamped = std::clamp(value, 0.0f, 1.0f);
        if (parameterId == "attack") {
            instance.ampAttack = clamped;
        } else if (parameterId == "release") {
            instance.ampRelease = clamped;
        } else {
            instance.ampSustain = clamped;
        }
    } else if (parameterId == "bassOscShape" || parameterId == "bassSubMix" ||
               parameterId == "bassNoise" || parameterId == "bassFilterResonance" ||
               parameterId == "bassDrive" || parameterId == "bassSquash" ||
               parameterId == "bassVelocitySense" || parameterId == "glideMs") {
        const float clamped = std::clamp(value, 0.0f, 1.0f);
        if (parameterId == "bassOscShape") {
            instance.oscShape = clamped;
        } else if (parameterId == "bassSubMix") {
            instance.subMix = clamped;
        } else if (parameterId == "bassNoise") {
            instance.noise = clamped;
        } else if (parameterId == "bassFilterResonance") {
            instance.filterResonance = clamped;
        } else if (parameterId == "bassDrive") {
            instance.drive = clamped;
        } else if (parameterId == "bassSquash") {
            instance.squash = clamped;
        } else if (parameterId == "bassVelocitySense") {
            instance.velocitySense = clamped;
        } else {
            instance.glideMs = clamped;
        }
    } else if (parameterId == "filterCutoff" || parameterId == "filterEnvAmount" ||
               parameterId == "filterDecay") {
        const float clamped = std::clamp(value, 0.0f, 1.0f);
        if (parameterId == "filterCutoff") {
            instance.filterCutoff = clamped;
        } else if (parameterId == "filterEnvAmount") {
            instance.filterEnvAmount = clamped;
        } else {
            instance.filterDecay = clamped;
        }
    } else if (parameterId == "bassSubOctave") {
        instance.subOctave = std::clamp(static_cast<int>(std::lround(value)), 0, 2);
    } else if (parameterId == "bassOctave") {
        instance.octave = std::clamp(static_cast<int>(std::lround(value)), 0, 4);
    } else {
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
    const auto& inst = std::get<BassSynthInstance>(slot.instance);
    auto params = inst.toPlaybackParams();
    params.gain = slot.gain;
    out.kind = DeviceNodeKind::BassSynth;
    out.params = params;
}

bool BassSynthDeviceType::buildLiveInstrument(const DeviceSlot& slot,
                                              const PlaybackBuildContext&,
                                              LiveInstrumentSnapshot& out) const {
    const auto& inst = std::get<BassSynthInstance>(slot.instance);
    out = LiveInstrumentSnapshot{};
    out.kind = LiveInstrumentKind::BassSynth;
    out.gain = slot.gain;
    out.subtractive = inst.toPlaybackParams();
    out.subtractive.gain = slot.gain;
    return true;
}

juce::var BassSynthDeviceType::slotToVar(const DeviceSlot& slot) const {
    auto* parameters = new juce::DynamicObject();
    const auto& inst = std::get<BassSynthInstance>(slot.instance);
    parameters->setProperty("gain", static_cast<double>(slot.gain));
    parameters->setProperty("pan", static_cast<double>(slot.pan));
    parameters->setProperty("bypass", slot.bypassed ? 1.0 : 0.0);
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
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceSlot BassSynthDeviceType::varToSlot(const juce::var& obj) const {
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
            slot.gain = readFloat("gain", 1.0f);
            slot.pan = readFloat("pan", 0.5f);
            slot.bypassed = readFloat("bypass", 0.0f) >= 0.5f;
            BassSynthInstance inst;
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
            slot.instance = inst;
        }
    }
    return slot;
}

} // namespace audioapp