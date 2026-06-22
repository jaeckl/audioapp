#include "audioapp/ProjectJson.hpp"
#include "audioapp/SampleTypes.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"

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
    object->setProperty("naturalLengthBeats", clip.naturalLengthBeats);
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
        // Backwards-compatible: legacy projects predate the natural-length
        // field; default to the current length so the waveform still renders.
        clip.naturalLengthBeats =
            varToDouble(object->getProperty("naturalLengthBeats"), clip.lengthBeats);
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
    object->setProperty("homeTrackId", toJuceString(clip.homeTrackId));
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
        clip.homeTrackId = varToString(object->getProperty("homeTrackId"));
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

// --- LFO / modulation serialization helpers ---

juce::var lfoToVar(const LfoState& lfo) {
    auto* object = new juce::DynamicObject();
    object->setProperty("id", lfo.id);
    object->setProperty("modulatorType", lfo.modulatorType);
    object->setProperty("retrigger", lfo.retrigger);
    object->setProperty("waveform", lfo.waveform);
    object->setProperty("rate", static_cast<double>(lfo.rate));
    object->setProperty("syncDivision", lfo.syncDivision);
    object->setProperty("phase", static_cast<double>(lfo.phase));
    object->setProperty("polarity", lfo.polarity);
    object->setProperty("attack", static_cast<double>(lfo.attack));
    object->setProperty("decay", static_cast<double>(lfo.decay));
    object->setProperty("sustain", static_cast<double>(lfo.sustain));
    object->setProperty("release", static_cast<double>(lfo.release));
    return juce::var(object);
}

LfoState lfoFromVar(const juce::var& value) {
    LfoState lfo;
    if (const auto* object = value.getDynamicObject()) {
        lfo.id = varToInt(object->getProperty("id"), 0);
        lfo.modulatorType = varToInt(object->getProperty("modulatorType"), 0);
        lfo.retrigger = varToInt(object->getProperty("retrigger"), 0);
        lfo.waveform = varToInt(object->getProperty("waveform"), 0);
        lfo.rate = varToFloat(object->getProperty("rate"), 1.0f);
        lfo.syncDivision = varToInt(object->getProperty("syncDivision"), 0);
        lfo.phase = varToFloat(object->getProperty("phase"), 0.0f);
        lfo.polarity = varToInt(object->getProperty("polarity"), 0);
        lfo.attack = varToFloat(object->getProperty("attack"), 0.1f);
        lfo.decay = varToFloat(object->getProperty("decay"), 0.25f);
        lfo.sustain = varToFloat(object->getProperty("sustain"), 0.7f);
        lfo.release = varToFloat(object->getProperty("release"), 0.35f);
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

juce::var automationClipArrayToVar(const std::vector<AutomationClipState>& clips) {
    juce::Array<juce::var> result;
    result.ensureStorageAllocated(static_cast<int>(clips.size()));
    for (const auto& clip : clips) {
        result.add(automationClipToVar(clip));
    }
    return juce::var(result);
}

std::vector<AutomationClipState> automationClipArrayFromVar(const juce::var& value) {
    std::vector<AutomationClipState> result;
    if (const auto* arr = varArray(value)) {
        result.reserve(static_cast<size_t>(arr->size()));
        for (const auto& item : *arr) {
            result.push_back(automationClipFromVar(item));
        }
    }
    return result;
}

// Forward declaration — defined below in this namespace.
juce::var trackToVarSnapshot(const TrackState& track,
                              const DeviceRegistry& registry);

juce::var snapshotToVar(const ProjectSnapshot& snapshot,
                         const DeviceRegistry& registry) {
    juce::Array<juce::var> tracks;
    tracks.ensureStorageAllocated(static_cast<int>(snapshot.tracks.size()));
    for (const auto& track : snapshot.tracks) {
        tracks.add(trackToVarSnapshot(track, registry));
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
    object->setProperty("loopRegionStartBeat", snapshot.loopRegionStartBeat);
    object->setProperty("loopRegionEndBeat", snapshot.loopRegionEndBeat);
    object->setProperty("loopLengthBeats", snapshot.loopLengthBeats());
    object->setProperty("recordArmed", snapshot.recordArmed);
    object->setProperty("selectedTrackId", toJuceString(snapshot.selectedTrackId));
    object->setProperty("master", juce::var(master));
    object->setProperty("samples", samples);
    object->setProperty("tracks", tracks);
    object->setProperty("lfos", lfoArrayToVar(snapshot.lfos));
    object->setProperty("modEdges", modEdgeArrayToVar(snapshot.modEdges));
    object->setProperty("automationClips", automationClipArrayToVar(snapshot.automationClips));
    return juce::var(object);
}

// --- Persistence-only track serializers (Phase 2) ---

// Forward declarations for persistence track serializers (defined below in this namespace).
juce::var trackToVarPersistence(const TrackState& track,
                                 const DeviceRegistry& registry);
TrackState trackFromVarPersistence(const juce::var& value,
                                    const DeviceRegistry& registry);

juce::var projectFileToVar(const ProjectFileData& project,
                            const DeviceRegistry& registry) {
    juce::Array<juce::var> tracks;
    tracks.ensureStorageAllocated(static_cast<int>(project.tracks.size()));
    for (const auto& track : project.tracks) {
        tracks.add(trackToVarPersistence(track, registry));
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
    object->setProperty("automationClips", automationClipArrayToVar(project.automationClips));
    return juce::var(object);
}

// --- DeviceSlot-based serialization dispatch (Package 0) ---

juce::var deviceSlotToVarImpl(const DeviceSlot& slot, const DeviceRegistry& registry) {
    // Try the device type's own slotToVar first.
    const IDeviceType* type = registry.findTypeForSlot(slot);
    if (type != nullptr) {
        juce::var result = type->slotToVar(slot);
        if (!result.isVoid() && !result.isUndefined()) {
            return result;
        }
    }
    // All device types should have migrated slotToVar by now.
    // Return empty var if not found (should not happen).
    return {};
}

DeviceSlot deviceVarToSlotImpl(const juce::var& obj, const DeviceRegistry& registry) {
    // Try the device type's own varToSlot first.
    if (const auto* object = obj.getDynamicObject()) {
        const std::string typeId = varToString(object->getProperty("type"));
        const IDeviceType* type = registry.find(typeId);
        if (type != nullptr) {
            DeviceSlot slot = type->varToSlot(obj);
            if (!slot.id.empty()) {
                return slot;
            }
        }
    }
    // All device types should have migrated varToSlot by now.
    // Return empty slot if not found (should not happen).
    return {};
}

// --- Persistence-only track serializers (Phase 2) ---

juce::var trackToVarPersistence(const TrackState& track,
                                 const DeviceRegistry& registry) {
    juce::Array<juce::var> devices;
    devices.ensureStorageAllocated(static_cast<int>(track.devices.size()));
    for (const auto& device : track.devices) {
        devices.add(deviceSlotToVarImpl(device, registry));
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

TrackState trackFromVarPersistence(const juce::var& value,
                                    const DeviceRegistry& registry) {
    TrackState track;
    if (const auto* object = value.getDynamicObject()) {
        track.id = varToString(object->getProperty("id"));
        track.name = varToString(object->getProperty("name"));
        if (const auto* devices = varArray(object->getProperty("devices"))) {
            for (const auto& deviceVar : *devices) {
                track.devices.push_back(
                    deviceVarToSlotImpl(deviceVar, registry));
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

// --- Snapshot track serializer (Phase 3) ---

juce::var trackToVarSnapshot(const TrackState& track,
                              const DeviceRegistry& registry) {
    juce::Array<juce::var> devices;
    devices.ensureStorageAllocated(static_cast<int>(track.devices.size()));
    for (size_t i = 0; i < track.devices.size(); ++i) {
        // Step 1: Serialize device params via registry dispatch (writes meters=0.0)
        juce::var deviceVar = deviceSlotToVarImpl(track.devices[i], registry);

        // Step 2: Inject live meter values from parallel array
        for (const auto& meter : track.deviceMeters) {
            if (meter.deviceId == track.devices[i].id) {
                if (auto* obj = deviceVar.getDynamicObject()) {
                    auto* metersObj = new juce::DynamicObject();
                    metersObj->setProperty("gainReductionDb",
                        static_cast<double>(meter.gainReductionDb));
                    metersObj->setProperty("inputLevel",
                        static_cast<double>(meter.inputLevel));
                    obj->setProperty("meters", juce::var(metersObj));
                }
                break;
            }
        }
        devices.add(deviceVar);
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

} // namespace

std::string deviceSlotToVar(const DeviceSlot& slot, const DeviceRegistry& registry) {
    return toStdString(juce::JSON::toString(deviceSlotToVarImpl(slot, registry), false));
}

DeviceSlot deviceVarToSlot(const std::string& json, const DeviceRegistry& registry) {
    return deviceVarToSlotImpl(parseRootVar(json), registry);
}

juce::var deviceToVar(const DeviceSlot& slot, const DeviceRegistry& registry) {
    return deviceSlotToVarImpl(slot, registry);
}

DeviceSlot deviceFromVar(const juce::var& value, const DeviceRegistry& registry) {
    return deviceVarToSlotImpl(value, registry);
}

std::string snapshotToJson(const ProjectSnapshot& snapshot,
                            const DeviceRegistry& registry) {
    return toStdString(juce::JSON::toString(snapshotToVar(snapshot, registry), false));
}

std::string projectFileToJson(const ProjectFileData& project,
                               const DeviceRegistry& registry) {
    return toStdString(juce::JSON::toString(projectFileToVar(project, registry), true));
}

bool parseProjectFileJson(const std::string& json,
                          ProjectFileData& out,
                          const DeviceRegistry& registry) {
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
            out.tracks.push_back(trackFromVarPersistence(trackVar, registry));
        }
    }

    if (object->hasProperty("lfos")) {
        out.lfos = lfoArrayFromVar(object->getProperty("lfos"));
    }
    if (object->hasProperty("modEdges")) {
        out.modEdges = modEdgeArrayFromVar(object->getProperty("modEdges"));
    }

    // Automation clips live in the top-level array.
    out.automationClips.clear();
    if (object->hasProperty("automationClips")) {
        out.automationClips = automationClipArrayFromVar(object->getProperty("automationClips"));
    }
    for (auto& clip : out.automationClips) {
        if (clip.homeTrackId.empty()) {
            clip.homeTrackId = out.selectedTrackId;
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

bool parseSubtractivePresetArgs(const std::string& argumentsJson, SubtractivePresetArgs& out) {
    out = {};
    const auto root = parseRootVar(argumentsJson);
    const auto* object = root.getDynamicObject();
    if (object == nullptr) {
        return false;
    }

    out.deviceId = varToString(object->getProperty("deviceId"));
    if (out.deviceId.empty()) {
        return false;
    }

    if (const auto* paramsObject = object->getProperty("params").getDynamicObject()) {
        for (const auto& prop : paramsObject->getProperties()) {
            out.params.emplace_back(prop.name.toString().toStdString(),
                                    varToFloat(prop.value, 0.0f));
        }
    }

    if (const auto* lfoArray = varArray(object->getProperty("lfos"))) {
        out.lfos.reserve(static_cast<size_t>(lfoArray->size()));
        for (const auto& lfoVar : *lfoArray) {
            const auto* lfoObject = lfoVar.getDynamicObject();
            if (lfoObject == nullptr) {
                continue;
            }
            ProjectEngine::SubtractivePresetLfoSpec spec;
            spec.waveform = varToInt(lfoObject->getProperty("waveform"), 0);
            spec.rate = varToFloat(lfoObject->getProperty("rate"), 1.0f);
            spec.syncDivision = varToInt(lfoObject->getProperty("syncDivision"), 0);
            spec.phase = varToFloat(lfoObject->getProperty("phase"), 0.0f);
            spec.polarity = varToInt(lfoObject->getProperty("polarity"), 0);
            out.lfos.push_back(spec);
        }
    }

    if (const auto* modArray = varArray(object->getProperty("mods"))) {
        out.mods.reserve(static_cast<size_t>(modArray->size()));
        for (const auto& modVar : *modArray) {
            const auto* modObject = modVar.getDynamicObject();
            if (modObject == nullptr) {
                continue;
            }
            ProjectEngine::SubtractivePresetModSpec spec;
            spec.lfoIndex = varToInt(modObject->getProperty("lfoIndex"), 0);
            spec.paramId = varToString(modObject->getProperty("paramId"));
            spec.amount = varToFloat(modObject->getProperty("amount"), 0.0f);
            if (spec.paramId.empty()) {
                return false;
            }
            out.mods.push_back(spec);
        }
    }

    return !out.params.empty();
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
    root->setProperty("loopRegionStartBeat", transport.loopRegionStartBeat);
    root->setProperty("loopRegionEndBeat", transport.loopRegionEndBeat);
    root->setProperty("loopLengthBeats", transport.loopLengthBeats());
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
