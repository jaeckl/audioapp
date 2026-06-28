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
    expect(snapshot.find("\"parentGroupId\": \"" + group + "\"") != std::string::npos,
           "snapshot exposes child membership");

    audioapp::EngineHost restored;
    restored.createProject();
    expect(restored.loadProjectFileJson(host.getProjectFileJson()),
           "project with group membership reloads");
    const std::string restoredSnapshot = restored.getProjectSnapshotJson();
    expect(restoredSnapshot.find("\"isGroup\": true") != std::string::npos,
           "reloaded project keeps the group");
    expect(restoredSnapshot.find("\"parentGroupId\": \"" + group + "\"") !=
               std::string::npos,
           "reloaded project keeps child membership");

    const auto receiver = host.addDeviceToTrack(child, "audio_receiver", 0);
    expect(!receiver.empty(), "child receiver is created");
    expect(!host.setDeviceStringParameter(receiver, "sourceId", "dev-2"),
           "routing from group back into its child is rejected");

    if (failures != 0) return 1;
    std::cout << "All group track tests passed\n";
    return 0;
}
