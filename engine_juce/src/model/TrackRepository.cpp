#include "audioapp/model/TrackRepository.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/DeviceChain.hpp"

#include <algorithm>
#include <iterator>

namespace audioapp {

std::string TrackRepository::defaultIconKey(size_t ordinal) {
    static constexpr const char* keys[] = {
        "piano", "waveform", "microphone", "audio", "album", "speaker",
    };
    return keys[ordinal % (sizeof(keys) / sizeof(keys[0]))];
}

void TrackRepository::clear() {
    tracks_.clear();
    selectedTrackId_.clear();
    nextTrackNum_ = 1;
    nextDeviceNum_ = 1;
}

std::string TrackRepository::addTrack(const std::string& name, const DeviceRegistry& registry) {
    Track track;
    track.id = "track-" + std::to_string(nextTrackNum_++);
    track.name = name.empty() ? ("Track " + std::to_string(tracks_.size() + 1)) : name;
    track.iconKey = defaultIconKey(static_cast<size_t>(nextTrackNum_ - 2));

    const std::string gainId = allocateDeviceId();
    track.devices.push_back(registry.createDefault(device_types::kTrackGain, gainId));

    tracks_.push_back(std::move(track));
    selectedTrackId_ = tracks_.back().id;
    return selectedTrackId_;
}

std::string TrackRepository::addGroupTrack(const std::string& name, const DeviceRegistry& registry) {
    const std::string id = addTrack(name.empty() ? "Group" : name, registry);
    if (auto* track = findTrack(id)) {
        track->isGroup = true;
        track->iconKey = "folder";
    }
    return id;
}

bool TrackRepository::setTrackGroup(const std::string& trackId,
                                    const std::string& groupTrackId) {
    return moveTrack(trackId, groupTrackId, {});
}

bool TrackRepository::moveTrack(const std::string& trackId,
                                const std::string& parentGroupId,
                                const std::string& beforeTrackId) {
    auto sourceIt = std::find_if(tracks_.begin(), tracks_.end(), [&](const Track& track) {
        return track.id == trackId;
    });
    if (sourceIt == tracks_.end()) {
        return false;
    }
    const bool movingGroup = sourceIt->isGroup;
    if (movingGroup && !parentGroupId.empty()) {
        return false;
    }

    if (!parentGroupId.empty()) {
        const auto groupIt = std::find_if(tracks_.begin(), tracks_.end(), [&](const Track& track) {
            return track.id == parentGroupId && track.isGroup;
        });
        if (groupIt == tracks_.end() || groupIt->id == trackId) {
            return false;
        }
    }

    if (!beforeTrackId.empty()) {
        const auto anchor = std::find_if(tracks_.begin(), tracks_.end(), [&](const Track& track) {
            return track.id == beforeTrackId;
        });
        if (anchor == tracks_.end() || anchor->id == trackId ||
            anchor->parentGroupId != parentGroupId ||
            (movingGroup && anchor->parentGroupId == trackId)) {
            return false;
        }
    }

    std::vector<Track> moving;
    std::vector<Track> remaining;
    moving.reserve(movingGroup ? tracks_.size() : 1);
    remaining.reserve(tracks_.size());
    for (auto& track : tracks_) {
        if (track.id == trackId || (movingGroup && track.parentGroupId == trackId)) {
            moving.push_back(std::move(track));
        } else {
            remaining.push_back(std::move(track));
        }
    }
    if (moving.empty()) {
        return false;
    }
    moving.front().parentGroupId = parentGroupId;

    auto insertion = remaining.end();
    if (!beforeTrackId.empty()) {
        insertion = std::find_if(remaining.begin(), remaining.end(), [&](const Track& track) {
            return track.id == beforeTrackId;
        });
        if (insertion == remaining.end()) {
            return false;
        }
    } else if (!parentGroupId.empty()) {
        insertion = std::find_if(remaining.begin(), remaining.end(), [&](const Track& track) {
            return track.id == parentGroupId;
        });
        if (insertion == remaining.end()) {
            return false;
        }
        ++insertion;
        while (insertion != remaining.end() && insertion->parentGroupId == parentGroupId) {
            ++insertion;
        }
    }
    remaining.insert(insertion,
                     std::make_move_iterator(moving.begin()),
                     std::make_move_iterator(moving.end()));
    tracks_ = std::move(remaining);
    return true;
}

bool TrackRepository::setTrackMuted(const std::string& trackId, bool muted) {
    auto* track = findTrack(trackId);
    if (track == nullptr) {
        return false;
    }
    track->muted = muted;
    return true;
}

bool TrackRepository::setTrackSoloed(const std::string& trackId, bool soloed) {
    auto* track = findTrack(trackId);
    if (track == nullptr) {
        return false;
    }
    if (soloed) {
        for (auto& candidate : tracks_) {
            candidate.soloed = candidate.id == trackId;
        }
    } else {
        track->soloed = false;
    }
    return true;
}

bool TrackRepository::deleteTrack(const std::string& trackId) {
    if (tracks_.size() <= 1) {
        return false;
    }
    for (auto it = tracks_.begin(); it != tracks_.end(); ++it) {
        if (it->id != trackId) {
            continue;
        }
        if (it->isGroup) {
            for (auto& track : tracks_) {
                if (track.parentGroupId == trackId) {
                    track.parentGroupId.clear();
                }
            }
        }
        tracks_.erase(it);
        if (selectedTrackId_ == trackId) {
            selectedTrackId_ = tracks_.empty() ? std::string{} : tracks_.front().id;
        }
        return true;
    }
    return false;
}

bool TrackRepository::selectTrack(const std::string& trackId) {
    if (findTrack(trackId) == nullptr) {
        return false;
    }
    selectedTrackId_ = trackId;
    return true;
}

Track* TrackRepository::findTrack(const std::string& trackId) {
    for (auto& track : tracks_) {
        if (track.id == trackId) {
            return &track;
        }
    }
    return nullptr;
}

const Track* TrackRepository::findTrack(const std::string& trackId) const {
    for (const auto& track : tracks_) {
        if (track.id == trackId) {
            return &track;
        }
    }
    return nullptr;
}

std::string TrackRepository::allocateDeviceId() {
    return "dev-" + std::to_string(nextDeviceNum_++);
}

void TrackRepository::ensureTrackGainDevices(const DeviceRegistry& registry) {
    for (auto& track : tracks_) {
        bool hasGain = false;
        for (const auto& device : track.devices) {
            if (deviceNodeKindFromTypeId(device.config.typeId) == DeviceNodeKind::TrackGain) {
                hasGain = true;
                break;
            }
        }
        if (hasGain) {
            continue;
        }
        track.devices.push_back(
            registry.createDefault(device_types::kTrackGain, allocateDeviceId()));
    }
}

void TrackRepository::ensureTrackIcons() {
    for (size_t index = 0; index < tracks_.size(); ++index) {
        auto& track = tracks_[index];
        if (track.isGroup) {
            track.iconKey = "folder";
        } else if (track.iconKey.empty()) {
            track.iconKey = defaultIconKey(index);
        }
    }
}

int TrackRepository::maxIdSuffix(const std::string& id, const std::string& prefix) {
    if (id.rfind(prefix, 0) != 0) {
        return 0;
    }
    const auto suffix = id.substr(prefix.size());
    return suffix.empty() ? 0 : std::atoi(suffix.c_str());
}

void TrackRepository::recomputeIdCounters() {
    int maxTrack = 0;
    int maxDevice = 0;
    for (const auto& track : tracks_) {
        maxTrack = std::max(maxTrack, maxIdSuffix(track.id, "track-"));
        for (const auto& device : track.devices) {
            maxDevice = std::max(maxDevice, maxIdSuffix(device.id, "dev-"));
        }
    }
    nextTrackNum_ = maxTrack + 1;
    nextDeviceNum_ = maxDevice + 1;
}

} // namespace audioapp
