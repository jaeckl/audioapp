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
    /// Global automation-clip store.
    std::vector<AutomationClipState> automationClips;
};

constexpr int kProjectFormatVersion = 1;

std::string projectFileToJson(const ProjectFileData& project,
                               const DeviceRegistry& registry);
bool parseProjectFileJson(const std::string& json,
                          ProjectFileData& out,
                          const DeviceRegistry& registry);

/// Registry-aware overload: converts DeviceSlot to JSON via dispatch.
juce::var deviceToVar(const DeviceSlot& slot, const DeviceRegistry& registry);

/// Registry-aware overload: parses JSON to DeviceSlot via dispatch.
DeviceSlot deviceFromVar(const juce::var& value, const DeviceRegistry& registry);

std::string snapshotToJson(const ProjectSnapshot& snapshot,
                            const DeviceRegistry& registry);

/// Serialize a DeviceSlot to JSON string via its registered IDeviceType
/// (default IDeviceType::slotToVar).
std::string deviceSlotToVar(const DeviceSlot& slot, const DeviceRegistry& registry);

/// Deserialize a JSON string to a DeviceSlot via its registered IDeviceType
/// (default IDeviceType::varToSlot).
DeviceSlot deviceVarToSlot(const std::string& json, const DeviceRegistry& registry);

std::vector<MidiNoteState> parseMidiNotesFromArgs(const std::string& argumentsJson);
std::vector<AutomationPointState> parseAutomationPointsFromArgs(const std::string& argumentsJson);

struct SubtractivePresetArgs {
    std::string deviceId;
    std::vector<std::pair<std::string, float>> params;
    std::vector<ProjectEngine::SubtractivePresetLfoSpec> lfos;
    std::vector<ProjectEngine::SubtractivePresetModSpec> mods;
};

bool parseSubtractivePresetArgs(const std::string& argumentsJson, SubtractivePresetArgs& out);

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
