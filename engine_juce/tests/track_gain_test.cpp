#include "audioapp/EngineHost.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    audioapp::EngineHost host;
    host.createProject();
    const std::string trackId = host.addTrack("A");
    if (trackId.empty()) {
        return EXIT_FAILURE;
    }

    if (host.createSampleClip(trackId, "sample_kick", 0.0, 0.0).empty()) {
        return EXIT_FAILURE;
    }

    const std::string json = host.getProjectSnapshotJson();
    const auto gainPos = json.rfind("\"type\":\"track_gain\"");
    if (gainPos == std::string::npos) {
        return EXIT_FAILURE;
    }
    const auto idPos = json.rfind("\"id\":\"dev-", gainPos);
    if (idPos == std::string::npos) {
        return EXIT_FAILURE;
    }
    const auto idStart = idPos + 6;
    const auto idEnd = json.find('"', idStart);
    const std::string gainDeviceId = json.substr(idStart, idEnd - idStart);

    if (!host.setDeviceParameter(gainDeviceId, "gain", 0.5f)) {
        return EXIT_FAILURE;
    }

    host.setPlaying(true);
    float full[256] = {};
    float half[256] = {};
    host.readMasterMix(full, 256, 48000.0, 0.0);

    if (!host.setDeviceParameter(gainDeviceId, "gain", 0.25f)) {
        return EXIT_FAILURE;
    }
    host.readMasterMix(half, 256, 48000.0, 0.0);

    float peakFull = 0.0f;
    float peakHalf = 0.0f;
    for (int i = 0; i < 256; ++i) {
        peakFull = std::max(peakFull, std::abs(full[i]));
        peakHalf = std::max(peakHalf, std::abs(half[i]));
    }

    if (peakFull <= 0.0f || peakHalf <= 0.0f) {
        return EXIT_FAILURE;
    }

    if (peakHalf >= peakFull * 0.9f) {
        return EXIT_FAILURE;
    }

    if (!host.setMasterGain(0.5f)) {
        return EXIT_FAILURE;
    }

    float masterHalf[256] = {};
    host.readMasterMix(masterHalf, 256, 48000.0, 0.0);
    float peakMasterHalf = 0.0f;
    for (const float sample : masterHalf) {
        peakMasterHalf = std::max(peakMasterHalf, std::abs(sample));
    }

    if (peakMasterHalf >= peakHalf * 0.95f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
