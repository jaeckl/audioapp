#include "audioapp/devices/BassSynthDeviceType.hpp"

#include "audioapp/devices/DeviceStripParams.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/BassSynthInstance.hpp"

#include <algorithm>
#include <cmath>

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

BassSynthInstance instanceFromSnapshot(const DeviceState& state) {
    BassSynthInstance instance;
    instance.gain = state.gain;
    instance.oscShape = state.bassOscShape;
    instance.subMix = state.bassSubMix;
    instance.subOctave = state.bassSubOctave;
    instance.noise = state.bassNoise;
    instance.ampAttack = state.attack;
    instance.ampSustain = state.sustain;
    instance.ampRelease = state.release;
    instance.octave = state.bassOctave;
    instance.filterCutoff = state.filterCutoff;
    instance.filterResonance = state.bassFilterResonance;
    instance.filterEnvAmount = state.filterEnvAmount;
    instance.filterDecay = state.filterDecay;
    instance.drive = state.bassDrive;
    instance.squash = state.bassSquash;
    instance.glideMs = state.glideMs;
    instance.velocitySense = state.bassVelocitySense;
    return instance;
}

void applyInstanceToSnapshot(const BassSynthInstance& instance, DeviceState& state) {
    state.bassOscShape = instance.oscShape;
    state.bassSubMix = instance.subMix;
    state.bassSubOctave = instance.subOctave;
    state.bassNoise = instance.noise;
    state.attack = instance.ampAttack;
    state.sustain = instance.ampSustain;
    state.release = instance.ampRelease;
    state.bassOctave = instance.octave;
    state.filterCutoff = instance.filterCutoff;
    state.bassFilterResonance = instance.filterResonance;
    state.filterEnvAmount = instance.filterEnvAmount;
    state.filterDecay = instance.filterDecay;
    state.bassDrive = instance.drive;
    state.bassSquash = instance.squash;
    state.glideMs = instance.glideMs;
    state.bassVelocitySense = instance.velocitySense;
}

} // namespace

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

DeviceState BassSynthDeviceType::toSnapshotState(const DeviceSlot& slot) const {
    DeviceState state = stripSnapshot(slot, device_types::kBasSynth);
    applyInstanceToSnapshot(std::get<BassSynthInstance>(slot.instance), state);
    return state;
}

DeviceSlot BassSynthDeviceType::slotFromSnapshot(const DeviceState& state) const {
    DeviceSlot slot;
    slot.id = state.id;
    slot.gain = state.gain;
    slot.pan = state.pan;
    slot.bypassed = state.bypassed;
    slot.instance = instanceFromSnapshot(state);
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

} // namespace audioapp