#include "audioapp/model/TrackRepository.hpp"

#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/TrackGainInstance.hpp"

#include <algorithm>

namespace audioapp {

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

    const std::string gainId = allocateDeviceId();
    track.devices.push_back(registry.createDefault(device_types::kTrackGain, gainId));

    tracks_.push_back(std::move(track));
    selectedTrackId_ = tracks_.back().id;
    return selectedTrackId_;
}

bool TrackRepository::deleteTrack(const std::string& trackId) {
    if (tracks_.size() <= 1) {
        return false;
    }
    for (auto it = tracks_.begin(); it != tracks_.end(); ++it) {
        if (it->id != trackId) {
            continue;
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
            if (std::holds_alternative<TrackGainInstance>(device.instance)) {
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
