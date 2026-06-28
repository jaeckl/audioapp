#include "audioapp/model/AutomationClipStore.hpp"

#include "audioapp/ClipContentPlayback.hpp"

#include <algorithm>
#include <cstdlib>
#include <utility>

namespace audioapp {

namespace {

int maxSuffix(const std::string& id, const std::string& prefix) {
    if (id.rfind(prefix, 0) != 0) {
        return 0;
    }
    const auto suffix = id.substr(prefix.size());
    return suffix.empty() ? 0 : std::atoi(suffix.c_str());
}

} // namespace

void AutomationClipStore::clear() {
    clips_.clear();
    nextNum_ = 1;
}

void AutomationClipStore::load(const std::vector<AutomationClip>& clips) {
    clips_ = clips;
    recomputeIdCounters();
}

void AutomationClipStore::recomputeIdCounters() {
    int maxSeen = 0;
    for (const auto& clip : clips_) {
        maxSeen = std::max(maxSeen, maxSuffix(clip.id, "aclip-"));
    }
    nextNum_ = maxSeen + 1;
}

std::string AutomationClipStore::create(const std::string& homeTrackId,
                                        double startBeat,
                                        double lengthBeats) {
    AutomationClip clip;
    clip.id = "aclip-" + std::to_string(nextNum_++);
    clip.homeTrackId = homeTrackId;
    clip.startBeat = startBeat < 0.0 ? 0.0 : startBeat;
    clip.lengthBeats = lengthBeats > 0.0 ? lengthBeats : 4.0;
    clip.naturalLengthBeats = clip.lengthBeats;
    clip.points.push_back(AutomationPoint{0.0, 1.0f});
    clip.points.push_back(AutomationPoint{clip.lengthBeats, 0.25f});
    clips_.push_back(std::move(clip));
    return clips_.back().id;
}

bool AutomationClipStore::assignTarget(const std::string& clipId,
                                       const std::string& deviceId,
                                       const std::string& paramId) {
    AutomationClip* clip = find(clipId);
    if (clip == nullptr || deviceId.empty() || paramId.empty()) {
        return false;
    }
    clip->deviceId = deviceId;
    clip->paramId = paramId;
    return true;
}

bool AutomationClipStore::setPoints(const std::string& clipId,
                                    const std::vector<AutomationPointState>& points) {
    AutomationClip* clip = find(clipId);
    if (clip == nullptr || points.empty()) {
        return false;
    }
    clip->points.clear();
    clip->points.reserve(points.size());
    for (const auto& point : points) {
        AutomationPoint stored;
        stored.beat = point.beat < 0.0 ? 0.0 : point.beat;
        stored.value = std::clamp(point.value, 0.0f, 1.0f);
        clip->points.push_back(stored);
    }
    std::sort(clip->points.begin(), clip->points.end(),
              [](const AutomationPoint& a, const AutomationPoint& b) {
                  return a.beat < b.beat;
              });
    const double pointEnd = automationPointsContentLengthBeats(clip->points, 0.0);
    if (!clip->loopContent && pointEnd > clip->naturalLengthBeats) {
        clip->naturalLengthBeats = pointEnd;
    }
    return true;
}

bool AutomationClipStore::setLength(const std::string& clipId,
                                    double lengthBeats,
                                    ClipLengthTarget target) {
    AutomationClip* clip = find(clipId);
    if (clip == nullptr) {
        return false;
    }
    const double len = lengthBeats < 0.01 ? 0.01 : lengthBeats;
    if (target == ClipLengthTarget::Content) {
        clip->naturalLengthBeats = len;
    } else {
        clip->lengthBeats = len;
    }
    return true;
}

bool AutomationClipStore::setStartBeat(const std::string& clipId, double startBeat) {
    AutomationClip* clip = find(clipId);
    if (clip == nullptr) {
        return false;
    }
    clip->startBeat = startBeat < 0.0 ? 0.0 : startBeat;
    return true;
}

bool AutomationClipStore::setHomeTrackId(const std::string& clipId,
                                         const std::string& homeTrackId) {
    AutomationClip* clip = find(clipId);
    if (clip == nullptr || homeTrackId.empty()) {
        return false;
    }
    clip->homeTrackId = homeTrackId;
    return true;
}

bool AutomationClipStore::remove(const std::string& clipId) {
    auto it = std::find_if(clips_.begin(), clips_.end(),
                           [&clipId](const AutomationClip& c) { return c.id == clipId; });
    if (it == clips_.end()) {
        return false;
    }
    clips_.erase(it);
    return true;
}

bool AutomationClipStore::duplicate(const std::string& clipId) {
    auto it = std::find_if(clips_.begin(), clips_.end(),
                           [&clipId](const AutomationClip& c) { return c.id == clipId; });
    if (it == clips_.end()) {
        return false;
    }
    AutomationClip copy = *it;
    copy.id = "aclip-" + std::to_string(nextNum_++);
    copy.startBeat = it->startBeat + it->lengthBeats;
    clips_.push_back(std::move(copy));
    return true;
}

bool AutomationClipStore::setLoopContent(const std::string& clipId, bool loopContent) {
    AutomationClip* clip = find(clipId);
    if (clip == nullptr) {
        return false;
    }
    clip->loopContent = loopContent;
    return true;
}

void AutomationClipStore::unlinkForDevice(const std::string& deviceId) {
    if (deviceId.empty()) {
        return;
    }
    for (auto& clip : clips_) {
        if (clip.deviceId == deviceId) {
            clip.deviceId.clear();
            clip.paramId.clear();
        }
    }
}

AutomationClip* AutomationClipStore::find(const std::string& clipId) {
    for (auto& clip : clips_) {
        if (clip.id == clipId) {
            return &clip;
        }
    }
    return nullptr;
}

const AutomationClip* AutomationClipStore::find(const std::string& clipId) const {
    for (const auto& clip : clips_) {
        if (clip.id == clipId) {
            return &clip;
        }
    }
    return nullptr;
}

} // namespace audioapp
