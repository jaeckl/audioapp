#pragma once

#include "audioapp/ProjectEngine.hpp"

#include <string>

namespace audioapp {

struct ProjectFileData {
    int projectFormatVersion = 1;
    std::string name = "Untitled";
    int bpm = 120;
    std::string selectedTrackId;
    std::vector<TrackState> tracks;
};

constexpr int kProjectFormatVersion = 1;

std::string projectFileToJson(const ProjectFileData& project);
bool parseProjectFileJson(const std::string& json, ProjectFileData& out);

std::string snapshotToJson(const ProjectSnapshot& snapshot);
std::vector<MidiNoteState> parseMidiNotesFromArgs(const std::string& argumentsJson);

} // namespace audioapp
