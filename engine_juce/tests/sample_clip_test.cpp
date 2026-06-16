#include "audioapp/EngineHost.hpp"

#include <cstdlib>

int main() {
    audioapp::EngineHost host;
    host.createProject();
    const std::string trackId = host.addTrack("Drums");
    const std::string clipId = host.createSampleClip(trackId, "sample_kick", 0.0, 0.0);
    if (clipId.empty()) {
        return EXIT_FAILURE;
    }

    const std::string json = host.getProjectSnapshotJson();
    if (json.find("sample_kick") == std::string::npos) {
        return EXIT_FAILURE;
    }
    if (json.find("sampleClips") == std::string::npos) {
        return EXIT_FAILURE;
    }

    const std::string projectJson = host.getProjectFileJson();
    audioapp::EngineHost loaded;
    loaded.createProject();
    if (!loaded.loadProjectFileJson(projectJson)) {
        return EXIT_FAILURE;
    }
    const std::string loadedSnapshot = loaded.getProjectSnapshotJson();
    if (loadedSnapshot.find("sample_kick") == std::string::npos) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
