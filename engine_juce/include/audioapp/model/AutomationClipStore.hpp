#pragma once

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/TimelineClipTypes.hpp"
#include "audioapp/model/TrackModel.hpp"

#include <string>
#include <vector>

namespace audioapp {

/// Global, project-wide store for automation clips.
///
/// Automation clips are device-targeted: their `deviceId`/`paramId` identify
/// a parameter on a specific device, and the device can live on any track.
/// Storing clips globally mirrors how modulation edges are stored on
/// `ModulationGraph` and avoids the "clip on the wrong track" footgun that
/// happened when they used to be nested under `Track::automationClips`.
///
/// The store owns all CRUD for automation clips. The audio-thread resolver
/// in `ProjectEngine::rebuildTrackPlaybackLocked` iterates this store once
/// per track and pulls in any clip whose target device is on that track.
class AutomationClipStore {
public:
    void clear();
    void load(const std::vector<AutomationClip>& clips);
    void recomputeIdCounters();

    std::string create(const std::string& homeTrackId, double startBeat, double lengthBeats);
    bool assignTarget(const std::string& clipId,
                      const std::string& deviceId,
                      const std::string& paramId);
    bool setPoints(const std::string& clipId,
                   const std::vector<AutomationPointState>& points);
    bool setLength(const std::string& clipId,
                   double lengthBeats,
                   ClipLengthTarget target = ClipLengthTarget::Arrangement);
    bool setStartBeat(const std::string& clipId, double startBeat);
    /// Updates the track lane in which this clip is rendered.
    bool setHomeTrackId(const std::string& clipId, const std::string& homeTrackId);
    bool remove(const std::string& clipId);
    /// Duplicates a clip; the copy starts immediately after the source and
    /// keeps the same `deviceId`/`paramId` (unlike the old per-track path
    /// that cleared the target on duplicate).
    bool duplicate(const std::string& clipId);
    bool setLoopContent(const std::string& clipId, bool loopContent);
    void unlinkForDevice(const std::string& deviceId);

    AutomationClip* find(const std::string& clipId);
    const AutomationClip* find(const std::string& clipId) const;

    const std::vector<AutomationClip>& clips() const { return clips_; }

private:
    std::vector<AutomationClip> clips_;
    int nextNum_ = 1;
};

} // namespace audioapp
