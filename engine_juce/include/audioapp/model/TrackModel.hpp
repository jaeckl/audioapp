#pragma once

#include "audioapp/devices/DeviceSlot.hpp"

#include <string>
#include <vector>

namespace audioapp {

struct MidiNote {
    int pitch = 60;
    double startBeat = 0.0;
    double durationBeats = 1.0;
    float velocity = 100.0f;
};

struct MidiClipTake {
    std::string id;
    std::string name;
    double startBeatOffset = 0.0;
    double lengthBeats = 4.0;
    std::vector<MidiNote> notes;
};

struct MidiClipTakeRegion {
    double startBeat = 0.0;
    double endBeat = 4.0;
    std::string takeId;
    double sourceStart = 0.0;
    /// Governs this region's *start* boundary handoff. When true (Ring), the
    /// previous region's notes that started before this boundary ring out to
    /// their natural length; when false (Cut), they are truncated at the
    /// boundary. Ignored for the first region (no incoming boundary).
    bool holdPrevious = true;
};

struct MidiClip {
    std::string id;
    double startBeat = 0.0;
    double lengthBeats = 4.0;
    /// Authored MIDI content length in beats. Set at clip creation to
    /// lengthBeats; updated when notes are saved; never modified by resize.
    /// Loop playback wraps at this boundary (like SampleClip::naturalLengthBeats).
    double naturalLengthBeats = 4.0;
    bool loopContent = false;
    int editorScaleRoot = 0;
    std::string editorScaleId = "major";
    bool editorScaleHighlight = false;
    bool editorScaleSnap = false;
    std::string editorChordQuality = "off";
    std::vector<MidiNote> notes;
    std::vector<MidiClipTake> takes;
    std::vector<MidiClipTakeRegion> activeTakeRegions;
    /// When true the comp has been flattened: `notes` is authoritative and
    /// hand-editable, and the comp derivation no longer overwrites it. Recorded
    /// takes/regions are preserved so the comp can be re-opened (discarding the
    /// manual edits) via reopenMidiComp.
    bool compFlattened = false;
};

struct SampleClipTake {
    std::string id;
    std::string sampleId;
    std::string name;
    double startBeatOffset = 0.0;
    double lengthBeats = 4.0;
};

struct SampleClipTakeRegion {
    double startBeat = 0.0;
    double endBeat = 4.0;
    std::string takeId;
    double sourceStart = 0.0;
};

struct SampleClip {
    std::string id;
    std::string sampleId;
    double startBeat = 0.0;
    double lengthBeats = 4.0;
    /// Length of the waveform's source region in beats. Set at clip creation
    /// to the source sample's natural duration; never modified by resize.
    /// The arranger view uses this to render the waveform at its natural
    /// density and either clip it (when shortening) or leave trailing empty
    /// space (when lengthening).
    double naturalLengthBeats = 4.0;
    bool loopContent = false;
    float sourceStart = 0.0f;
    float sourceEnd = 1.0f;
    float gain = 1.0f;
    float fadeIn = 0.0f;
    float fadeOut = 0.0f;
    float fadeInCurve = 0.5f;
    float fadeOutCurve = 0.5f;
    bool reversed = false;
    bool warpRepitch = false;
    std::vector<float> sliceMarkers;
    std::vector<SampleClipTake> takes;
    std::vector<SampleClipTakeRegion> activeTakeRegions;
};

struct AutomationPoint {
    double beat = 0.0;
    float value = 0.0f;
};

struct AutomationClip {
    std::string id;
    /// Track the clip is rendered on in the arrangement view. Set at create
    /// time and never changes — independent of `deviceId` (the device may
    /// live on any track, including this one).
    std::string homeTrackId;
    double startBeat = 0.0;
    double lengthBeats = 4.0;
    /// Authored automation content length in beats. Set at clip creation;
    /// updated when points are saved; never modified by resize.
    double naturalLengthBeats = 4.0;
    bool loopContent = false;
    std::string deviceId;
    std::string paramId;
    std::vector<AutomationPoint> points;
};

/// How a freeze asset is owned. Auto = invisible CPU cache (no edit lock / chrome).
/// Manual = user snowflake freeze. Off = not frozen.
enum class TrackFreezeMode : uint8_t { Off = 0, Auto = 1, Manual = 2 };

struct TrackFreezeData {
    bool enabled = false;
    bool stale = false;
    TrackFreezeMode mode = TrackFreezeMode::Off;
    /// Bumped on every invalidate / reschedule; commit drops jobs with a mismatch.
    uint64_t bakeGeneration = 0;
    std::string assetId;
    double startBeat = 0.0;
    double lengthBeats = 0.0;
    double sampleRate = 48000.0;
    int bpmAtFreeze = 120;
    uint64_t contentSignature = 0;
    /// Exclusive index into the *flattened* playback device array
    /// (noteFx…, synth, audioFx…): slots [0, bakeEndDeviceIndex) are baked;
    /// the rest still run live. Cross-track consumers/publishers cannot be
    /// baked, so the split lands before the first such model device's span
    /// rather than always at track_gain.
    int bakeEndDeviceIndex = 0;
    std::vector<float> waveformPeaks;
};

/// Audio output destination sentinels (also used as Track::outputTarget).
inline constexpr const char* kOutputTargetMaster = "master";
inline constexpr const char* kOutputTargetDevice = "device";

struct Track {
    std::string id;
    std::string name;
    std::string iconKey;
    bool isGroup = false;
    bool muted = false;
    bool soloed = false;
    std::string parentGroupId;
    /// Where this track's audio goes after its device chain:
    /// `master`, `device`, or another track id. Default = master.
    std::string outputTarget = kOutputTargetMaster;
    std::vector<DeviceSlot> devices;
    std::vector<MidiClip> midiClips;
    std::vector<SampleClip> sampleClips;
    TrackFreezeData freeze;
    // Note: automation clips were moved to AutomationClipStore (project-global)
    // so a single clip can target any device on any track. They are no
    // longer nested per-track.
};

} // namespace audioapp
