#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

#include <cstdlib>
#include <string>

int main() {
    audioapp::EngineHost host;
    host.createProject();
    const std::string trackId = host.addTrack("Keys");
    host.createMidiClip(trackId, 0.0, 4.0);

    const std::string oscId =
        host.addDeviceToTrack(trackId, audioapp::device_types::kOscillator);
    const std::string samplerId =
        host.addDeviceToTrack(trackId, audioapp::device_types::kSampler);
    const std::string synthId =
        host.addDeviceToTrack(trackId, audioapp::device_types::kSubtractiveSynth);
    if (oscId.empty() || samplerId.empty() || synthId.empty()) {
        return EXIT_FAILURE;
    }

    host.setDeviceParameter(oscId, "frequency", 523.25f);
    host.setDeviceParameter(samplerId, "attack", 0.05f);
    host.setDeviceParameter(synthId, "filterCutoff", 0.6f);

    const std::string json = host.getProjectFileJson();
    if (json.find("\"project_format_version\"") == std::string::npos) {
        return EXIT_FAILURE;
    }
    if (json.find("simple_oscillator") == std::string::npos ||
        json.find("simple_sampler") == std::string::npos ||
        json.find("subtractive_synth") == std::string::npos ||
        json.find("track_gain") == std::string::npos) {
        return EXIT_FAILURE;
    }

    audioapp::ProjectFileData parsed;
    if (!audioapp::parseProjectFileJson(json, parsed)) {
        return EXIT_FAILURE;
    }
    if (parsed.tracks.size() != 1 || parsed.tracks[0].name != "Keys") {
        return EXIT_FAILURE;
    }
    if (parsed.tracks[0].devices.size() < 4) {
        return EXIT_FAILURE;
    }

    audioapp::EngineHost loaded;
    loaded.createProject();
    if (!loaded.loadProjectFileJson(json)) {
        return EXIT_FAILURE;
    }

    const std::string snapshotJson = loaded.getProjectSnapshotJson();
    if (snapshotJson.find("Keys") == std::string::npos) {
        return EXIT_FAILURE;
    }
    if (snapshotJson.find("523.25") == std::string::npos) {
        return EXIT_FAILURE;
    }

    const std::string roundTripJson = loaded.getProjectFileJson();
    audioapp::ProjectFileData roundTrip;
    if (!audioapp::parseProjectFileJson(roundTripJson, roundTrip)) {
        return EXIT_FAILURE;
    }
    if (roundTrip.tracks[0].devices.size() != parsed.tracks[0].devices.size()) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
