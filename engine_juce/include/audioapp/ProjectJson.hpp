#pragma once

#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ModulationTypes.hpp"
#include "audioapp/modulation/IModulatorType.hpp"

#include <memory>
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
    std::vector<ModulationGraph::ModulatorRecord> lfos;
    std::vector<ModulationEdge> modEdges;
    /// Global automation-clip store.
    std::vector<AutomationClipState> automationClips;
};

constexpr int kProjectFormatVersion = 1;

std::string projectFileToJson(const ProjectFileData& project,
                               const DeviceRegistry& registry,
                               const std::vector<std::unique_ptr<IModulatorType>>& modulatorTypes);
bool parseProjectFileJson(const std::string& json,
                          ProjectFileData& out,
                          const DeviceRegistry& registry,
                          const std::vector<std::unique_ptr<IModulatorType>>& modulatorTypes);

/// Registry-aware overload: converts DeviceSlot to JSON via dispatch.
juce::var deviceToVar(const DeviceSlot& slot, const DeviceRegistry& registry);

/// Registry-aware overload: parses JSON to DeviceSlot via dispatch.
DeviceSlot deviceFromVar(const juce::var& value, const DeviceRegistry& registry);

std::string snapshotToJson(const ProjectSnapshot& snapshot,
                            const DeviceRegistry& registry,
                            const std::vector<std::unique_ptr<IModulatorType>>& modulatorTypes);

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

/// Current bridge protocol version. Increment on breaking bridge schema changes.
/// Flutter should check this field in every response and warn on mismatch.
constexpr int kBridgeProtocolVersion = 1;

/// Bridge command JSON helpers (control thread).
std::string jsonGetStringArg(const std::string& argumentsJson, const std::string& key);
double jsonGetNumberArg(const std::string& argumentsJson, const std::string& key, double fallback = 0.0);
bool jsonGetBoolArg(const std::string& argumentsJson, const std::string& key, bool fallback = false);
std::string buildBridgeOkWithSnapshot(const std::string& snapshotJson);
std::string buildBridgeOkTransportState(const TransportStateSnapshot& transport);
std::string buildBridgeOkWithPath(const std::string& path);
std::string buildBridgeOkWithMessage(const std::string& message);
std::string buildBridgeError(const std::string& errorCode);

/// Serialize modulator records array to juce::var, dispatching through IModulatorType.
juce::var modulatorRecordsToVar(const std::vector<ModulationGraph::ModulatorRecord>& records,
                                 const std::vector<std::unique_ptr<IModulatorType>>& modTypes);

/// Deserialize modulator records array from juce::var.
void modulatorRecordsFromVar(const juce::var& arr,
                              std::vector<ModulationGraph::ModulatorRecord>& out,
                              const std::vector<std::unique_ptr<IModulatorType>>& modTypes);

/// Create the default set of modulator types (LfoModulatorType + EnvelopeModulatorType).
/// Used for parsing project JSON outside of ProjectEngine context (e.g., tests).
std::vector<std::unique_ptr<IModulatorType>> createDefaultModulatorTypes();

} // namespace audioapp