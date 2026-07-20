#include "audioapp/ProjectJson.hpp"
#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/SampleTypes.hpp"
#include "audioapp/TrackFreeze.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/modulation/LfoModulatorType.hpp"
#include "audioapp/modulation/EnvelopeModulatorType.hpp"

#include <juce_core/juce_core.h>

#include <unordered_set>

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

const char* migratedHihatParam(std::string_view oldName) noexcept {
    if (oldName == "cymbalPitch") return "hihatPitch";
    if (oldName == "cymbalColor") return "hihatColor";
    if (oldName == "cymbalDecay") return "hihatDecay";
    if (oldName == "cymbalWidth") return "hihatWidth";
    if (oldName == "cymbalVelocity") return "hihatVelocity";
    if (oldName == "cymbalKeyTrack") return "hihatKeyTrack";
    return nullptr;
}

void migrateV1DeviceToV2(juce::var& value, std::unordered_set<std::string>& migratedIds) {
    auto* object = value.getDynamicObject();
    if (object == nullptr) return;
    if (object->getProperty("type").toString() == "cymbal_generator") {
        const auto id = object->getProperty("id").toString().toStdString();
        migratedIds.insert(id);
        object->setProperty("type", device_types::kHihatGenerator);
        if (auto* old = object->getProperty("parameters").getDynamicObject()) {
            if (object->getProperty("outputPanel").getDynamicObject() == nullptr) {
                auto* output = new juce::DynamicObject();
                output->setProperty("type", "mono");
                output->setProperty("gain", old->getProperty("gain"));
                object->setProperty("outputPanel", juce::var(output));
                object->setProperty("bypass", old->getProperty("bypass"));
            }
            auto* parameters = new juce::DynamicObject();
            parameters->setProperty("hihatPitch", old->getProperty("cymbalPitch"));
            parameters->setProperty("hihatColor", old->getProperty("cymbalColor"));
            parameters->setProperty("hihatDecay", old->getProperty("cymbalDecay"));
            parameters->setProperty("hihatWidth", old->getProperty("cymbalWidth"));
            parameters->setProperty("hihatVelocity", old->getProperty("cymbalVelocity"));
            parameters->setProperty("hihatKeyTrack", old->getProperty("cymbalKeyTrack"));
            parameters->setProperty("hihatTightness", 0.72);
            parameters->setProperty("hihatNoise", 0.34);
            object->setProperty("parameters", juce::var(parameters));
        }
    }
    const auto migrateArray = [&](const char* property) {
        if (auto* children = object->getProperty(property).getArray())
            for (auto& child : *children) migrateV1DeviceToV2(child, migratedIds);
    };
    migrateArray("devices");
    migrateArray("audioFxDevices");
    migrateArray("noteFxDevices");
    if (auto* pads = object->getProperty("pads").getArray()) {
        for (auto& pad : *pads)
            if (auto* padObject = pad.getDynamicObject())
                if (auto* devices = padObject->getProperty("devices").getArray())
                    for (auto& child : *devices) migrateV1DeviceToV2(child, migratedIds);
    }
}

bool migrateProjectVarToCurrent(juce::var& root) {
    auto* object = root.getDynamicObject();
    if (object == nullptr) return false;
    const int version = static_cast<int>(object->getProperty("project_format_version"));
    if (version == kProjectFormatVersion) return true;
    if (version != 1) return false;

    std::unordered_set<std::string> migratedIds;
    if (auto* tracks = object->getProperty("tracks").getArray()) {
        for (auto& track : *tracks) {
            if (auto* trackObject = track.getDynamicObject())
                if (auto* devices = trackObject->getProperty("devices").getArray())
                    for (auto& device : *devices) migrateV1DeviceToV2(device, migratedIds);
        }
    }
    const auto migrateTargets = [&](const char* property) {
        if (auto* targets = object->getProperty(property).getArray()) {
            for (auto& target : *targets) {
                auto* targetObject = target.getDynamicObject();
                if (targetObject == nullptr) continue;
                const auto id = targetObject->getProperty("deviceId").toString().toStdString();
                if (!migratedIds.contains(id)) continue;
                const auto oldParam = targetObject->getProperty("paramId").toString().toStdString();
                if (const char* replacement = migratedHihatParam(oldParam))
                    targetObject->setProperty("paramId", replacement);
            }
        }
    };
    migrateTargets("modEdges");
    migrateTargets("automationClips");
    object->setProperty("project_format_version", kProjectFormatVersion);
    return true;
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
    juce::Array<juce::var> takes;
    takes.ensureStorageAllocated(static_cast<int>(clip.takes.size()));
    for (const auto& take : clip.takes) {
        juce::Array<juce::var> takeNotes;
        takeNotes.ensureStorageAllocated(static_cast<int>(take.notes.size()));
        for (const auto& note : take.notes) {
            takeNotes.add(midiNoteToVar(note));
        }
        auto* takeObject = new juce::DynamicObject();
        takeObject->setProperty("id", toJuceString(take.id));
        takeObject->setProperty("name", toJuceString(take.name));
        takeObject->setProperty("startBeatOffset", take.startBeatOffset);
        takeObject->setProperty("lengthBeats", take.lengthBeats);
        takeObject->setProperty("notes", takeNotes);
        takes.add(juce::var(takeObject));
    }
    juce::Array<juce::var> takeRegions;
    takeRegions.ensureStorageAllocated(static_cast<int>(clip.activeTakeRegions.size()));
    for (const auto& region : clip.activeTakeRegions) {
        auto* regionObject = new juce::DynamicObject();
        regionObject->setProperty("startBeat", region.startBeat);
        regionObject->setProperty("endBeat", region.endBeat);
        regionObject->setProperty("takeId", toJuceString(region.takeId));
        regionObject->setProperty("sourceStart", region.sourceStart);
        regionObject->setProperty("holdPrevious", region.holdPrevious);
        takeRegions.add(juce::var(regionObject));
    }

    auto* object = new juce::DynamicObject();
    object->setProperty("id", toJuceString(clip.id));
    object->setProperty("startBeat", clip.startBeat);
    object->setProperty("lengthBeats", clip.lengthBeats);
    object->setProperty("naturalLengthBeats", clip.naturalLengthBeats);
    object->setProperty("loopContent", clip.loopContent);
    object->setProperty("editorScaleRoot", clip.editorScaleRoot);
    object->setProperty("editorScaleId", toJuceString(clip.editorScaleId));
    object->setProperty("editorScaleHighlight", clip.editorScaleHighlight);
    object->setProperty("editorScaleSnap", clip.editorScaleSnap);
    object->setProperty("editorChordQuality", toJuceString(clip.editorChordQuality));
    object->setProperty("notes", notes);
    object->setProperty("takes", takes);
    object->setProperty("activeTakeRegions", takeRegions);
    object->setProperty("compFlattened", clip.compFlattened);
    return juce::var(object);
}

MidiClipState midiClipFromVar(const juce::var& value) {
    MidiClipState clip;
    if (const auto* object = value.getDynamicObject()) {
        clip.id = varToString(object->getProperty("id"));
        clip.startBeat = varToDouble(object->getProperty("startBeat"), 0.0);
        clip.lengthBeats = varToDouble(object->getProperty("lengthBeats"), 4.0);
        clip.naturalLengthBeats =
            varToDouble(object->getProperty("naturalLengthBeats"), clip.lengthBeats);
        clip.loopContent = static_cast<bool>(object->getProperty("loopContent"));
        clip.editorScaleRoot = varToInt(object->getProperty("editorScaleRoot"), 0);
        clip.editorScaleId = varToString(object->getProperty("editorScaleId"));
        if (clip.editorScaleId.empty()) {
            clip.editorScaleId = "major";
        }
        clip.editorScaleHighlight =
            object->hasProperty("editorScaleHighlight")
                ? static_cast<bool>(object->getProperty("editorScaleHighlight"))
                : false;
        clip.editorScaleSnap = static_cast<bool>(object->getProperty("editorScaleSnap"));
        clip.editorChordQuality = varToString(object->getProperty("editorChordQuality"));
        if (clip.editorChordQuality.empty()) {
            clip.editorChordQuality = "off";
        }
        if (const auto* notes = varArray(object->getProperty("notes"))) {
            clip.notes.reserve(static_cast<size_t>(notes->size()));
            for (const auto& noteVar : *notes) {
                clip.notes.push_back(midiNoteFromVar(noteVar));
            }
        }
        if (const auto* takes = varArray(object->getProperty("takes"))) {
            clip.takes.reserve(static_cast<size_t>(takes->size()));
            for (const auto& takeVar : *takes) {
                if (const auto* takeObject = takeVar.getDynamicObject()) {
                    MidiClipTakeState take;
                    take.id = varToString(takeObject->getProperty("id"));
                    take.name = varToString(takeObject->getProperty("name"));
                    take.startBeatOffset = varToDouble(takeObject->getProperty("startBeatOffset"), 0.0);
                    take.lengthBeats = varToDouble(takeObject->getProperty("lengthBeats"), clip.lengthBeats);
                    if (const auto* takeNotes = varArray(takeObject->getProperty("notes"))) {
                        for (const auto& noteVar : *takeNotes) {
                            take.notes.push_back(midiNoteFromVar(noteVar));
                        }
                    }
                    clip.takes.push_back(std::move(take));
                }
            }
        }
        if (const auto* regions = varArray(object->getProperty("activeTakeRegions"))) {
            clip.activeTakeRegions.reserve(static_cast<size_t>(regions->size()));
            for (const auto& regionVar : *regions) {
                if (const auto* regionObject = regionVar.getDynamicObject()) {
                    MidiClipTakeRegionState region;
                    region.startBeat = varToDouble(regionObject->getProperty("startBeat"), 0.0);
                    region.endBeat = varToDouble(regionObject->getProperty("endBeat"), clip.lengthBeats);
                    region.takeId = varToString(regionObject->getProperty("takeId"));
                    region.sourceStart = varToDouble(regionObject->getProperty("sourceStart"), 0.0);
                    if (regionObject->hasProperty("holdPrevious")) {
                        region.holdPrevious =
                            static_cast<bool>(regionObject->getProperty("holdPrevious"));
                    }
                    clip.activeTakeRegions.push_back(std::move(region));
                }
            }
        }
        if (object->hasProperty("compFlattened")) {
            clip.compFlattened =
                static_cast<bool>(object->getProperty("compFlattened"));
        }
        if (!object->hasProperty("naturalLengthBeats")) {
            const double noteEnd = midiNotesContentLengthBeats(clip.notes, 0.0);
            clip.naturalLengthBeats = noteEnd > 0.0 ? noteEnd : clip.lengthBeats;
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
    juce::Array<juce::var> slices;
    for (const auto marker : clip.sliceMarkers) slices.add(marker);
    juce::Array<juce::var> takes;
    takes.ensureStorageAllocated(static_cast<int>(clip.takes.size()));
    for (const auto& take : clip.takes) {
        auto* takeObject = new juce::DynamicObject();
        takeObject->setProperty("id", toJuceString(take.id));
        takeObject->setProperty("sampleId", toJuceString(take.sampleId));
        takeObject->setProperty("name", toJuceString(take.name));
        takeObject->setProperty("startBeatOffset", take.startBeatOffset);
        takeObject->setProperty("lengthBeats", take.lengthBeats);
        takes.add(juce::var(takeObject));
    }
    juce::Array<juce::var> takeRegions;
    takeRegions.ensureStorageAllocated(static_cast<int>(clip.activeTakeRegions.size()));
    for (const auto& region : clip.activeTakeRegions) {
        auto* regionObject = new juce::DynamicObject();
        regionObject->setProperty("startBeat", region.startBeat);
        regionObject->setProperty("endBeat", region.endBeat);
        regionObject->setProperty("takeId", toJuceString(region.takeId));
        regionObject->setProperty("sourceStart", region.sourceStart);
        takeRegions.add(juce::var(regionObject));
    }

    auto* object = new juce::DynamicObject();
    object->setProperty("id", toJuceString(clip.id));
    object->setProperty("sampleId", toJuceString(clip.sampleId));
    object->setProperty("sampleName", toJuceString(clip.sampleName));
    object->setProperty("startBeat", clip.startBeat);
    object->setProperty("lengthBeats", clip.lengthBeats);
    object->setProperty("naturalLengthBeats", clip.naturalLengthBeats);
    object->setProperty("loopContent", clip.loopContent);
    object->setProperty("sourceStart", clip.sourceStart);
    object->setProperty("sourceEnd", clip.sourceEnd);
    object->setProperty("gain", clip.gain);
    object->setProperty("fadeIn", clip.fadeIn);
    object->setProperty("fadeOut", clip.fadeOut);
    object->setProperty("fadeInCurve", clip.fadeInCurve);
    object->setProperty("fadeOutCurve", clip.fadeOutCurve);
    object->setProperty("reversed", clip.reversed);
    object->setProperty("warpRepitch", clip.warpRepitch);
    object->setProperty("sliceMarkers", slices);
    object->setProperty("waveformPeaks", peaks);
    object->setProperty("takes", takes);
    object->setProperty("activeTakeRegions", takeRegions);
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
        clip.naturalLengthBeats =
            varToDouble(object->getProperty("naturalLengthBeats"), clip.lengthBeats);
        clip.loopContent = static_cast<bool>(object->getProperty("loopContent"));
        clip.sourceStart = varToFloat(object->getProperty("sourceStart"), 0.0f);
        clip.sourceEnd = varToFloat(object->getProperty("sourceEnd"), 1.0f);
        clip.gain = varToFloat(object->getProperty("gain"), 1.0f);
        clip.fadeIn = varToFloat(object->getProperty("fadeIn"), 0.0f);
        clip.fadeOut = varToFloat(object->getProperty("fadeOut"), 0.0f);
        clip.fadeInCurve = varToFloat(object->getProperty("fadeInCurve"), 0.5f);
        clip.fadeOutCurve = varToFloat(object->getProperty("fadeOutCurve"), 0.5f);
        clip.reversed = static_cast<bool>(object->getProperty("reversed"));
        clip.warpRepitch = static_cast<bool>(object->getProperty("warpRepitch"));
        if (const auto* markers = varArray(object->getProperty("sliceMarkers"))) {
            for (const auto& marker : *markers)
                clip.sliceMarkers.push_back(varToFloat(marker, 0.0f));
        }
        if (const auto* peakArray = varArray(object->getProperty("waveformPeaks"))) {
            clip.waveformPeaks.reserve(static_cast<size_t>(peakArray->size()));
            for (const auto& peakVar : *peakArray) {
                clip.waveformPeaks.push_back(varToFloat(peakVar, 0.0f));
            }
        }
        if (const auto* takes = varArray(object->getProperty("takes"))) {
            clip.takes.reserve(static_cast<size_t>(takes->size()));
            for (const auto& takeVar : *takes) {
                if (const auto* takeObject = takeVar.getDynamicObject()) {
                    SampleClipTakeState take;
                    take.id = varToString(takeObject->getProperty("id"));
                    take.sampleId = varToString(takeObject->getProperty("sampleId"));
                    take.name = varToString(takeObject->getProperty("name"));
                    take.startBeatOffset = varToDouble(takeObject->getProperty("startBeatOffset"), 0.0);
                    take.lengthBeats = varToDouble(takeObject->getProperty("lengthBeats"), clip.lengthBeats);
                    clip.takes.push_back(std::move(take));
                }
            }
        }
        if (const auto* regions = varArray(object->getProperty("activeTakeRegions"))) {
            clip.activeTakeRegions.reserve(static_cast<size_t>(regions->size()));
            for (const auto& regionVar : *regions) {
                if (const auto* regionObject = regionVar.getDynamicObject()) {
                    SampleClipTakeRegionState region;
                    region.startBeat = varToDouble(regionObject->getProperty("startBeat"), 0.0);
                    region.endBeat = varToDouble(regionObject->getProperty("endBeat"), clip.lengthBeats);
                    region.takeId = varToString(regionObject->getProperty("takeId"));
                    region.sourceStart = varToDouble(regionObject->getProperty("sourceStart"), 0.0);
                    clip.activeTakeRegions.push_back(std::move(region));
                }
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
    object->setProperty("naturalLengthBeats", clip.naturalLengthBeats);
    object->setProperty("loopContent", clip.loopContent);
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
        clip.naturalLengthBeats =
            varToDouble(object->getProperty("naturalLengthBeats"), clip.lengthBeats);
        clip.loopContent = static_cast<bool>(object->getProperty("loopContent"));
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
        if (!object->hasProperty("naturalLengthBeats")) {
            const double pointEnd = automationPointsContentLengthBeats(clip.points, 0.0);
            clip.naturalLengthBeats = pointEnd > 0.0 ? pointEnd : clip.lengthBeats;
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

// --- Modulation serialization: dispatch through IModulatorType ---

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
juce::var deviceSlotToVarImpl(const DeviceSlot& slot, const DeviceRegistry& registry);

juce::var snapshotToVar(const ProjectSnapshot& snapshot,
                         const DeviceRegistry& registry,
                         const std::vector<std::unique_ptr<IModulatorType>>& modTypes) {
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
    master->setProperty("muted", snapshot.master.muted);
    {
        juce::Array<juce::var> devices;
        for (const auto& device : snapshot.master.devices) {
            devices.add(deviceSlotToVarImpl(device, registry));
        }
        master->setProperty("devices", devices);
        juce::Array<juce::var> midiClips;
        for (const auto& clip : snapshot.master.midiClips) {
            midiClips.add(midiClipToVar(clip));
        }
        master->setProperty("midiClips", midiClips);
        juce::Array<juce::var> sampleClips;
        for (const auto& clip : snapshot.master.sampleClips) {
            sampleClips.add(sampleClipToVar(clip));
        }
        master->setProperty("sampleClips", sampleClips);
    }

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
    object->setProperty("lfos", modulatorRecordsToVar(snapshot.lfos, modTypes));
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
                            const DeviceRegistry& registry,
                            const std::vector<std::unique_ptr<IModulatorType>>& modTypes) {
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
    object->setProperty("loopEnabled", project.loopEnabled);
    object->setProperty("loopRegionStartBeat", project.loopRegionStartBeat);
    object->setProperty("loopRegionEndBeat", project.loopRegionEndBeat);
    auto* master = new juce::DynamicObject();
    master->setProperty("id", toJuceString(project.master.id));
    master->setProperty("name", toJuceString(project.master.name));
    master->setProperty("gain", static_cast<double>(project.master.gain));
    master->setProperty("muted", project.master.muted);
    {
        juce::Array<juce::var> devices;
        for (const auto& device : project.master.devices) {
            devices.add(deviceSlotToVarImpl(device, registry));
        }
        master->setProperty("devices", devices);
        juce::Array<juce::var> midiClips;
        for (const auto& clip : project.master.midiClips) {
            midiClips.add(midiClipToVar(clip));
        }
        master->setProperty("midiClips", midiClips);
        juce::Array<juce::var> sampleClips;
        for (const auto& clip : project.master.sampleClips) {
            sampleClips.add(sampleClipToVar(clip));
        }
        master->setProperty("sampleClips", sampleClips);
    }
    object->setProperty("master", juce::var(master));
    object->setProperty("samples", samples);
    object->setProperty("tracks", tracks);
    object->setProperty("lfos", modulatorRecordsToVar(project.lfos, modTypes));
    object->setProperty("modEdges", modEdgeArrayToVar(project.modEdges));
    object->setProperty("automationClips", automationClipArrayToVar(project.automationClips));
    return juce::var(object);
}

// --- DeviceSlot-based serialization dispatch (Package 0) ---

DeviceSlot deviceVarToSlotImpl(const juce::var& obj, const DeviceRegistry& registry);

juce::var deviceSlotToVarImpl(const DeviceSlot& slot, const DeviceRegistry& registry) {
    if (slot.config.typeId == device_types::kChain) {
        const auto& chain = std::get<ChainModel>(slot.config.instance);
        const IDeviceType* type = registry.findForSlot(slot);
        juce::var result = type != nullptr ? type->slotToVar(slot) : juce::var{};
        if (auto* object = result.getDynamicObject()) {
            juce::Array<juce::var> devices;
            for (const auto& device : chain.devices) {
                if (device != nullptr) {
                    devices.add(deviceSlotToVarImpl(*device, registry));
                }
            }
            object->setProperty("devices", devices);
        }
        return result;
    }
    if (device_types::isSplitType(slot.config.typeId)) {
        const auto& split = std::get<SplitModel>(slot.config.instance);
        const IDeviceType* type = registry.findForSlot(slot);
        juce::var result = type != nullptr ? type->slotToVar(slot) : juce::var{};
        if (auto* object = result.getDynamicObject()) {
            const std::vector<std::shared_ptr<DeviceSlot>>* sides[2] = {&split.branch0, &split.branch1};
            juce::Array<juce::var> branches;
            for (const auto* side : sides) {
                juce::Array<juce::var> devices;
                for (const auto& device : *side) {
                    if (device != nullptr) {
                        devices.add(deviceSlotToVarImpl(*device, registry));
                    }
                }
                auto* branchObject = new juce::DynamicObject();
                branchObject->setProperty("devices", devices);
                branches.add(juce::var(branchObject));
            }
            object->setProperty("branches", branches);
        }
        return result;
    }
    if (device_types::isMultibandSplitType(slot.config.typeId)) {
        const auto& mb = std::get<MultibandSplitModel>(slot.config.instance);
        const IDeviceType* type = registry.findForSlot(slot);
        juce::var result = type != nullptr ? type->slotToVar(slot) : juce::var{};
        if (auto* object = result.getDynamicObject()) {
            juce::Array<juce::var> bands;
            for (int b = 0; b < mb.bandCount && b < kMaxMbBands; ++b) {
                juce::Array<juce::var> devices;
                for (const auto& device : mb.bands[b]) {
                    if (device != nullptr) {
                        devices.add(deviceSlotToVarImpl(*device, registry));
                    }
                }
                auto* bandObject = new juce::DynamicObject();
                bandObject->setProperty("devices", devices);
                bands.add(juce::var(bandObject));
            }
            object->setProperty("bands", bands);
        }
        return result;
    }
    if (device_types::isSpectralLoudSplitType(slot.config.typeId)) {
        const auto& sl = std::get<SpectralLoudSplitModel>(slot.config.instance);
        const IDeviceType* type = registry.findForSlot(slot);
        juce::var result = type != nullptr ? type->slotToVar(slot) : juce::var{};
        if (auto* object = result.getDynamicObject()) {
            auto writeDevices = [&](const std::vector<std::shared_ptr<DeviceSlot>>& list) {
                juce::Array<juce::var> devices;
                for (const auto& device : list) {
                    if (device != nullptr) {
                        devices.add(deviceSlotToVarImpl(*device, registry));
                    }
                }
                return devices;
            };
            juce::Array<juce::var> bands;
            for (int b = 0; b < kSpectralLoudBands; ++b) {
                auto* bandObject = new juce::DynamicObject();
                bandObject->setProperty("devices", writeDevices(sl.bands[b]));
                bands.add(juce::var(bandObject));
            }
            object->setProperty("bands", bands);
            auto* preObj = new juce::DynamicObject();
            preObj->setProperty("devices", writeDevices(sl.preFxDevices));
            object->setProperty("preFx", juce::var(preObj));
            auto* postObj = new juce::DynamicObject();
            postObj->setProperty("devices", writeDevices(sl.postFxDevices));
            object->setProperty("postFx", juce::var(postObj));
        }
        return result;
    }
    if (slot.config.typeId == device_types::kDrumMachine) {
        const auto& machine = std::get<DrumMachineModel>(slot.config.instance);
        juce::Array<juce::var> pads;
        for (const auto& pad : machine.pads) {
            if (pad.devices.empty() && pad.name.empty() && pad.gain == 1.0f &&
                pad.pan == 0.5f && !pad.muted && !pad.solo && pad.chokeGroup == 0) {
                continue;
            }
            auto* padObject = new juce::DynamicObject();
            padObject->setProperty("note", pad.note);
            padObject->setProperty("name", toJuceString(pad.name));
            padObject->setProperty("gain", static_cast<double>(pad.gain));
            padObject->setProperty("pan", static_cast<double>(pad.pan));
            padObject->setProperty("muted", pad.muted);
            padObject->setProperty("solo", pad.solo);
            padObject->setProperty("chokeGroup", pad.chokeGroup);
            juce::Array<juce::var> devices;
            for (const auto& device : pad.devices) {
                if (device != nullptr) {
                    devices.add(deviceSlotToVarImpl(*device, registry));
                }
            }
            padObject->setProperty("devices", devices);
            pads.add(juce::var(padObject));
        }
        auto* object = new juce::DynamicObject();
        object->setProperty("id", toJuceString(slot.id));
        object->setProperty("type", device_types::kDrumMachine);
        object->setProperty("bypass", slot.config.bypassed);
        if (const auto* panel = std::get_if<StereoOutputPanel>(&slot.config.outputPanel)) {
            auto* output = new juce::DynamicObject();
            output->setProperty("type", "stereo");
            output->setProperty("gain", static_cast<double>(panel->gain));
            output->setProperty("pan", static_cast<double>(panel->pan));
            output->setProperty("outputMix", static_cast<double>(panel->outputMix));
            output->setProperty("outputWidth", static_cast<double>(panel->outputWidth));
            object->setProperty("outputPanel", juce::var(output));
        }
        object->setProperty("pads", pads);
        return juce::var(object);
    }
    if (device_types::isSynthType(slot.config.typeId) ||
        device_types::isSidechainFxHost(slot.config.typeId)) {
        const IDeviceType* type = registry.findForSlot(slot);
        juce::var result = type != nullptr ? type->slotToVar(slot) : juce::var{};
        if (auto* object = result.getDynamicObject()) {
            if (!slot.audioFxDevices.empty()) {
                juce::Array<juce::var> devices;
                for (const auto& child : slot.audioFxDevices) {
                    if (child != nullptr) {
                        devices.add(deviceSlotToVarImpl(*child, registry));
                    }
                }
                object->setProperty("audioFxDevices", devices);
            }
            if (device_types::isSynthType(slot.config.typeId) &&
                !slot.noteFxDevices.empty()) {
                juce::Array<juce::var> devices;
                for (const auto& child : slot.noteFxDevices) {
                    if (child != nullptr) {
                        devices.add(deviceSlotToVarImpl(*child, registry));
                    }
                }
                object->setProperty("noteFxDevices", devices);
            }
        }
        return result;
    }
    const IDeviceType* type = registry.findForSlot(slot);
    if (type != nullptr) {
        juce::var result = type->slotToVar(slot);
        if (!result.isVoid() && !result.isUndefined()) {
            return result;
        }
    }
    return {};
}

DeviceSlot deviceVarToSlotImpl(const juce::var& obj, const DeviceRegistry& registry) {
    if (const auto* object = obj.getDynamicObject()) {
        const std::string typeId = varToString(object->getProperty("type"));
        if (typeId == device_types::kChain) {
            const IDeviceType* type = registry.find(typeId);
            if (type == nullptr) return {};
            DeviceSlot slot = type->varToSlot(obj);
            if (slot.id.empty()) return {};
            slot.config.bypassed = static_cast<bool>(object->getProperty("bypass"));
            auto& chain = std::get<ChainModel>(slot.config.instance);
            if (const auto* devices = varArray(object->getProperty("devices"))) {
                for (const auto& value : *devices) {
                    if (chain.devices.size() >= 8) break;
                    DeviceSlot child = deviceVarToSlotImpl(value, registry);
                    if (!child.id.empty()) {
                        chain.devices.push_back(std::make_shared<DeviceSlot>(std::move(child)));
                    }
                }
            }
            return slot;
        }
        if (device_types::isSplitType(typeId)) {
            const IDeviceType* type = registry.find(typeId);
            if (type == nullptr) return {};
            DeviceSlot slot = type->varToSlot(obj);
            if (slot.id.empty()) return {};
            slot.config.bypassed = static_cast<bool>(object->getProperty("bypass"));
            auto& split = std::get<SplitModel>(slot.config.instance);
            std::vector<std::shared_ptr<DeviceSlot>>* sides[2] = {&split.branch0, &split.branch1};
            if (const auto* branches = varArray(object->getProperty("branches"))) {
                for (int branchIndex = 0; branchIndex < 2 && branchIndex < branches->size();
                     ++branchIndex) {
                    const auto* branchObject = (*branches)[branchIndex].getDynamicObject();
                    if (branchObject == nullptr) continue;
                    if (const auto* devices = varArray(branchObject->getProperty("devices"))) {
                        for (const auto& value : *devices) {
                            if (sides[branchIndex]->size() >= 8) break;
                            DeviceSlot child = deviceVarToSlotImpl(value, registry);
                            if (!child.id.empty()) {
                                sides[branchIndex]->push_back(
                                    std::make_shared<DeviceSlot>(std::move(child)));
                            }
                        }
                    }
                }
            }
            return slot;
        }
        if (device_types::isMultibandSplitType(typeId)) {
            const IDeviceType* type = registry.find(typeId);
            if (type == nullptr) return {};
            DeviceSlot slot = type->varToSlot(obj);
            if (slot.id.empty()) return {};
            slot.config.bypassed = static_cast<bool>(object->getProperty("bypass"));
            auto& mb = std::get<MultibandSplitModel>(slot.config.instance);
            if (const auto* bands = varArray(object->getProperty("bands"))) {
                for (int bandIndex = 0;
                     bandIndex < mb.bandCount && bandIndex < bands->size() && bandIndex < kMaxMbBands;
                     ++bandIndex) {
                    const auto* bandObject = (*bands)[bandIndex].getDynamicObject();
                    if (bandObject == nullptr) continue;
                    if (const auto* devices = varArray(bandObject->getProperty("devices"))) {
                        for (const auto& value : *devices) {
                            if (mb.bands[bandIndex].size() >= 8) break;
                            DeviceSlot child = deviceVarToSlotImpl(value, registry);
                            if (!child.id.empty()) {
                                mb.bands[bandIndex].push_back(
                                    std::make_shared<DeviceSlot>(std::move(child)));
                            }
                        }
                    }
                }
            }
            return slot;
        }
        if (device_types::isSpectralLoudSplitType(typeId)) {
            const IDeviceType* type = registry.find(typeId);
            if (type == nullptr) return {};
            DeviceSlot slot = type->varToSlot(obj);
            if (slot.id.empty()) return {};
            slot.config.bypassed = static_cast<bool>(object->getProperty("bypass"));
            auto& sl = std::get<SpectralLoudSplitModel>(slot.config.instance);
            auto readList = [&](const juce::var& container,
                                std::vector<std::shared_ptr<DeviceSlot>>& dest) {
                const auto* obj = container.getDynamicObject();
                if (obj == nullptr) return;
                if (const auto* devices = varArray(obj->getProperty("devices"))) {
                    for (const auto& value : *devices) {
                        if (dest.size() >= 8) break;
                        DeviceSlot child = deviceVarToSlotImpl(value, registry);
                        if (!child.id.empty()) {
                            dest.push_back(std::make_shared<DeviceSlot>(std::move(child)));
                        }
                    }
                }
            };
            if (const auto* bands = varArray(object->getProperty("bands"))) {
                for (int bandIndex = 0;
                     bandIndex < kSpectralLoudBands && bandIndex < bands->size(); ++bandIndex) {
                    readList((*bands)[bandIndex], sl.bands[bandIndex]);
                }
            }
            readList(object->getProperty("preFx"), sl.preFxDevices);
            readList(object->getProperty("postFx"), sl.postFxDevices);
            return slot;
        }
        if (typeId == device_types::kDrumMachine) {
            DeviceSlot slot = registry.createDefault(
                typeId, varToString(object->getProperty("id")));
            if (slot.id.empty()) return {};
            slot.config.bypassed = static_cast<bool>(object->getProperty("bypass"));
            if (const auto* output = object->getProperty("outputPanel").getDynamicObject()) {
                auto& panel = std::get<StereoOutputPanel>(slot.config.outputPanel);
                panel.gain = std::clamp(varToFloat(output->getProperty("gain"), 1.0f), 0.0f, 1.0f);
                panel.pan = std::clamp(varToFloat(output->getProperty("pan"), 0.5f), 0.0f, 1.0f);
                panel.outputMix = std::clamp(varToFloat(output->getProperty("outputMix"), 1.0f), 0.0f, 1.0f);
                panel.outputWidth = std::clamp(varToFloat(output->getProperty("outputWidth"), 1.0f), 0.0f, 1.0f);
            }
            auto& machine = std::get<DrumMachineModel>(slot.config.instance);
            if (const auto* padValues = varArray(object->getProperty("pads"))) {
                for (const auto& padValue : *padValues) {
                    const auto* padObject = padValue.getDynamicObject();
                    if (padObject == nullptr) continue;
                    const int note = std::clamp(
                        static_cast<int>(padObject->getProperty("note")), 0,
                        DrumMachineModel::kMidiNoteCount - 1);
                    auto& pad = machine.pads[static_cast<size_t>(note)];
                    pad.name = varToString(padObject->getProperty("name"));
                    pad.gain = std::clamp(static_cast<float>(
                        static_cast<double>(padObject->getProperty("gain"))), 0.0f, 2.0f);
                    pad.pan = std::clamp(static_cast<float>(
                        static_cast<double>(padObject->getProperty("pan"))), 0.0f, 1.0f);
                    pad.muted = static_cast<bool>(padObject->getProperty("muted"));
                    pad.solo = static_cast<bool>(padObject->getProperty("solo"));
                    pad.chokeGroup = std::clamp(
                        static_cast<int>(padObject->getProperty("chokeGroup")), 0, 16);
                    if (const auto* devices = varArray(padObject->getProperty("devices"))) {
                        for (const auto& deviceValue : *devices) {
                            if (pad.devices.size() >= DrumMachineModel::kMaxDevicesPerPad) break;
                            DeviceSlot child = deviceVarToSlotImpl(deviceValue, registry);
                            if (!child.id.empty()) {
                                pad.devices.push_back(std::make_shared<DeviceSlot>(std::move(child)));
                            }
                        }
                    }
                }
            }
            return slot;
        }
        if (device_types::isSynthType(typeId) ||
            device_types::isSidechainFxHost(typeId)) {
            const IDeviceType* type = registry.find(typeId);
            if (type == nullptr) return {};
            DeviceSlot slot = type->varToSlot(obj);
            if (slot.id.empty()) return {};
            slot.config.bypassed = static_cast<bool>(object->getProperty("bypass"));
            if (const auto* devices = varArray(object->getProperty("audioFxDevices"))) {
                slot.audioFxDevices.reserve(std::min(devices->size(), 8));
                for (const auto& value : *devices) {
                    if (slot.audioFxDevices.size() >= 8) break;
                    DeviceSlot child = deviceVarToSlotImpl(value, registry);
                    if (!child.id.empty() && device_types::isAudioFxType(child.config.typeId)) {
                        slot.audioFxDevices.push_back(
                            std::make_shared<DeviceSlot>(std::move(child)));
                    }
                }
            }
            if (device_types::isSynthType(typeId)) {
                if (const auto* devices = varArray(object->getProperty("noteFxDevices"))) {
                    slot.noteFxDevices.reserve(std::min(devices->size(), 8));
                    for (const auto& value : *devices) {
                        if (slot.noteFxDevices.size() >= 8) break;
                        DeviceSlot child = deviceVarToSlotImpl(value, registry);
                        if (!child.id.empty() && device_types::isNoteFxType(child.config.typeId)) {
                            slot.noteFxDevices.push_back(
                                std::make_shared<DeviceSlot>(std::move(child)));
                        }
                    }
                }
            }
            return slot;
        }
        const IDeviceType* type = registry.find(typeId);
        if (type != nullptr) {
            DeviceSlot slot = type->varToSlot(obj);
            if (!slot.id.empty()) {
                return slot;
            }
        }
    }
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
    object->setProperty("iconKey", toJuceString(track.iconKey));
    object->setProperty("isGroup", track.isGroup);
    object->setProperty("muted", track.muted);
    object->setProperty("soloed", track.soloed);
    object->setProperty("parentGroupId", toJuceString(track.parentGroupId));
    object->setProperty("outputTarget", toJuceString(
        track.outputTarget.empty() ? "master" : track.outputTarget));
    object->setProperty("devices", devices);
    object->setProperty("midiClips", clips);
    object->setProperty("sampleClips", sampleClips);
    if (track.freeze.enabled || !track.freeze.assetId.empty()) {
        auto* freezeObj = new juce::DynamicObject();
        freezeObj->setProperty("enabled", track.freeze.enabled);
        freezeObj->setProperty("stale", track.freeze.stale);
        freezeObj->setProperty("assetId", toJuceString(track.freeze.assetId));
        freezeObj->setProperty("startBeat", track.freeze.startBeat);
        freezeObj->setProperty("lengthBeats", track.freeze.lengthBeats);
        freezeObj->setProperty("sampleRate", track.freeze.sampleRate);
        freezeObj->setProperty("bpmAtFreeze", track.freeze.bpmAtFreeze);
        freezeObj->setProperty("contentSignature",
                               juce::String(static_cast<juce::int64>(track.freeze.contentSignature)));
        if (!track.freeze.assetId.empty()) {
            freezeObj->setProperty("wavPath", toJuceString(freezeWavArchivePath(track.freeze.assetId)));
        }
        juce::Array<juce::var> peaks;
        peaks.ensureStorageAllocated(static_cast<int>(track.freeze.waveformPeaks.size()));
        for (float peak : track.freeze.waveformPeaks) {
            peaks.add(static_cast<double>(peak));
        }
        freezeObj->setProperty("waveformPeaks", peaks);
        object->setProperty("freeze", juce::var(freezeObj));
    }
    return juce::var(object);
}

TrackState trackFromVarPersistence(const juce::var& value,
                                    const DeviceRegistry& registry) {
    TrackState track;
    if (const auto* object = value.getDynamicObject()) {
        track.id = varToString(object->getProperty("id"));
        track.name = varToString(object->getProperty("name"));
        track.iconKey = varToString(object->getProperty("iconKey"));
        track.isGroup = static_cast<bool>(object->getProperty("isGroup"));
        if (object->hasProperty("muted"))
            track.muted = static_cast<bool>(object->getProperty("muted"));
        if (object->hasProperty("soloed"))
            track.soloed = static_cast<bool>(object->getProperty("soloed"));
        track.parentGroupId = varToString(object->getProperty("parentGroupId"));
        if (object->hasProperty("outputTarget")) {
            track.outputTarget = varToString(object->getProperty("outputTarget"));
        }
        if (track.outputTarget.empty()) {
            track.outputTarget = "master";
        }
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
        if (const auto* freezeVar = object->getProperty("freeze").getDynamicObject()) {
            track.freeze.enabled = static_cast<bool>(freezeVar->getProperty("enabled"));
            if (freezeVar->hasProperty("stale")) {
                track.freeze.stale = static_cast<bool>(freezeVar->getProperty("stale"));
            }
            track.freeze.assetId = varToString(freezeVar->getProperty("assetId"));
            track.freeze.startBeat = static_cast<double>(freezeVar->getProperty("startBeat"));
            track.freeze.lengthBeats = static_cast<double>(freezeVar->getProperty("lengthBeats"));
            track.freeze.sampleRate = static_cast<double>(freezeVar->getProperty("sampleRate"));
            if (freezeVar->hasProperty("bpmAtFreeze")) {
                track.freeze.bpmAtFreeze =
                    static_cast<int>(static_cast<double>(freezeVar->getProperty("bpmAtFreeze")));
            }
            if (freezeVar->hasProperty("contentSignature")) {
                track.freeze.contentSignature = static_cast<uint64_t>(static_cast<juce::int64>(
                    freezeVar->getProperty("contentSignature")));
            }
            if (const auto* peaks = varArray(freezeVar->getProperty("waveformPeaks"))) {
                for (const auto& peakVar : *peaks) {
                    track.freeze.waveformPeaks.push_back(static_cast<float>(static_cast<double>(peakVar)));
                }
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
        juce::var deviceVar = deviceSlotToVarImpl(track.devices[i], registry);

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
    object->setProperty("iconKey", toJuceString(track.iconKey));
    object->setProperty("isGroup", track.isGroup);
    object->setProperty("muted", track.muted);
    object->setProperty("soloed", track.soloed);
    object->setProperty("parentGroupId", toJuceString(track.parentGroupId));
    object->setProperty("outputTarget", toJuceString(
        track.outputTarget.empty() ? "master" : track.outputTarget));
    object->setProperty("devices", devices);
    object->setProperty("midiClips", clips);
    object->setProperty("sampleClips", sampleClips);
    if (track.freeze.enabled || !track.freeze.waveformPeaks.empty()) {
        auto* freezeObj = new juce::DynamicObject();
        freezeObj->setProperty("enabled", track.freeze.enabled);
        freezeObj->setProperty("stale", track.freeze.stale);
        freezeObj->setProperty("assetId", toJuceString(track.freeze.assetId));
        freezeObj->setProperty("startBeat", track.freeze.startBeat);
        freezeObj->setProperty("lengthBeats", track.freeze.lengthBeats);
        freezeObj->setProperty("sampleRate", track.freeze.sampleRate);
        freezeObj->setProperty("bpmAtFreeze", track.freeze.bpmAtFreeze);
        freezeObj->setProperty("contentSignature",
                               juce::String(static_cast<juce::int64>(track.freeze.contentSignature)));
        if (!track.freeze.assetId.empty()) {
            freezeObj->setProperty("wavPath", toJuceString(freezeWavArchivePath(track.freeze.assetId)));
        }
        juce::Array<juce::var> peaks;
        peaks.ensureStorageAllocated(static_cast<int>(track.freeze.waveformPeaks.size()));
        for (float peak : track.freeze.waveformPeaks) {
            peaks.add(static_cast<double>(peak));
        }
        freezeObj->setProperty("waveformPeaks", peaks);
        object->setProperty("freeze", juce::var(freezeObj));
    }
    return juce::var(object);
}

} // namespace

std::vector<std::unique_ptr<IModulatorType>> createDefaultModulatorTypes() {
    std::vector<std::unique_ptr<IModulatorType>> types;
    types.push_back(std::make_unique<LfoModulatorType>());
    types.push_back(std::make_unique<EnvelopeModulatorType>());
    return types;
}

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

juce::var modulatorRecordsToVar(const std::vector<ModulationGraph::ModulatorRecord>& records,
                                 const std::vector<std::unique_ptr<IModulatorType>>& modTypes) {
    juce::Array<juce::var> result;
    result.ensureStorageAllocated(static_cast<int>(records.size()));
    for (const auto& rec : records) {
        if (static_cast<size_t>(rec.typeIndex) >= modTypes.size()) continue;
        const auto& type = modTypes[static_cast<size_t>(rec.typeIndex)];
        juce::var paramsVar = type->paramsToVar(rec.params);
        if (auto* obj = paramsVar.getDynamicObject()) {
            obj->setProperty("id", rec.id);
            obj->setProperty("type", juce::String(type->typeId()));
            obj->setProperty("ownerDeviceId", juce::String(rec.ownerDeviceId));
        }
        result.add(paramsVar);
    }
    return juce::var(result);
}

void modulatorRecordsFromVar(const juce::var& arr,
                              std::vector<ModulationGraph::ModulatorRecord>& out,
                              const std::vector<std::unique_ptr<IModulatorType>>& modTypes) {
    out.clear();
    const auto* array = arr.getArray();
    if (array == nullptr) return;

    out.reserve(static_cast<size_t>(array->size()));
    for (const auto& item : *array) {
        const auto* obj = item.getDynamicObject();
        if (obj == nullptr) continue;

        const int id = varToInt(obj->getProperty("id"), 0);
        const std::string typeId = varToString(obj->getProperty("type"));

        int typeIndex = -1;
        for (size_t i = 0; i < modTypes.size(); ++i) {
            if (modTypes[i]->typeId() == typeId) {
                typeIndex = static_cast<int>(i);
                break;
            }
        }
        if (typeIndex < 0) continue;

        ModulationGraph::ModulatorRecord rec;
        rec.id = id;
        rec.typeIndex = typeIndex;
        rec.ownerDeviceId =
            obj->getProperty("ownerDeviceId").toString().toStdString();
        rec.params = modTypes[static_cast<size_t>(typeIndex)]->varToParams(item);
        out.push_back(std::move(rec));
    }
}

std::string snapshotToJson(const ProjectSnapshot& snapshot,
                            const DeviceRegistry& registry,
                            const std::vector<std::unique_ptr<IModulatorType>>& modulatorTypes) {
    return toStdString(juce::JSON::toString(snapshotToVar(snapshot, registry, modulatorTypes), false));
}

std::string projectFileToJson(const ProjectFileData& project,
                               const DeviceRegistry& registry,
                               const std::vector<std::unique_ptr<IModulatorType>>& modulatorTypes) {
    return toStdString(juce::JSON::toString(projectFileToVar(project, registry, modulatorTypes), true));
}

bool parseProjectFileJson(const std::string& json,
                          ProjectFileData& out,
                          const DeviceRegistry& registry,
                          const std::vector<std::unique_ptr<IModulatorType>>& modulatorTypes) {
    auto root = parseRootVar(json);
    if (!migrateProjectVarToCurrent(root)) return false;
    const auto* object = root.getDynamicObject();
    if (object == nullptr) {
        return false;
    }

    out.projectFormatVersion = kProjectFormatVersion;

    out.name = varToString(object->getProperty("name"));
    out.bpm = varToInt(object->getProperty("bpm"), 120);
    out.selectedTrackId = varToString(object->getProperty("selectedTrackId"));
    out.loopEnabled = !object->hasProperty("loopEnabled") ||
                      static_cast<bool>(object->getProperty("loopEnabled"));
    out.loopRegionStartBeat = varToDouble(
        object->getProperty("loopRegionStartBeat"),
        varToDouble(object->getProperty("loopStart"), 0.0));
    out.loopRegionEndBeat = varToDouble(
        object->getProperty("loopRegionEndBeat"),
        varToDouble(object->getProperty("loopEnd"), 16.0));
    if (out.loopRegionEndBeat <= out.loopRegionStartBeat) {
        out.loopRegionStartBeat = 0.0;
        out.loopRegionEndBeat = 16.0;
    }
    out.tracks.clear();
    out.sampleLibrary.clear();
    out.master.id = "master";
    out.master.name = "Master";
    out.master.gain = 1.0f;
    out.master.muted = false;
    out.master.devices.clear();
    if (const auto* masterObject = object->getProperty("master").getDynamicObject()) {
        out.master.id = varToString(masterObject->getProperty("id"));
        out.master.name = varToString(masterObject->getProperty("name"));
        out.master.gain = varToFloat(masterObject->getProperty("gain"), 1.0f);
        if (masterObject->hasProperty("muted")) {
            out.master.muted = static_cast<bool>(masterObject->getProperty("muted"));
        }
        if (const auto* devices = varArray(masterObject->getProperty("devices"))) {
            for (const auto& deviceVar : *devices) {
                out.master.devices.push_back(deviceVarToSlotImpl(deviceVar, registry));
            }
        }
        if (const auto* midiClips = varArray(masterObject->getProperty("midiClips"))) {
            for (const auto& clipVar : *midiClips) {
                out.master.midiClips.push_back(midiClipFromVar(clipVar));
            }
        }
        if (const auto* sampleClips = varArray(masterObject->getProperty("sampleClips"))) {
            for (const auto& clipVar : *sampleClips) {
                out.master.sampleClips.push_back(sampleClipFromVar(clipVar));
            }
        }
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
        modulatorRecordsFromVar(object->getProperty("lfos"), out.lfos, modulatorTypes);
    }
    if (object->hasProperty("modEdges")) {
        out.modEdges = modEdgeArrayFromVar(object->getProperty("modEdges"));
    }

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
    root->setProperty("protocolVersion", kBridgeProtocolVersion);
    root->setProperty("snapshot", parseRootVar(snapshotJson));
    return toStdString(juce::JSON::toString(juce::var(root), false));
}

std::string buildBridgeOkTransportState(const TransportStateSnapshot& transport) {
    auto* root = new juce::DynamicObject();
    root->setProperty("ok", true);
    root->setProperty("protocolVersion", kBridgeProtocolVersion);
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
    root->setProperty("protocolVersion", kBridgeProtocolVersion);
    root->setProperty("path", toJuceString(path));
    return toStdString(juce::JSON::toString(juce::var(root), false));
}

std::string buildBridgeOkWithMessage(const std::string& message) {
    auto* root = new juce::DynamicObject();
    root->setProperty("ok", true);
    root->setProperty("protocolVersion", kBridgeProtocolVersion);
    root->setProperty("message", toJuceString(message));
    return toStdString(juce::JSON::toString(juce::var(root), false));
}

std::string buildBridgeError(const std::string& errorCode) {
    auto* root = new juce::DynamicObject();
    root->setProperty("ok", false);
    root->setProperty("protocolVersion", kBridgeProtocolVersion);
    root->setProperty("error", toJuceString(errorCode));
    return toStdString(juce::JSON::toString(juce::var(root), false));
}

} // namespace audioapp
