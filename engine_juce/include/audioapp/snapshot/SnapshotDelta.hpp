#pragma once

#include <optional>
#include <string>
#include <vector>

#include <juce_core/juce_core.h>

namespace audioapp::snapshot {

/// Describes a single parameter change on a device.
struct DeviceParamDelta {
    std::string paramId;
    float newValue = 0.0f;
};

/// Describes changes to a single device slot.
struct DeviceDelta {
    std::string deviceId;
    std::vector<DeviceParamDelta> params;
    bool deviceAdded = false;
    bool deviceRemoved = false;
};

/// Describes changes to a single track.
struct TrackDelta {
    std::string trackId;
    std::vector<DeviceDelta> devices;
    bool trackAdded = false;
    bool trackRemoved = false;
    bool trackSelected = false;
};

/// Describes a single modulator parameter change.
struct ModulatorParamDelta {
    std::string param;
    float newValue = 0.0f;
};

/// Describes changes to a single modulator.
struct ModulatorDelta {
    int lfoId = 0;
    std::vector<ModulatorParamDelta> params;
    bool modulatorAdded = false;
    bool modulatorRemoved = false;
};

/// Describes transport-level changes.
struct TransportDelta {
    bool bpmChanged = false;
    int newBpm = 120;
    bool playingChanged = false;
    bool newPlaying = false;
};

/// Describes a single mutation delta. Returned by mutation commands
/// instead of a full project snapshot.
struct SnapshotDelta {
    std::vector<TrackDelta> tracks;
    std::vector<ModulatorDelta> modulators;
    std::optional<TransportDelta> transport;

    /// If true, the client must perform a full refresh (project load, undo, etc.)
    bool fullRefresh = false;

    /// Full snapshot payload, only set when fullRefresh is true.
    juce::var fullSnapshot;

    /// Serialize this delta to a JSON string suitable for bridge transport.
    std::string toJson() const;

    /// Build a "full refresh" delta that includes a complete snapshot.
    static SnapshotDelta fullRefreshDelta(juce::var snapshot);
};

} // namespace audioapp::snapshot