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
    if (device.type == "track_gain" || device.type == "simple_sampler") {
        parameters->setProperty("gain", static_cast<double>(device.gain));
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
    }
    if (device.type == "simple_oscillator") {
        parameters->setProperty("frequency", static_cast<double>(device.frequencyHz));
    }

    auto* object = new juce::DynamicObject();
    object->setProperty("id", toJuceString(device.id));
    object->setProperty("type", toJuceString(device.type));
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
            device.sampleId = varToString(params->getProperty("sampleId"));
            device.attack = varToFloat(params->getProperty("attack"), 0.01f);
            device.decay = varToFloat(params->getProperty("decay"), 0.3f);
            device.sustain = varToFloat(params->getProperty("sustain"), 0.7f);
            device.release = varToFloat(params->getProperty("release"), 0.4f);
            device.filterCutoff = varToFloat(params->getProperty("filterCutoff"), 1.0f);
            device.filterQ = varToFloat(params->getProperty("filterQ"), 0.35f);
            device.filterMode = varToInt(params->getProperty("filterMode"), 0);
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

    auto* object = new juce::DynamicObject();
    object->setProperty("id", toJuceString(track.id));
    object->setProperty("name", toJuceString(track.name));
    object->setProperty("devices", devices);
    object->setProperty("midiClips", clips);
    object->setProperty("sampleClips", sampleClips);
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
    }
    return track;
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
    object->setProperty("selectedTrackId", toJuceString(snapshot.selectedTrackId));
    object->setProperty("master", juce::var(master));
    object->setProperty("samples", samples);
    object->setProperty("tracks", tracks);
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

std::string buildBridgeOkWithSnapshot(const std::string& snapshotJson) {
    auto* root = new juce::DynamicObject();
    root->setProperty("ok", true);
    root->setProperty("snapshot", parseRootVar(snapshotJson));
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
