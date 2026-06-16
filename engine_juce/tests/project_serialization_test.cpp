#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cstdlib>
#include <string>

int main() {
    audioapp::EngineHost host;
    host.createProject();
  const std::string trackId = host.addTrack("Keys");
    host.createMidiClip(trackId, 0.0, 4.0);

    const std::string json = host.getProjectFileJson();
    if (json.find("\"project_format_version\"") == std::string::npos) {
        return EXIT_FAILURE;
    }

    audioapp::ProjectFileData parsed;
    if (!audioapp::parseProjectFileJson(json, parsed)) {
        return EXIT_FAILURE;
    }
    if (parsed.tracks.size() != 1 || parsed.tracks[0].name != "Keys") {
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

    return EXIT_SUCCESS;
}
