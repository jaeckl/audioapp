#pragma once

#include "audioapp/ProjectEngine.hpp"
#include "audioapp/LfoTypes.hpp"

#include <string>
#include <vector>

namespace audioapp {

struct ProjectFileData {
    int projectFormatVersion = 1;
    std::string name = "Untitled";
    int bpm = 120;
    std::string selectedTrackId;
    MasterTrackState master;
    std::vector<SampleLibraryEntryState> sampleLibrary;
    std::vector<TrackState> tracks;
    std::vector<LfoState> lfos;
    std::vector<ModulationEdge> modEdges;
};

constexpr int kProjectFormatVersion = 1;

std::string projectFileToJson(const ProjectFileData& project);
bool parseProjectFileJson(const std::string& json, ProjectFileData& out);

std::string snapshotToJson(const ProjectSnapshot& snapshot);
std::vector<MidiNoteState> parseMidiNotesFromArgs(const std::string& argumentsJson);
std::vector<AutomationPointState> parseAutomationPointsFromArgs(const std::string& argumentsJson);

/// LFO evaluation and helpers.
float lfoEvaluate(LfoWaveform waveform, float phase) noexcept;
double lfoSyncBeats(int syncDivision) noexcept;

/// Bridge command JSON helpers (control thread).
std::string jsonGetStringArg(const std::string& argumentsJson, const std::string& key);
double jsonGetNumberArg(const std::string& argumentsJson, const std::string& key, double fallback = 0.0);
bool jsonGetBoolArg(const std::string& argumentsJson, const std::string& key, bool fallback = false);
std::string buildBridgeOkWithSnapshot(const std::string& snapshotJson);
std::string buildBridgeOkTransportState(const TransportStateSnapshot& transport);
std::string buildBridgeOkWithPath(const std::string& path);
std::string buildBridgeOkWithMessage(const std::string& message);
std::string buildBridgeError(const std::string& errorCode);

} // namespace audioapp
