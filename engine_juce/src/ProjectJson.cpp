#include "audioapp/ProjectJson.hpp"
#include "audioapp/SampleTypes.hpp"

#include <juce_core/juce_core.h>

namespace audioapp {

namespace {

juce::String toJuceString(const std::string& value) {
    return juce::String::fromUTF8(value.data(), static_cast<int>(value.size()));
}

juce::var parseRootVar(const std::string& json) {
    if (json.empty()) {
        return juce::var();
    }
    const auto parsed =
        juce::JSON::parse(juce::String::fromUTF8(json.data(), static_cast<int>(json.size())));
    if (parsed.isVoid() || parsed.isUndefined()) {
        return juce::var();
    }
    return parsed;
}

std::string toStdString(const juce::String& value) {
    return value.toStdString();
}

int varToInt(const juce::var& value, int fallback) {
    if (value.isInt() || value.isInt64()) {
        return static_cast<int>(value);
    }
    if (value.isDouble()) {
        return static_cast<int>(static_cast<double>(value));
    }
    return fallback;
}

double varToDouble(const juce::var& value, double fallback) {
    if (value.isDouble() || value.isInt() || value.isInt64()) {
        return static_cast<double>(value);
    }
    return fallback;
}

float varToFloat(const juce::var& value, float fallback) {
    return static_cast<float>(varToDouble(value, static_cast<double>(fallback)));
}

std::string varToString(const juce::var& value) {
    return value.toString().toStdString();
}

const juce::Array<juce::var>* varArray(const juce::var& value) {
    return value.getArray();
}

juce::var midiNoteToVar(const MidiNoteState& note) {
    auto* object = new juce::DynamicObject();
    object->setProperty("pitch", note.pitch);
    object->setProperty("startBeat", note.startBeat);
    object->setProperty("durationBeats", note.durationBeats);
    object->setProperty("velocity", static_cast<double>(note.velocity));
    return juce::var(object);
}

MidiNoteState midiNoteFromVar(const juce::var& value) {
    MidiNoteState note;
    if (const auto* object = value.getDynamicObject()) {
        note.pitch = varToInt(object->getProperty("pitch"), 60);
        note.startBeat = varToDouble(object->getProperty("startBeat"), 0.0);
        note.durationBeats = varToDouble(object->getProperty("durationBeats"), 1.0);
        note.velocity = varToFloat(object->getProperty("velocity"), 100.0f);
    }
    return note;
}

juce::var deviceToVar(const DeviceState& device) {
    auto* parameters = new juce::DynamicObject();
    if (device.type == "track_gain" || device.type == "simple_sampler" ||
        device.type == "simple_oscillator" || device.type == "subtractive_synth" ||
        device.type == "gate" || device.type == "compressor" || device.type == "expander" ||
        device.type == "limiter") {
        parameters->setProperty("gain", static_cast<double>(device.gain));
    }
    if (device.type != "track_gain") {
        parameters->setProperty("pan", static_cast<double>(device.pan));
    }
    if (device.type == "simple_sampler") {
        parameters->setProperty("sampleId", toJuceString(device.sampleId));
        parameters->setProperty("attack", static_cast<double>(device.attack));
        parameters->setProperty("decay", static_cast<double>(device.decay));
        parameters->setProperty("sustain", static_cast<double>(device.sustain));
        parameters->setProperty("release", static_cast<double>(device.release));
        parameters->setProperty("filterCutoff", static_cast<double>(device.filterCutoff));
        parameters->setProperty("filterQ", static_cast<double>(device.filterQ));
        parameters->setProperty("filterMode", device.filterMode);
        parameters->setProperty("trimStartSec", static_cast<double>(device.trimStartSec));
        parameters->setProperty("trimEndSec", static_cast<double>(device.trimEndSec));
        parameters->setProperty("regionStartSec", static_cast<double>(device.regionStartSec));
        parameters->setProperty("regionEndSec", static_cast<double>(device.regionEndSec));
    }
    if (device.type == "simple_oscillator") {
        parameters->setProperty("frequency", static_cast<double>(device.frequencyHz));
    }
    if (device.type == "subtractive_synth") {
        parameters->setProperty("attack", static_cast<double>(device.attack));
        parameters->setProperty("decay", static_cast<double>(device.decay));
        parameters->setProperty("sustain", static_cast<double>(device.sustain));
        parameters->setProperty("release", static_cast<double>(device.release));
        parameters->setProperty("filterCutoff", static_cast<double>(device.filterCutoff));
        parameters->setProperty("filterQ", static_cast<double>(device.filterQ));
        parameters->setProperty("filterEnvAmount", static_cast<double>(device.filterEnvAmount));
        parameters->setProperty("filterAttack", static_cast<double>(device.filterAttack));
        parameters->setProperty("filterDecay", static_cast<double>(device.filterDecay));
        parameters->setProperty("filterSustain", static_cast<double>(device.filterSustain));
        parameters->setProperty("filterRelease", static_cast<double>(device.filterRelease));
        parameters->setProperty("osc1Shape", static_cast<double>(device.osc1Shape));
        parameters->setProperty("osc2Shape", static_cast<double>(device.osc2Shape));
        parameters->setProperty("osc1Octave", static_cast<double>(device.osc1Octave));
        parameters->setProperty("osc1Semi", static_cast<double>(device.osc1Semi));
        parameters->setProperty("osc1Detune", static_cast<double>(device.osc1Detune));
        parameters->setProperty("osc2Octave", static_cast<double>(device.osc2Octave));
        parameters->setProperty("osc2Semi", static_cast<double>(device.osc2Semi));
        parameters->setProperty("osc2Detune", static_cast<double>(device.osc2Detune));
        parameters->setProperty("oscMix", static_cast<double>(device.oscMix));
        parameters->setProperty("osc1Sync", static_cast<double>(device.osc1Sync));
        parameters->setProperty("osc2Sync", static_cast<double>(device.osc2Sync));
        parameters->setProperty("filterMode", device.filterMode);
        parameters->setProperty("noiseLevel", static_cast<double>(device.noiseLevel));
        parameters->setProperty("oscMixMode", device.oscMixMode);
        parameters->setProperty("unisonVoices", static_cast<double>(device.unisonVoices));
        parameters->setProperty("unisonDetune", static_cast<double>(device.unisonDetune));
        parameters->setProperty("glideMs", static_cast<double>(device.glideMs));
        parameters->setProperty("velocitySensitivity",
                                static_cast<double>(device.velocitySensitivity));
    }
    if (device.type == "kick_generator") {
        parameters->setProperty("kickPitch", static_cast<double>(device.kickPitch));
        parameters->setProperty("kickPunch", static_cast<double>(device.kickPunch));
        parameters->setProperty("kickDecay", static_cast<double>(device.kickDecay));
        parameters->setProperty("kickClick", static_cast<double>(device.kickClick));
        parameters->setProperty("kickTone", static_cast<double>(device.kickTone));
        parameters->setProperty("kickVelocity", static_cast<double>(device.kickVelocity));
    }
    if (device.type == "snare_generator") {
        parameters->setProperty("snareBody", static_cast<double>(device.snareBody));
        parameters->setProperty("snareTune", static_cast<double>(device.snareTune));
        parameters->setProperty("snareSnares", static_cast<double>(device.snareSnares));
        parameters->setProperty("snareSnap", static_cast<double>(device.snareSnap));
        parameters->setProperty("snareDecay", static_cast<double>(device.snareDecay));
        parameters->setProperty("snareVelocity", static_cast<double>(device.snareVelocity));
    }
    if (device.type == "clap_generator") {
        parameters->setProperty("clapBursts", static_cast<double>(device.clapBursts));
        parameters->setProperty("clapSpread", static_cast<double>(device.clapSpread));
        parameters->setProperty("clapTone", static_cast<double>(device.clapTone));
        parameters->setProperty("clapRoom", static_cast<double>(device.clapRoom));
        parameters->setProperty("clapDecay", static_cast<double>(device.clapDecay));
    }
    if (device.type == "cymbal_generator") {
        parameters->setProperty("cymbalMetal", static_cast<double>(device.cymbalMetal));
        parameters->setProperty("cymbalBrightness", static_cast<double>(device.cymbalBrightness));
        parameters->setProperty("cymbalDecay", static_cast<double>(device.cymbalDecay));
        parameters->setProperty("cymbalChoke", static_cast<double>(device.cymbalChoke));
        parameters->setProperty("cymbalVelocity", static_cast<double>(device.cymbalVelocity));
    }
    if (device.type == "gate") {
        parameters->setProperty("gateThreshold", static_cast<double>(device.gateThreshold));
        parameters->setProperty("gateAttack", static_cast<double>(device.gateAttack));
        parameters->setProperty("gateRelease", static_cast<double>(device.gateRelease));
        parameters->setProperty("gateHold", static_cast<double>(device.gateHold));
        parameters->setProperty("gateRange", static_cast<double>(device.gateRange));
    }
    if (device.type == "compressor") {
        parameters->setProperty("compThreshold", static_cast<double>(device.compThreshold));
        parameters->setProperty("compRatio", static_cast<double>(device.compRatio));
        parameters->setProperty("compAttack", static_cast<double>(device.compAttack));
        parameters->setProperty("compRelease", static_cast<double>(device.compRelease));
        parameters->setProperty("compKnee", static_cast<double>(device.compKnee));
        parameters->setProperty("compMakeup", static_cast<double>(device.compMakeup));
    }
    if (device.type == "expander") {
        parameters->setProperty("expandThreshold", static_cast<double>(device.expandThreshold));
        parameters->setProperty("expandRatio", static_cast<double>(device.expandRatio));
        parameters->setProperty("expandAttack", static_cast<double>(device.expandAttack));
        parameters->setProperty("expandRelease", static_cast<double>(device.expandRelease));
        parameters->setProperty("expandRange", static_cast<double>(device.expandRange));
    }
    if (device.type == "limiter") {
        parameters->setProperty("limitCeiling", static_cast<double>(device.limitCeiling));
        parameters->setProperty("limitRelease", static_cast<double>(device.limitRelease));
        parameters->setProperty("limitDrive", static_cast<double>(device.limitDrive));
    }

    auto* object = new juce::DynamicObject();
    object->setProperty("id", toJuceString(device.id));
    object->setProperty("type", toJuceString(device.type));
    parameters->setProperty("bypass", device.bypassed ? 1.0 : 0.0);
    object->setProperty("parameters", juce::var(parameters));
    return juce::var(object);
}

DeviceState deviceFromVar(const juce::var& value) {
    DeviceState device;
    if (const auto* object = value.getDynamicObject()) {
        device.id = varToString(object->getProperty("id"));
        device.type = varToString(object->getProperty("type"));
        const auto parameters = object->getProperty("parameters");
        if (const auto* params = parameters.getDynamicObject()) {
            device.frequencyHz = varToFloat(params->getProperty("frequency"), 440.0f);
            device.gain = varToFloat(params->getProperty("gain"), 1.0f);
            device.pan = varToFloat(params->getProperty("pan"), 0.5f);
            device.sampleId = varToString(params->getProperty("sampleId"));
            device.attack = varToFloat(params->getProperty("attack"), 0.01f);
            device.decay = varToFloat(params->getProperty("decay"), 0.3f);
            device.sustain = varToFloat(params->getProperty("sustain"), 0.7f);
            device.release = varToFloat(params->getProperty("release"), 0.4f);
            device.filterCutoff = varToFloat(params->getProperty("filterCutoff"), 1.0f);
            device.filterQ = varToFloat(params->getProperty("filterQ"), 0.35f);
            device.filterMode = varToInt(params->getProperty("filterMode"), 0);
            device.trimStartSec = varToFloat(params->getProperty("trimStartSec"), 0.0f);
            device.trimEndSec = varToFloat(params->getProperty("trimEndSec"), 0.0f);
            device.regionStartSec = varToFloat(params->getProperty("regionStartSec"), 0.0f);
            device.regionEndSec = varToFloat(params->getProperty("regionEndSec"), 0.0f);
            device.bypassed = varToFloat(params->getProperty("bypass"), 0.0f) >= 0.5f;
            if (params->hasProperty("osc1Shape")) {
                device.osc1Shape = varToFloat(params->getProperty("osc1Shape"), 0.5f);
            } else {
                const int legacyWave = varToInt(params->getProperty("osc1Wave"), 2);
                device.osc1Shape = static_cast<float>(legacyWave) / 4.0f;
            }
            if (params->hasProperty("osc2Shape")) {
                device.osc2Shape = varToFloat(params->getProperty("osc2Shape"), 0.5f);
            } else {
                const int legacyWave = varToInt(params->getProperty("osc2Wave"), 2);
                device.osc2Shape = static_cast<float>(legacyWave) / 4.0f;
            }
            device.osc1Octave = varToFloat(params->getProperty("osc1Octave"), 0.5f);
            device.osc1Semi = varToFloat(params->getProperty("osc1Semi"), 0.0f);
            device.osc1Detune = varToFloat(params->getProperty("osc1Detune"), 0.5f);
            device.osc2Octave = varToFloat(params->getProperty("osc2Octave"), 0.5f);
            device.osc2Semi = varToFloat(params->getProperty("osc2Semi"), 0.0f);
            device.osc2Detune = varToFloat(params->getProperty("osc2Detune"), 0.5f);
            if (params->hasProperty("oscMix")) {
                device.oscMix = varToFloat(params->getProperty("oscMix"), 0.37f);
            } else {
                const float osc1Level = varToFloat(params->getProperty("osc1Level"), 0.85f);
                const float osc2Level = varToFloat(params->getProperty("osc2Level"), 0.5f);
                const float sum = osc1Level + osc2Level;
                device.oscMix = sum > 0.001f ? osc2Level / sum : 0.37f;
            }
            device.osc1Sync = varToFloat(params->getProperty("osc1Sync"), 0.0f);
            device.osc2Sync = varToFloat(params->getProperty("osc2Sync"), 0.0f);
            device.noiseLevel = varToFloat(params->getProperty("noiseLevel"), 0.0f);
            device.oscMixMode = varToInt(params->getProperty("oscMixMode"), 0);
            device.unisonVoices = varToFloat(params->getProperty("unisonVoices"), 0.0f);
            device.unisonDetune = varToFloat(params->getProperty("unisonDetune"), 0.35f);
            device.filterEnvAmount = varToFloat(params->getProperty("filterEnvAmount"), 0.5f);
            device.filterAttack = varToFloat(params->getProperty("filterAttack"), 0.05f);
            device.filterDecay = varToFloat(params->getProperty("filterDecay"), 0.35f);
            device.filterSustain = varToFloat(params->getProperty("filterSustain"), 0.4f);
            device.filterRelease = varToFloat(params->getProperty("filterRelease"), 0.45f);
            device.glideMs = varToFloat(params->getProperty("glideMs"), 0.0f);
            device.velocitySensitivity =
                varToFloat(params->getProperty("velocitySensitivity"), 1.0f);
            device.kickPitch = varToFloat(params->getProperty("kickPitch"), 0.55f);
            device.kickPunch = varToFloat(params->getProperty("kickPunch"), 0.60f);
            device.kickDecay = varToFloat(params->getProperty("kickDecay"), 0.50f);
            device.kickClick = varToFloat(params->getProperty("kickClick"), 0.35f);
            device.kickTone = varToFloat(params->getProperty("kickTone"), 0.50f);
            device.kickVelocity = varToFloat(params->getProperty("kickVelocity"), 1.0f);
            device.snareBody = varToFloat(params->getProperty("snareBody"), 0.55f);
            device.snareTune = varToFloat(params->getProperty("snareTune"), 0.50f);
            device.snareSnares = varToFloat(params->getProperty("snareSnares"), 0.60f);
            device.snareSnap = varToFloat(params->getProperty("snareSnap"), 0.40f);
            device.snareDecay = varToFloat(params->getProperty("snareDecay"), 0.50f);
            device.snareVelocity = varToFloat(params->getProperty("snareVelocity"), 1.0f);
            device.clapBursts = varToFloat(params->getProperty("clapBursts"), 0.50f);
            device.clapSpread = varToFloat(params->getProperty("clapSpread"), 0.45f);
            device.clapTone = varToFloat(params->getProperty("clapTone"), 0.55f);
            device.clapRoom = varToFloat(params->getProperty("clapRoom"), 0.50f);
            device.clapDecay = varToFloat(params->getProperty("clapDecay"), 0.50f);
            device.cymbalMetal = varToFloat(params->getProperty("cymbalMetal"), 0.55f);
            device.cymbalBrightness = varToFloat(params->getProperty("cymbalBrightness"), 0.60f);
            device.cymbalDecay = varToFloat(params->getProperty("cymbalDecay"), 0.50f);
            device.cymbalChoke = varToFloat(params->getProperty("cymbalChoke"), 0.0f);
            device.cymbalVelocity = varToFloat(params->getProperty("cymbalVelocity"), 1.0f);
            device.gateThreshold = varToFloat(params->getProperty("gateThreshold"), 0.45f);
            device.gateAttack = varToFloat(params->getProperty("gateAttack"), 0.25f);
            device.gateRelease = varToFloat(params->getProperty("gateRelease"), 0.50f);
            device.gateHold = varToFloat(params->getProperty("gateHold"), 0.20f);
            device.gateRange = varToFloat(params->getProperty("gateRange"), 0.0f);
            device.compThreshold = varToFloat(params->getProperty("compThreshold"), 0.55f);
            device.compRatio = varToFloat(params->getProperty("compRatio"), 0.50f);
            device.compAttack = varToFloat(params->getProperty("compAttack"), 0.20f);
            device.compRelease = varToFloat(params->getProperty("compRelease"), 0.55f);
            device.compKnee = varToFloat(params->getProperty("compKnee"), 0.25f);
            device.compMakeup = varToFloat(params->getProperty("compMakeup"), 0.35f);
            device.expandThreshold = varToFloat(params->getProperty("expandThreshold"), 0.40f);
            device.expandRatio = varToFloat(params->getProperty("expandRatio"), 0.45f);
            device.expandAttack = varToFloat(params->getProperty("expandAttack"), 0.25f);
            device.expandRelease = varToFloat(params->getProperty("expandRelease"), 0.55f);
            device.expandRange = varToFloat(params->getProperty("expandRange"), 0.15f);
            device.limitCeiling = varToFloat(params->getProperty("limitCeiling"), 0.85f);
            device.limitRelease = varToFloat(params->getProperty("limitRelease"), 0.40f);
            device.limitDrive = varToFloat(params->getProperty("limitDrive"), 0.0f);
        }
    }
    return device;
}

juce::var midiClipToVar(const MidiClipState& clip) {
    juce::Array<juce::var> notes;
    notes.ensureStorageAllocated(static_cast<int>(clip.notes.size()));
    for (const auto& note : clip.notes) {
        notes.add(midiNoteToVar(note));
    }

    auto* object = new juce::DynamicObject();
    object->setProperty("id", toJuceString(clip.id));
    object->setProperty("startBeat", clip.startBeat);
    object->setProperty("lengthBeats", clip.lengthBeats);
    object->setProperty("notes", notes);
    return juce::var(object);
}

MidiClipState midiClipFromVar(const juce::var& value) {
    MidiClipState clip;
    if (const auto* object = value.getDynamicObject()) {
        clip.id = varToString(object->getProperty("id"));
        clip.startBeat = varToDouble(object->getProperty("startBeat"), 0.0);
        clip.lengthBeats = varToDouble(object->getProperty("lengthBeats"), 4.0);
        if (const auto* notes = varArray(object->getProperty("notes"))) {
            clip.notes.reserve(static_cast<size_t>(notes->size()));
            for (const auto& noteVar : *notes) {
                clip.notes.push_back(midiNoteFromVar(noteVar));
            }
        }
    }
    return clip;
}

juce::var sampleClipToVar(const SampleClipState& clip) {
    juce::Array<juce::var> peaks;
    peaks.ensureStorageAllocated(static_cast<int>(clip.waveformPeaks.size()));
    for (const auto peak : clip.waveformPeaks) {
        peaks.add(static_cast<double>(peak));
    }

    auto* object = new juce::DynamicObject();
    object->setProperty("id", toJuceString(clip.id));
    object->setProperty("sampleId", toJuceString(clip.sampleId));
    object->setProperty("sampleName", toJuceString(clip.sampleName));
    object->setProperty("startBeat", clip.startBeat);
    object->setProperty("lengthBeats", clip.lengthBeats);
    object->setProperty("waveformPeaks", peaks);
    return juce::var(object);
}

SampleClipState sampleClipFromVar(const juce::var& value) {
    SampleClipState clip;
    if (const auto* object = value.getDynamicObject()) {
        clip.id = varToString(object->getProperty("id"));
        clip.sampleId = varToString(object->getProperty("sampleId"));
        clip.sampleName = varToString(object->getProperty("sampleName"));
        clip.startBeat = varToDouble(object->getProperty("startBeat"), 0.0);
        clip.lengthBeats = varToDouble(object->getProperty("lengthBeats"), 4.0);
        if (const auto* peakArray = varArray(object->getProperty("waveformPeaks"))) {
            clip.waveformPeaks.reserve(static_cast<size_t>(peakArray->size()));
            for (const auto& peakVar : *peakArray) {
                clip.waveformPeaks.push_back(varToFloat(peakVar, 0.0f));
            }
        }
    }
    return clip;
}

juce::var automationClipToVar(const AutomationClipState& clip) {
    juce::Array<juce::var> points;
    points.ensureStorageAllocated(static_cast<int>(clip.points.size()));
    for (const auto& point : clip.points) {
        auto* pointObject = new juce::DynamicObject();
        pointObject->setProperty("beat", point.beat);
        pointObject->setProperty("value", static_cast<double>(point.value));
        points.add(juce::var(pointObject));
    }

    auto* object = new juce::DynamicObject();
    object->setProperty("id", toJuceString(clip.id));
    object->setProperty("startBeat", clip.startBeat);
    object->setProperty("lengthBeats", clip.lengthBeats);
    object->setProperty("deviceId", toJuceString(clip.deviceId));
    object->setProperty("paramId", toJuceString(clip.paramId));
    object->setProperty("points", points);
    return juce::var(object);
}

AutomationClipState automationClipFromVar(const juce::var& value) {
    AutomationClipState clip;
    if (const auto* object = value.getDynamicObject()) {
        clip.id = varToString(object->getProperty("id"));
        clip.startBeat = varToDouble(object->getProperty("startBeat"), 0.0);
        clip.lengthBeats = varToDouble(object->getProperty("lengthBeats"), 4.0);
        clip.deviceId = varToString(object->getProperty("deviceId"));
        clip.paramId = varToString(object->getProperty("paramId"));
        if (const auto* pointArray = varArray(object->getProperty("points"))) {
            clip.points.reserve(static_cast<size_t>(pointArray->size()));
            for (const auto& pointVar : *pointArray) {
                if (const auto* pointObject = pointVar.getDynamicObject()) {
                    clip.points.push_back(AutomationPointState{
                        varToDouble(pointObject->getProperty("beat"), 0.0),
                        varToFloat(pointObject->getProperty("value"), 0.0f),
                    });
                }
            }
        }
    }
    return clip;
}

juce::var sampleLibraryEntryToVar(const SampleLibraryEntryState& entry) {
    juce::Array<juce::var> peaks;
    peaks.ensureStorageAllocated(static_cast<int>(entry.waveformPeaks.size()));
    for (const auto peak : entry.waveformPeaks) {
        peaks.add(static_cast<double>(peak));
    }

    auto* object = new juce::DynamicObject();
    object->setProperty("id", toJuceString(entry.id));
    object->setProperty("name", toJuceString(entry.name));
    object->setProperty("source", toJuceString(entry.source));
    object->setProperty("durationBeats", entry.durationBeats);
    object->setProperty("waveformPeaks", peaks);
    return juce::var(object);
}

SampleLibraryEntryState sampleLibraryEntryFromVar(const juce::var& value) {
    SampleLibraryEntryState entry;
    if (const auto* object = value.getDynamicObject()) {
        entry.id = varToString(object->getProperty("id"));
        entry.name = varToString(object->getProperty("name"));
        entry.source = varToString(object->getProperty("source"));
        entry.durationBeats = varToDouble(object->getProperty("durationBeats"), 4.0);
        if (const auto* peakArray = varArray(object->getProperty("waveformPeaks"))) {
            entry.waveformPeaks.reserve(static_cast<size_t>(peakArray->size()));
            for (const auto& peakVar : *peakArray) {
                entry.waveformPeaks.push_back(varToFloat(peakVar, 0.0f));
            }
        }
    }
    return entry;
}

juce::var trackToVar(const TrackState& track) {
    juce::Array<juce::var> devices;
    devices.ensureStorageAllocated(static_cast<int>(track.devices.size()));
    for (const auto& device : track.devices) {
        devices.add(deviceToVar(device));
    }

    juce::Array<juce::var> clips;
    clips.ensureStorageAllocated(static_cast<int>(track.midiClips.size()));
    for (const auto& clip : track.midiClips) {
        clips.add(midiClipToVar(clip));
    }

    juce::Array<juce::var> sampleClips;
    sampleClips.ensureStorageAllocated(static_cast<int>(track.sampleClips.size()));
    for (const auto& clip : track.sampleClips) {
        sampleClips.add(sampleClipToVar(clip));
    }

    juce::Array<juce::var> automationClips;
    automationClips.ensureStorageAllocated(static_cast<int>(track.automationClips.size()));
    for (const auto& clip : track.automationClips) {
        automationClips.add(automationClipToVar(clip));
    }

    auto* object = new juce::DynamicObject();
    object->setProperty("id", toJuceString(track.id));
    object->setProperty("name", toJuceString(track.name));
    object->setProperty("devices", devices);
    object->setProperty("midiClips", clips);
    object->setProperty("sampleClips", sampleClips);
    object->setProperty("automationClips", automationClips);
    return juce::var(object);
}

TrackState trackFromVar(const juce::var& value) {
    TrackState track;
    if (const auto* object = value.getDynamicObject()) {
        track.id = varToString(object->getProperty("id"));
        track.name = varToString(object->getProperty("name"));
        if (const auto* devices = varArray(object->getProperty("devices"))) {
            for (const auto& deviceVar : *devices) {
                track.devices.push_back(deviceFromVar(deviceVar));
            }
        }
        if (const auto* clips = varArray(object->getProperty("midiClips"))) {
            for (const auto& clipVar : *clips) {
                track.midiClips.push_back(midiClipFromVar(clipVar));
            }
        }
        if (const auto* sampleClips = varArray(object->getProperty("sampleClips"))) {
            for (const auto& clipVar : *sampleClips) {
                track.sampleClips.push_back(sampleClipFromVar(clipVar));
            }
        }
        if (const auto* automationClips = varArray(object->getProperty("automationClips"))) {
            for (const auto& clipVar : *automationClips) {
                track.automationClips.push_back(automationClipFromVar(clipVar));
            }
        }
    }
    return track;
}

// --- LFO / modulation serialization helpers ---

juce::var lfoToVar(const LfoState& lfo) {
    auto* object = new juce::DynamicObject();
    object->setProperty("id", lfo.id);
    object->setProperty("waveform", lfo.waveform);
    object->setProperty("rate", static_cast<double>(lfo.rate));
    object->setProperty("syncDivision", lfo.syncDivision);
    object->setProperty("phase", static_cast<double>(lfo.phase));
    return juce::var(object);
}

LfoState lfoFromVar(const juce::var& value) {
    LfoState lfo;
    if (const auto* object = value.getDynamicObject()) {
        lfo.id = varToInt(object->getProperty("id"), 0);
        lfo.waveform = varToInt(object->getProperty("waveform"), 0);
        lfo.rate = varToFloat(object->getProperty("rate"), 1.0f);
        lfo.syncDivision = varToInt(object->getProperty("syncDivision"), 0);
        lfo.phase = varToFloat(object->getProperty("phase"), 0.0f);
    }
    return lfo;
}

juce::var modEdgeToVar(const ModulationEdge& edge) {
    auto* object = new juce::DynamicObject();
    object->setProperty("lfoId", edge.lfoId);
    object->setProperty("deviceId", toJuceString(edge.deviceId));
    object->setProperty("paramId", toJuceString(edge.paramId));
    object->setProperty("amount", static_cast<double>(edge.amount));
    return juce::var(object);
}

ModulationEdge modEdgeFromVar(const juce::var& value) {
    ModulationEdge edge;
    if (const auto* object = value.getDynamicObject()) {
        edge.lfoId = varToInt(object->getProperty("lfoId"), 0);
        edge.deviceId = varToString(object->getProperty("deviceId"));
        edge.paramId = varToString(object->getProperty("paramId"));
        edge.amount = varToFloat(object->getProperty("amount"), 0.0f);
    }
    return edge;
}

juce::var lfoArrayToVar(const std::vector<LfoState>& lfos) {
    juce::Array<juce::var> result;
    result.ensureStorageAllocated(static_cast<int>(lfos.size()));
    for (const auto& lfo : lfos) {
        result.add(lfoToVar(lfo));
    }
    return juce::var(result);
}

std::vector<LfoState> lfoArrayFromVar(const juce::var& value) {
    std::vector<LfoState> result;
    if (const auto* arr = varArray(value)) {
        result.reserve(static_cast<size_t>(arr->size()));
        for (const auto& item : *arr) {
            result.push_back(lfoFromVar(item));
        }
    }
    return result;
}

juce::var modEdgeArrayToVar(const std::vector<ModulationEdge>& edges) {
    juce::Array<juce::var> result;
    result.ensureStorageAllocated(static_cast<int>(edges.size()));
    for (const auto& edge : edges) {
        result.add(modEdgeToVar(edge));
    }
    return juce::var(result);
}

std::vector<ModulationEdge> modEdgeArrayFromVar(const juce::var& value) {
    std::vector<ModulationEdge> result;
    if (const auto* arr = varArray(value)) {
        result.reserve(static_cast<size_t>(arr->size()));
        for (const auto& item : *arr) {
            result.push_back(modEdgeFromVar(item));
        }
    }
    return result;
}

juce::var snapshotToVar(const ProjectSnapshot& snapshot) {
    juce::Array<juce::var> tracks;
    tracks.ensureStorageAllocated(static_cast<int>(snapshot.tracks.size()));
    for (const auto& track : snapshot.tracks) {
        tracks.add(trackToVar(track));
    }

    juce::Array<juce::var> samples;
    samples.ensureStorageAllocated(static_cast<int>(snapshot.samples.size()));
    for (const auto& sample : snapshot.samples) {
        samples.add(sampleLibraryEntryToVar(sample));
    }

    auto* master = new juce::DynamicObject();
    master->setProperty("id", toJuceString(snapshot.master.id));
    master->setProperty("name", toJuceString(snapshot.master.name));
    master->setProperty("gain", static_cast<double>(snapshot.master.gain));

    auto* object = new juce::DynamicObject();
    object->setProperty("bpm", snapshot.bpm);
    object->setProperty("playheadBeats", snapshot.playheadBeats);
    object->setProperty("playing", snapshot.playing);
    object->setProperty("loopEnabled", snapshot.loopEnabled);
    object->setProperty("loopLengthBeats", snapshot.loopLengthBeats);
    object->setProperty("recordArmed", snapshot.recordArmed);
    object->setProperty("selectedTrackId", toJuceString(snapshot.selectedTrackId));
    object->setProperty("master", juce::var(master));
    object->setProperty("samples", samples);
    object->setProperty("tracks", tracks);
    object->setProperty("lfos", lfoArrayToVar(snapshot.lfos));
    object->setProperty("modEdges", modEdgeArrayToVar(snapshot.modEdges));
    return juce::var(object);
}

juce::var projectFileToVar(const ProjectFileData& project) {
    juce::Array<juce::var> tracks;
    tracks.ensureStorageAllocated(static_cast<int>(project.tracks.size()));
    for (const auto& track : project.tracks) {
        tracks.add(trackToVar(track));
    }

    juce::Array<juce::var> samples;
    samples.ensureStorageAllocated(static_cast<int>(project.sampleLibrary.size()));
    for (const auto& sample : project.sampleLibrary) {
        samples.add(sampleLibraryEntryToVar(sample));
    }

    auto* object = new juce::DynamicObject();
    object->setProperty("project_format_version", project.projectFormatVersion);
    object->setProperty("name", toJuceString(project.name));
    object->setProperty("bpm", project.bpm);
    object->setProperty("selectedTrackId", toJuceString(project.selectedTrackId));
    auto* master = new juce::DynamicObject();
    master->setProperty("id", toJuceString(project.master.id));
    master->setProperty("name", toJuceString(project.master.name));
    master->setProperty("gain", static_cast<double>(project.master.gain));
    object->setProperty("master", juce::var(master));
    object->setProperty("samples", samples);
    object->setProperty("tracks", tracks);
    object->setProperty("lfos", lfoArrayToVar(project.lfos));
    object->setProperty("modEdges", modEdgeArrayToVar(project.modEdges));
    return juce::var(object);
}

} // namespace

std::string snapshotToJson(const ProjectSnapshot& snapshot) {
    return toStdString(juce::JSON::toString(snapshotToVar(snapshot), false));
}

std::string projectFileToJson(const ProjectFileData& project) {
    return toStdString(juce::JSON::toString(projectFileToVar(project), true));
}

bool parseProjectFileJson(const std::string& json, ProjectFileData& out) {
    const auto root = parseRootVar(json);
    const auto* object = root.getDynamicObject();
    if (object == nullptr) {
        return false;
    }

    out.projectFormatVersion = varToInt(object->getProperty("project_format_version"), 0);
    if (out.projectFormatVersion != kProjectFormatVersion) {
        return false;
    }

    out.name = varToString(object->getProperty("name"));
    out.bpm = varToInt(object->getProperty("bpm"), 120);
    out.selectedTrackId = varToString(object->getProperty("selectedTrackId"));
    out.tracks.clear();
    out.sampleLibrary.clear();
    out.master.id = "master";
    out.master.name = "Master";
    out.master.gain = 1.0f;
    if (const auto* masterObject = object->getProperty("master").getDynamicObject()) {
        out.master.id = varToString(masterObject->getProperty("id"));
        out.master.name = varToString(masterObject->getProperty("name"));
        out.master.gain = varToFloat(masterObject->getProperty("gain"), 1.0f);
    }

    if (const auto* samples = varArray(object->getProperty("samples"))) {
        out.sampleLibrary.reserve(static_cast<size_t>(samples->size()));
        for (const auto& sampleVar : *samples) {
            out.sampleLibrary.push_back(sampleLibraryEntryFromVar(sampleVar));
        }
    }

    if (const auto* tracks = varArray(object->getProperty("tracks"))) {
        out.tracks.reserve(static_cast<size_t>(tracks->size()));
        for (const auto& trackVar : *tracks) {
            out.tracks.push_back(trackFromVar(trackVar));
        }
    }

    if (object->hasProperty("lfos")) {
        out.lfos = lfoArrayFromVar(object->getProperty("lfos"));
    }
    if (object->hasProperty("modEdges")) {
        out.modEdges = modEdgeArrayFromVar(object->getProperty("modEdges"));
    }

    return true;
}

std::vector<MidiNoteState> parseMidiNotesFromArgs(const std::string& argumentsJson) {
    std::vector<MidiNoteState> notes;
    const auto root = parseRootVar(argumentsJson);
    if (const auto* object = root.getDynamicObject()) {
        if (const auto* noteArray = varArray(object->getProperty("notes"))) {
            notes.reserve(static_cast<size_t>(noteArray->size()));
            for (const auto& noteVar : *noteArray) {
                notes.push_back(midiNoteFromVar(noteVar));
            }
        }
    }
    return notes;
}

std::vector<AutomationPointState> parseAutomationPointsFromArgs(const std::string& argumentsJson) {
    std::vector<AutomationPointState> points;
    const auto root = parseRootVar(argumentsJson);
    if (const auto* object = root.getDynamicObject()) {
        if (const auto* pointArray = varArray(object->getProperty("points"))) {
            points.reserve(static_cast<size_t>(pointArray->size()));
            for (const auto& pointVar : *pointArray) {
                if (const auto* pointObject = pointVar.getDynamicObject()) {
                    points.push_back(AutomationPointState{
                        varToDouble(pointObject->getProperty("beat"), 0.0),
                        varToFloat(pointObject->getProperty("value"), 0.0f),
                    });
                }
            }
        }
    }
    return points;
}

std::string jsonGetStringArg(const std::string& argumentsJson, const std::string& key) {
    const auto root = parseRootVar(argumentsJson);
    if (const auto* object = root.getDynamicObject()) {
        return varToString(object->getProperty(toJuceString(key)));
    }
    return {};
}

double jsonGetNumberArg(const std::string& argumentsJson, const std::string& key, double fallback) {
    const auto root = parseRootVar(argumentsJson);
    if (const auto* object = root.getDynamicObject()) {
        return varToDouble(object->getProperty(toJuceString(key)), fallback);
    }
    return fallback;
}

bool jsonGetBoolArg(const std::string& argumentsJson, const std::string& key, bool fallback) {
    const auto root = parseRootVar(argumentsJson);
    if (const auto* object = root.getDynamicObject()) {
        const auto value = object->getProperty(toJuceString(key));
        if (value.isBool()) {
            return static_cast<bool>(value);
        }
    }
    return fallback;
}

std::string buildBridgeOkWithSnapshot(const std::string& snapshotJson) {
    auto* root = new juce::DynamicObject();
    root->setProperty("ok", true);
    root->setProperty("snapshot", parseRootVar(snapshotJson));
    return toStdString(juce::JSON::toString(juce::var(root), false));
}

std::string buildBridgeOkTransportState(const TransportStateSnapshot& transport) {
    auto* root = new juce::DynamicObject();
    root->setProperty("ok", true);
    root->setProperty("playheadBeats", transport.playheadBeats);
    root->setProperty("playing", transport.playing);
    root->setProperty("bpm", transport.bpm);
    root->setProperty("loopEnabled", transport.loopEnabled);
    root->setProperty("loopLengthBeats", transport.loopLengthBeats);
    return toStdString(juce::JSON::toString(juce::var(root), false));
}

std::string buildBridgeOkWithPath(const std::string& path) {
    auto* root = new juce::DynamicObject();
    root->setProperty("ok", true);
    root->setProperty("path", toJuceString(path));
    return toStdString(juce::JSON::toString(juce::var(root), false));
}

std::string buildBridgeOkWithMessage(const std::string& message) {
    auto* root = new juce::DynamicObject();
    root->setProperty("ok", true);
    root->setProperty("message", toJuceString(message));
    return toStdString(juce::JSON::toString(juce::var(root), false));
}

std::string buildBridgeError(const std::string& errorCode) {
    auto* root = new juce::DynamicObject();
    root->setProperty("ok", false);
    root->setProperty("error", toJuceString(errorCode));
    return toStdString(juce::JSON::toString(juce::var(root), false));
}

} // namespace audioapp
