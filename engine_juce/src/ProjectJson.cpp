#include "audioapp/ProjectJson.hpp"

#include <cstdlib>
#include <sstream>
#include <iomanip>
#include <cctype>

namespace audioapp {

namespace {

std::string escapeJson(const std::string& value) {
    std::string out;
    out.reserve(value.size());
    for (char c : value) {
        if (c == '"' || c == '\\') {
            out.push_back('\\');
        }
        out.push_back(c);
    }
    return out;
}

} // namespace

std::string snapshotToJson(const ProjectSnapshot& snapshot) {
    std::ostringstream json;
    json << std::fixed << std::setprecision(2);
    json << "{\"bpm\":" << snapshot.bpm;
    json << ",\"playheadBeats\":" << snapshot.playheadBeats;
    json << ",\"playing\":" << (snapshot.playing ? "true" : "false");
    json << ",\"selectedTrackId\":\"" << escapeJson(snapshot.selectedTrackId) << "\"";
    json << ",\"tracks\":[";
    for (size_t i = 0; i < snapshot.tracks.size(); ++i) {
        if (i > 0) {
            json << ',';
        }
        const auto& track = snapshot.tracks[i];
        json << "{\"id\":\"" << escapeJson(track.id) << "\"";
        json << ",\"name\":\"" << escapeJson(track.name) << "\"";
        json << ",\"devices\":[";
        for (size_t j = 0; j < track.devices.size(); ++j) {
            if (j > 0) {
                json << ',';
            }
            const auto& device = track.devices[j];
            json << "{\"id\":\"" << escapeJson(device.id) << "\"";
            json << ",\"type\":\"" << escapeJson(device.type) << "\"";
            json << ",\"parameters\":{\"frequency\":" << device.frequencyHz << "}}";
        }
        json << "],\"midiClips\":[";
        for (size_t k = 0; k < track.midiClips.size(); ++k) {
            if (k > 0) {
                json << ',';
            }
            const auto& clip = track.midiClips[k];
            json << "{\"id\":\"" << escapeJson(clip.id) << "\"";
            json << ",\"startBeat\":" << clip.startBeat;
            json << ",\"lengthBeats\":" << clip.lengthBeats;
            json << ",\"notes\":[";
            for (size_t n = 0; n < clip.notes.size(); ++n) {
                if (n > 0) {
                    json << ',';
                }
                const auto& note = clip.notes[n];
                json << "{\"pitch\":" << note.pitch;
                json << ",\"startBeat\":" << note.startBeat;
                json << ",\"durationBeats\":" << note.durationBeats;
                json << ",\"velocity\":" << note.velocity << '}';
            }
            json << "]}";
        }
        json << "]}";
    }
    json << "]}";
    return json.str();
}

std::string projectFileToJson(const ProjectFileData& project) {
    std::ostringstream json;
    json << std::fixed << std::setprecision(2);
    json << "{\n";
    json << "  \"project_format_version\": " << project.projectFormatVersion << ",\n";
    json << "  \"name\": \"" << escapeJson(project.name) << "\",\n";
    json << "  \"bpm\": " << project.bpm << ",\n";
    json << "  \"selectedTrackId\": \"" << escapeJson(project.selectedTrackId) << "\",\n";
    json << "  \"tracks\": [";

    for (size_t i = 0; i < project.tracks.size(); ++i) {
        if (i > 0) {
            json << ',';
        }
        const auto& track = project.tracks[i];
        json << "\n    {\"id\":\"" << escapeJson(track.id) << "\"";
        json << ",\"name\":\"" << escapeJson(track.name) << "\"";
        json << ",\"devices\":[";
        for (size_t j = 0; j < track.devices.size(); ++j) {
            if (j > 0) {
                json << ',';
            }
            const auto& device = track.devices[j];
            json << "{\"id\":\"" << escapeJson(device.id) << "\"";
            json << ",\"type\":\"" << escapeJson(device.type) << "\"";
            json << ",\"parameters\":{\"frequency\":" << device.frequencyHz << "}}";
        }
        json << "],\"midiClips\":[";
        for (size_t k = 0; k < track.midiClips.size(); ++k) {
            if (k > 0) {
                json << ',';
            }
            const auto& clip = track.midiClips[k];
            json << "{\"id\":\"" << escapeJson(clip.id) << "\"";
            json << ",\"startBeat\":" << clip.startBeat;
            json << ",\"lengthBeats\":" << clip.lengthBeats;
            json << ",\"notes\":[";
            for (size_t n = 0; n < clip.notes.size(); ++n) {
                if (n > 0) {
                    json << ',';
                }
                const auto& note = clip.notes[n];
                json << "{\"pitch\":" << note.pitch;
                json << ",\"startBeat\":" << note.startBeat;
                json << ",\"durationBeats\":" << note.durationBeats;
                json << ",\"velocity\":" << note.velocity << '}';
            }
            json << "]}";
        }
        json << "]}";
    }

    json << "\n  ]\n}";
    return json.str();
}

namespace {

std::string extractJsonStringValue(const std::string& json, const std::string& key) {
    const std::string needle = "\"" + key + "\":";
    const auto pos = json.find(needle);
    if (pos == std::string::npos) {
        return {};
    }
    size_t i = pos + needle.size();
    while (i < json.size() && std::isspace(static_cast<unsigned char>(json[i]))) {
        ++i;
    }
    if (i >= json.size() || json[i] != '"') {
        return {};
    }
    ++i;
    const auto start = i;
    const auto end = json.find('"', start);
    if (end == std::string::npos) {
        return {};
    }
    return json.substr(start, end - start);
}

size_t valueStartAfterKey(const std::string& json, const std::string& key) {
    const std::string needle = "\"" + key + "\":";
    const auto pos = json.find(needle);
    if (pos == std::string::npos) {
        return std::string::npos;
    }
    size_t i = pos + needle.size();
    while (i < json.size() && std::isspace(static_cast<unsigned char>(json[i]))) {
        ++i;
    }
    return i;
}

int extractJsonInt(const std::string& json, const std::string& key, int fallback) {
    const auto start = valueStartAfterKey(json, key);
    if (start == std::string::npos) {
        return fallback;
    }
    return std::atoi(json.c_str() + start);
}

double extractJsonDouble(const std::string& json, const std::string& key, double fallback) {
    const auto start = valueStartAfterKey(json, key);
    if (start == std::string::npos) {
        return fallback;
    }
    return std::strtod(json.c_str() + start, nullptr);
}

std::vector<std::string> extractJsonObjectsFromArray(const std::string& json, const std::string& arrayKey) {
    std::vector<std::string> objects;
    const std::string needle = "\"" + arrayKey + "\":[";
    const auto arrayStart = json.find(needle);
    if (arrayStart == std::string::npos) {
        return objects;
    }

    size_t pos = arrayStart + needle.size();
    while (pos < json.size()) {
        while (pos < json.size() && (json[pos] == ' ' || json[pos] == '\n' || json[pos] == '\r' || json[pos] == ',')) {
            ++pos;
        }
        if (pos >= json.size() || json[pos] == ']') {
            break;
        }
        if (json[pos] != '{') {
            break;
        }

        const size_t objStart = pos;
        int depth = 0;
        for (; pos < json.size(); ++pos) {
            if (json[pos] == '{') {
                ++depth;
            } else if (json[pos] == '}') {
                --depth;
                if (depth == 0) {
                    objects.push_back(json.substr(objStart, pos - objStart + 1));
                    ++pos;
                    break;
                }
            }
        }
    }
    return objects;
}

DeviceState parseDeviceObject(const std::string& obj) {
    DeviceState device;
    device.id = extractJsonStringValue(obj, "id");
    device.type = extractJsonStringValue(obj, "type");
    device.frequencyHz = static_cast<float>(extractJsonDouble(obj, "frequency", 440.0));
    const auto paramsPos = obj.find("\"parameters\":");
    if (paramsPos != std::string::npos) {
        const auto paramsObj = obj.substr(paramsPos);
        device.frequencyHz = static_cast<float>(extractJsonDouble(paramsObj, "frequency", device.frequencyHz));
    }
    return device;
}

MidiClipState parseClipObject(const std::string& obj) {
    MidiClipState clip;
    clip.id = extractJsonStringValue(obj, "id");
    clip.startBeat = extractJsonDouble(obj, "startBeat", 0.0);
    clip.lengthBeats = extractJsonDouble(obj, "lengthBeats", 4.0);

    const auto noteObjects = extractJsonObjectsFromArray(obj, "notes");
    clip.notes.reserve(noteObjects.size());
    for (const auto& noteObj : noteObjects) {
        MidiNoteState note;
        note.pitch = extractJsonInt(noteObj, "pitch", 60);
        note.startBeat = extractJsonDouble(noteObj, "startBeat", 0.0);
        note.durationBeats = extractJsonDouble(noteObj, "durationBeats", 1.0);
        note.velocity = static_cast<float>(extractJsonDouble(noteObj, "velocity", 100.0));
        clip.notes.push_back(note);
    }
    return clip;
}

TrackState parseTrackObject(const std::string& obj) {
    TrackState track;
    track.id = extractJsonStringValue(obj, "id");
    track.name = extractJsonStringValue(obj, "name");

    const auto deviceObjects = extractJsonObjectsFromArray(obj, "devices");
    for (const auto& deviceObj : deviceObjects) {
        track.devices.push_back(parseDeviceObject(deviceObj));
    }

    const auto clipObjects = extractJsonObjectsFromArray(obj, "midiClips");
    for (const auto& clipObj : clipObjects) {
        track.midiClips.push_back(parseClipObject(clipObj));
    }
    return track;
}

} // namespace

bool parseProjectFileJson(const std::string& json, ProjectFileData& out) {
    out.projectFormatVersion = extractJsonInt(json, "project_format_version", 0);
    if (out.projectFormatVersion != kProjectFormatVersion) {
        return false;
    }

    out.name = extractJsonStringValue(json, "name");
    out.bpm = extractJsonInt(json, "bpm", 120);
    out.selectedTrackId = extractJsonStringValue(json, "selectedTrackId");
    out.tracks.clear();

    const auto trackObjects = extractJsonObjectsFromArray(json, "tracks");
    out.tracks.reserve(trackObjects.size());
    for (const auto& trackObj : trackObjects) {
        out.tracks.push_back(parseTrackObject(trackObj));
    }
    return true;
}

std::vector<MidiNoteState> parseMidiNotesFromArgs(const std::string& argumentsJson) {
    std::vector<MidiNoteState> notes;
    const std::string key = "\"notes\":[";
    auto pos = argumentsJson.find(key);
    if (pos == std::string::npos) {
        return notes;
    }
    pos += key.size();

    while (pos < argumentsJson.size()) {
        const auto objStart = argumentsJson.find('{', pos);
        if (objStart == std::string::npos) {
            break;
        }
        const auto objEnd = argumentsJson.find('}', objStart);
        if (objEnd == std::string::npos) {
            break;
        }

        const std::string obj = argumentsJson.substr(objStart, objEnd - objStart + 1);
        MidiNoteState note;
        note.pitch = extractJsonInt(obj, "pitch", 60);
        note.startBeat = extractJsonDouble(obj, "startBeat", 0.0);
        note.durationBeats = extractJsonDouble(obj, "durationBeats", 1.0);
        note.velocity = static_cast<float>(extractJsonDouble(obj, "velocity", 100.0));
        notes.push_back(note);

        pos = objEnd + 1;
        if (pos < argumentsJson.size() && argumentsJson[pos] == ']') {
            break;
        }
    }

    return notes;
}

} // namespace audioapp
