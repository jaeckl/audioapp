#include "audioapp/EngineHost.hpp"

#include <cmath>
#include <iostream>
#include <vector>

namespace {

int failures = 0;

void expect(bool condition, const char* message) {
    if (condition) return;
    ++failures;
    std::cerr << "FAIL: " << message << '\n';
}

float rms(const std::vector<float>& audio) {
    double sum = 0.0;
    for (float sample : audio) sum += static_cast<double>(sample) * sample;
    return audio.empty() ? 0.0f : static_cast<float>(std::sqrt(sum / audio.size()));
}

size_t trackPosition(const std::string& json, const std::string& trackId) {
    return json.find("\"id\": \"" + trackId + "\"");
}

} // namespace

int main() {
    audioapp::EngineHost host;
    host.createProject();

    const auto child = host.addTrack("Drums");
    expect(!host.createSampleClip(child, "sample_kick", 0.0, 1.0).empty(),
           "child sample clip is created");
    const float direct = rms(host.renderOffline(1.0, 48000.0));

    const auto group = host.addGroupTrack("Drum Bus");
    expect(!group.empty(), "group track is created");
    expect(host.setTrackGroup(child, group), "child is assigned to group");
    const float grouped = rms(host.renderOffline(1.0, 48000.0));

    expect(direct > 0.001f, "direct child output is audible");
    expect(grouped > direct * 0.8f && grouped < direct * 1.2f,
           "grouped child reaches master exactly once");
    expect(host.setDeviceParameter("dev-2", "gain", 0.0f),
           "group gain can mute the child sum");
    const float muted = rms(host.renderOffline(1.0, 48000.0));
    expect(muted < grouped * 0.01f, "group chain processes the child sum");

    const std::string snapshot = host.getProjectSnapshotJson();
    expect(snapshot.find("\"isGroup\": true") != std::string::npos,
           "snapshot identifies the group");
    expect(snapshot.find("\"iconKey\": \"folder\"") != std::string::npos,
           "snapshot persists group icon metadata");
    expect(snapshot.find("\"parentGroupId\": \"" + group + "\"") != std::string::npos,
           "snapshot exposes child membership");

    audioapp::EngineHost restored;
    restored.createProject();
    expect(restored.loadProjectFileJson(host.getProjectFileJson()),
           "project with group membership reloads");
    const std::string restoredSnapshot = restored.getProjectSnapshotJson();
    expect(restoredSnapshot.find("\"isGroup\": true") != std::string::npos,
           "reloaded project keeps the group");
    expect(restoredSnapshot.find("\"iconKey\": \"folder\"") != std::string::npos,
           "reloaded project keeps track icon metadata");
    expect(restoredSnapshot.find("\"parentGroupId\": \"" + group + "\"") !=
               std::string::npos,
           "reloaded project keeps child membership");

    const auto receiver = host.addDeviceToTrack(child, "audio_receiver", 0);
    expect(!receiver.empty(), "child receiver is created");
    expect(!host.setDeviceStringParameter(receiver, "sourceId", "dev-2"),
           "routing from group back into its child is rejected");

    audioapp::EngineHost orderHost;
    orderHost.createProject();
    const auto orderGroup = orderHost.addGroupTrack("Bus");
    const auto first = orderHost.addTrack("First");
    const auto second = orderHost.addTrack("Second");
    const auto outside = orderHost.addTrack("Outside");
    expect(orderHost.moveTrack(first, orderGroup, ""),
           "track can be appended to a group");
    expect(orderHost.moveTrack(second, orderGroup, first),
           "track can be inserted before a group child");
    std::string ordered = orderHost.getProjectSnapshotJson();
    expect(trackPosition(ordered, orderGroup) < trackPosition(ordered, second) &&
               trackPosition(ordered, second) < trackPosition(ordered, first) &&
               trackPosition(ordered, first) < trackPosition(ordered, outside),
           "group child insertion order is reflected in the snapshot");

    expect(orderHost.moveTrack(first, "", orderGroup),
           "dropping outside removes group membership");
    ordered = orderHost.getProjectSnapshotJson();
    expect(trackPosition(ordered, first) < trackPosition(ordered, orderGroup) &&
               trackPosition(ordered, orderGroup) < trackPosition(ordered, second),
           "ungrouped track is inserted at its top-level anchor");

    expect(orderHost.moveTrack(orderGroup, "", first),
           "group track can move as a top-level block");
    ordered = orderHost.getProjectSnapshotJson();
    expect(trackPosition(ordered, orderGroup) < trackPosition(ordered, second) &&
               trackPosition(ordered, second) < trackPosition(ordered, first),
           "moving a group carries its children");
    expect(!orderHost.moveTrack(orderGroup, orderGroup, ""),
           "groups cannot be nested into themselves");

    if (failures != 0) return 1;
    std::cout << "All group track tests passed\n";
    return 0;
}
