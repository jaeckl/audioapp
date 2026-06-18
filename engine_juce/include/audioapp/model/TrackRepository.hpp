#pragma once

#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/model/TrackModel.hpp"

#include <cstdlib>
#include <string>
#include <vector>

namespace audioapp {

class TrackRepository {
public:
    void clear();

    std::string addTrack(const std::string& name, const DeviceRegistry& registry);
    bool deleteTrack(const std::string& trackId);
    bool selectTrack(const std::string& trackId);

    Track* findTrack(const std::string& trackId);
    const Track* findTrack(const std::string& trackId) const;

    std::vector<Track>& tracks() { return tracks_; }
    const std::vector<Track>& tracks() const { return tracks_; }

    const std::string& selectedTrackId() const { return selectedTrackId_; }
    void setSelectedTrackId(std::string trackId) { selectedTrackId_ = std::move(trackId); }

    std::string allocateDeviceId();
    void ensureTrackGainDevices(const DeviceRegistry& registry);
    void recomputeIdCounters();

    int nextTrackNum() const { return nextTrackNum_; }
    int nextDeviceNum() const { return nextDeviceNum_; }

private:
    static int maxIdSuffix(const std::string& id, const std::string& prefix);

    std::vector<Track> tracks_;
    std::string selectedTrackId_;
    int nextTrackNum_ = 1;
    int nextDeviceNum_ = 1;
};

} // namespace audioapp
