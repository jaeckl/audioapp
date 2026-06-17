#pragma once

#include "audioapp/ProjectEngine.hpp"

#include <string>

namespace audioapp {

struct ProjectFileData {
    int projectFormatVersion = 1;
    std::string name = "Untitled";
    int bpm = 120;
    std::string selectedTrackId;
    MasterTrackState master;
    std::vector<SampleLibraryEntryState> sampleLibrary;
    std::vector<TrackState> tracks;
};

constexpr int kProjectFormatVersion = 1;

std::string projectFileToJson(const ProjectFileData& project);
bool parseProjectFileJson(const std::string& json, ProjectFileData& out);

std::string snapshotToJson(const ProjectSnapshot& snapshot);
std::vector<MidiNoteState> parseMidiNotesFromArgs(const std::string& argumentsJson);

/// Bridge command JSON helpers (control thread).
std::string jsonGetStringArg(const std::string& argumentsJson, const std::string& key);
double jsonGetNumberArg(const std::string& argumentsJson, const std::string& key, double fallback = 0.0);
bool jsonGetBoolArg(const std::string& argumentsJson, const std::string& key, bool fallback = false);
std::string buildBridgeOkWithSnapshot(const std::string& snapshotJson);
std::string buildBridgeOkWithPath(const std::string& path);
std::string buildBridgeOkWithMessage(const std::string& message);
std::string buildBridgeError(const std::string& errorCode);

} // namespace audioapp
