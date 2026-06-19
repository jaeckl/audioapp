#include "audioapp/EngineHost.hpp"

#include <cstdlib>
#include <string>

namespace {

bool snapshotContainsDevice(const std::string& json, const std::string& deviceId) {
    return json.find('"' + deviceId + '"') != std::string::npos;
}

} // namespace

int main() {
    audioapp::EngineHost host;
    host.createProject();
    const std::string trackId = host.addTrack("Devices");
    host.selectTrack(trackId);

    const std::string samplerId = host.addDeviceToTrack(trackId, "simple_sampler");
    const std::string fxId = host.addDeviceToTrack(trackId, "compressor");
    if (samplerId.empty() || fxId.empty()) {
        return EXIT_FAILURE;
    }

    const std::string clipId = host.createAutomationClip(trackId, 0.0, 4.0);
    if (clipId.empty()) {
        return EXIT_FAILURE;
    }
    if (!host.assignAutomationTarget(clipId, fxId, "threshold")) {
        return EXIT_FAILURE;
    }

    const int lfoId = host.createLfo();
    if (lfoId <= 0) {
        return EXIT_FAILURE;
    }
    if (!host.assignModulation(lfoId, fxId, "threshold", 0.5f)) {
        return EXIT_FAILURE;
    }

    if (!host.removeDeviceFromTrack(fxId)) {
        return EXIT_FAILURE;
    }

    const std::string json = host.getProjectSnapshotJson();
    if (snapshotContainsDevice(json, fxId)) {
        return EXIT_FAILURE;
    }
    if (json.find("\"deviceId\":\"" + fxId + "\"") != std::string::npos) {
        return EXIT_FAILURE;
    }
    if (json.find("\"deviceId\":\"" + samplerId + "\"") == std::string::npos) {
        return EXIT_FAILURE;
    }

    if (!host.removeDeviceFromTrack("dev-missing")) {
        // expected
    } else {
        return EXIT_FAILURE;
    }

    if (host.removeDeviceFromTrack("dev-1")) {
        return EXIT_FAILURE;
    }

    if (!host.removeDeviceFromTrack(samplerId)) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
