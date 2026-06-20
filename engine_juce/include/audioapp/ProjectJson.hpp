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
    /// Global automation-clip store. New files write it here. The loader
    /// will fall back to per-track `tracks[i].automationClips` for legacy
    /// projects and flatten them into the global store on load.
    std::vector<AutomationClipState> automationClips;
};

constexpr int kProjectFormatVersion = 1;

std::string projectFileToJson(const ProjectFileData& project,
                               const DeviceRegistry& registry);
bool parseProjectFileJson(const std::string& json,
                          ProjectFileData& out,
                          const DeviceRegistry& registry);

/// Registry-aware overload: converts DeviceState to JSON via DeviceSlot dispatch.
juce::var deviceToVar(const DeviceState& device, const DeviceRegistry& registry);

/// Registry-aware overload: parses JSON to DeviceState via DeviceSlot dispatch.
DeviceState deviceFromVar(const juce::var& value, const DeviceRegistry& registry);

std::string snapshotToJson(const ProjectSnapshot& snapshot);

/// Serialize a DeviceSlot to JSON string via its registered IDeviceType.
/// Falls back to the existing DeviceState-based serialization if the device
/// type hasn't been migrated yet (default IDeviceType::slotToVar).
std::string deviceSlotToVar(const DeviceSlot& slot, const DeviceRegistry& registry);

/// Deserialize a JSON string to a DeviceSlot via its registered IDeviceType.
/// Falls back to the existing DeviceState-based deserialization if the device
/// type hasn't been migrated yet (default IDeviceType::varToSlot).
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

/// LFO / modulator evaluation helpers.
float lfoEvaluate(LfoWaveform waveform, float phase) noexcept;
double lfoSyncBeats(int syncDivision) noexcept;
float modulatorApplyPolarity(float value, int polarity) noexcept;
float modulatorEvaluateSynced(const LfoState& state,
                              double playheadBeat,
                              int bpm,
                              double frameSeconds) noexcept;
float modulatorEvaluateOnNote(const LfoState& state,
                              double frameSeconds,
                              uint32_t retriggerGeneration,
                              uint32_t& lastRetriggerGeneration,
                              float& envelopeLevel,
                              int& envelopeStage,
                              double& segStartSeconds) noexcept;

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
