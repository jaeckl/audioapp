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

    const auto trackA = host.addTrack("A");
    const auto trackB = host.addTrack("B");
    expect(!host.createSampleClip(trackA, "sample_kick", 0.0, 1.0).empty(),
           "track A clip created");
    expect(!host.createSampleClip(trackB, "sample_snare", 0.0, 1.0).empty(),
           "track B clip created");

    const float both = rms(host.renderOffline(1.0, 48000.0));
    expect(both > 0.001f, "both tracks audible by default");

    expect(host.setTrackMuted(trackA, true), "mute track A");
    const float mutedA = rms(host.renderOffline(1.0, 48000.0));
    expect(mutedA < both * 0.85f, "muting one track reduces the mix");
    expect(host.getProjectSnapshotJson().find("\"muted\": true") != std::string::npos,
           "snapshot exposes muted state");

    expect(host.setTrackMuted(trackA, false), "unmute track A");
    expect(host.setTrackMuted(trackB, true), "mute track B");
    const float muteBOnly = rms(host.renderOffline(1.0, 48000.0));
    expect(host.setTrackMuted(trackB, false), "unmute track B");

    expect(host.setTrackSoloed(trackA, true), "solo track A");
    const float soloA = rms(host.renderOffline(1.0, 48000.0));
    expect(soloA > 0.001f, "solo track stays audible");
    expect(std::abs(soloA - muteBOnly) < muteBOnly * 0.2f,
           "solo isolates to the chosen track");
    expect(host.getProjectSnapshotJson().find("\"soloed\": true") != std::string::npos,
           "snapshot exposes soloed state");

    audioapp::EngineHost restored;
    restored.createProject();
    expect(restored.loadProjectFileJson(host.getProjectFileJson()),
           "mute/solo state reloads from project file");
    expect(restored.getProjectSnapshotJson().find("\"soloed\": true") != std::string::npos,
           "reloaded project keeps solo state");

    if (failures != 0) return 1;
    std::cout << "All track mute/solo tests passed\n";
    return 0;
}
