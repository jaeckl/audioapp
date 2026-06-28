#pragma once

#include <juce_data_structures/juce_data_structures.h>

#include <string>
#include <string_view>

namespace audioapp::state {

// ── ValueTree type identifiers ────────────────────────────────
inline constexpr std::string_view kProjectType     = "Project";
inline constexpr std::string_view kTrackType       = "Track";
inline constexpr std::string_view kDeviceType      = "Device";
inline constexpr std::string_view kMidiClipType    = "MidiClip";
inline constexpr std::string_view kSampleClipType  = "SampleClip";
inline constexpr std::string_view kModulatorType   = "Modulator";
inline constexpr std::string_view kModEdgeType     = "ModulationEdge";
inline constexpr std::string_view kAutomationType  = "AutomationClip";
inline constexpr std::string_view kMidiNoteType    = "MidiNote";
inline constexpr std::string_view kAutomationPointType = "AutomationPoint";

// ── Property identifiers (juce::Identifier) ───────────────────
namespace props {

// Identifiers shared across types
inline const juce::Identifier id          = "id";
inline const juce::Identifier name        = "name";

// Transport / project-global
inline const juce::Identifier bpm               = "bpm";
inline const juce::Identifier selectedTrackId   = "selectedTrackId";
inline const juce::Identifier recording         = "recording";
inline const juce::Identifier playing           = "playing";
inline const juce::Identifier loopEnabled       = "loopEnabled";
inline const juce::Identifier loopStart         = "loopStart";
inline const juce::Identifier loopEnd           = "loopEnd";
inline const juce::Identifier masterGain        = "masterGain";

// Track
inline const juce::Identifier trackName    = "trackName";
inline const juce::Identifier isGroup      = "isGroup";
inline const juce::Identifier parentGroupId = "parentGroupId";

// Device
inline const juce::Identifier typeId       = "typeId";
inline const juce::Identifier bypassed     = "bypassed";
/// Device-config blob (JSON-serialized DeviceConfig::instance + panel states).
/// Stored as an opaque string property since DeviceInstance is a 22-variant
/// std::variant that doesn't map directly to ValueTree properties.
inline const juce::Identifier configBlob   = "configBlob";

// Clip
inline const juce::Identifier startBeat     = "startBeat";
inline const juce::Identifier lengthBeats   = "lengthBeats";
inline const juce::Identifier naturalLength = "naturalLength";

// MIDI note
inline const juce::Identifier pitch       = "pitch";
inline const juce::Identifier duration    = "duration";
inline const juce::Identifier velocity    = "velocity";

// Sample clip
inline const juce::Identifier sampleId    = "sampleId";
inline const juce::Identifier sampleName  = "sampleName";

// Automation clip
inline const juce::Identifier homeTrackId = "homeTrackId";
inline const juce::Identifier deviceId    = "deviceId";
inline const juce::Identifier paramId     = "paramId";

// Automation point
inline const juce::Identifier beat   = "beat";
inline const juce::Identifier value  = "value";

// Modulation edge
inline const juce::Identifier lfoId  = "lfoId";
inline const juce::Identifier amount = "amount";

// Modulator
inline const juce::Identifier typeIndex      = "typeIndex";
inline const juce::Identifier modulatorBlob  = "modulatorBlob";

} // namespace props

// ── Helper builders ──────────────────────────────────────────

/// Create a top-level Project ValueTree with default transport properties.
inline juce::ValueTree createProjectTree() {
    juce::ValueTree root{kProjectType.data()};
    root.setProperty(props::bpm, 120, nullptr);
    root.setProperty(props::selectedTrackId, juce::String{}, nullptr);
    root.setProperty(props::playing, false, nullptr);
    root.setProperty(props::loopEnabled, true, nullptr);
    root.setProperty(props::loopStart, 0.0, nullptr);
    root.setProperty(props::loopEnd, 16.0, nullptr);
    root.setProperty(props::recording, false, nullptr);
    root.setProperty(props::masterGain, 1.0, nullptr);
    return root;
}

/// Create a Track child ValueTree.
inline juce::ValueTree createTrackTree(const std::string& trackId,
                                       const std::string& trackName,
                                       bool isGroup = false,
                                       const std::string& parentGroupId = {}) {
    juce::ValueTree track{kTrackType.data()};
    track.setProperty(props::id, juce::String{trackId}, nullptr);
    track.setProperty(props::name, juce::String{trackName}, nullptr);
    track.setProperty(props::isGroup, isGroup, nullptr);
    track.setProperty(props::parentGroupId, juce::String{parentGroupId}, nullptr);
    return track;
}

/// Create a Device child ValueTree (params stored as opaque configBlob).
inline juce::ValueTree createDeviceTree(const std::string& deviceId,
                                        const std::string& deviceTypeId,
                                        const std::string& configJson) {
    juce::ValueTree device{kDeviceType.data()};
    device.setProperty(props::id, juce::String{deviceId}, nullptr);
    device.setProperty(props::typeId, juce::String{deviceTypeId}, nullptr);
    device.setProperty(props::configBlob, juce::String{configJson}, nullptr);
    device.setProperty(props::bypassed, false, nullptr);
    return device;
}

/// Create a MidiClip child ValueTree.
inline juce::ValueTree createMidiClipTree(const std::string& clipId,
                                          double startBeat,
                                          double lengthBeats) {
    juce::ValueTree clip{kMidiClipType.data()};
    clip.setProperty(props::id, juce::String{clipId}, nullptr);
    clip.setProperty(props::startBeat, startBeat, nullptr);
    clip.setProperty(props::lengthBeats, lengthBeats, nullptr);
    return clip;
}

/// Create a SampleClip child ValueTree.
inline juce::ValueTree createSampleClipTree(const std::string& clipId,
                                            const std::string& sampleId,
                                            double startBeat,
                                            double lengthBeats,
                                            double naturalLengthBeats) {
    juce::ValueTree clip{kSampleClipType.data()};
    clip.setProperty(props::id, juce::String{clipId}, nullptr);
    clip.setProperty(props::sampleId, juce::String{sampleId}, nullptr);
    clip.setProperty(props::startBeat, startBeat, nullptr);
    clip.setProperty(props::lengthBeats, lengthBeats, nullptr);
    clip.setProperty(props::naturalLength, naturalLengthBeats, nullptr);
    return clip;
}

/// Create an AutomationClip child ValueTree.
inline juce::ValueTree createAutomationClipTree(const std::string& clipId,
                                                const std::string& homeTrackId,
                                                double startBeat,
                                                double lengthBeats) {
    juce::ValueTree clip{kAutomationType.data()};
    clip.setProperty(props::id, juce::String{clipId}, nullptr);
    clip.setProperty(props::homeTrackId, juce::String{homeTrackId}, nullptr);
    clip.setProperty(props::startBeat, startBeat, nullptr);
    clip.setProperty(props::lengthBeats, lengthBeats, nullptr);
    return clip;
}

/// Create a Modulator child ValueTree.
inline juce::ValueTree createModulatorTree(int lfoId,
                                           int typeIndex,
                                           const std::string& paramsJson) {
    juce::ValueTree mod{kModulatorType.data()};
    mod.setProperty(props::lfoId, lfoId, nullptr);
    mod.setProperty(props::typeIndex, typeIndex, nullptr);
    mod.setProperty(props::modulatorBlob, juce::String{paramsJson}, nullptr);
    return mod;
}

/// Create a ModulationEdge child ValueTree.
inline juce::ValueTree createModEdgeTree(int lfoId,
                                         const std::string& deviceId,
                                         const std::string& paramId,
                                         float amount) {
    juce::ValueTree edge{kModEdgeType.data()};
    edge.setProperty(props::lfoId, lfoId, nullptr);
    edge.setProperty(props::deviceId, juce::String{deviceId}, nullptr);
    edge.setProperty(props::paramId, juce::String{paramId}, nullptr);
    edge.setProperty(props::amount, static_cast<double>(amount), nullptr);
    return edge;
}

} // namespace audioapp::state
