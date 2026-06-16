#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectArchive.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cstdlib>
#include <filesystem>

int main() {
    const auto tempArchive =
        std::filesystem::temp_directory_path() / "audioapp_project_archive_test.audioapp.zip";
    std::error_code ec;
    std::filesystem::remove(tempArchive, ec);

    audioapp::ProjectEngine project;
    project.createProject();
    const std::string trackId = project.addTrack("Bass");
    project.createMidiClip(trackId, 0.0, 4.0);

    const auto before = project.snapshot();
    if (before.tracks.size() != 1) {
        return EXIT_FAILURE;
    }

    if (!audioapp::saveProjectToArchive(project, tempArchive.string())) {
        return EXIT_FAILURE;
    }

    if (!std::filesystem::exists(tempArchive)) {
        return EXIT_FAILURE;
    }

    audioapp::ProjectEngine loaded;
    loaded.createProject();
    if (!audioapp::loadProjectFromArchive(loaded, tempArchive.string())) {
        return EXIT_FAILURE;
    }

    const auto after = loaded.snapshot();
    if (after.tracks.size() != 1 || after.tracks[0].name != "Bass") {
        return EXIT_FAILURE;
    }
    if (after.tracks[0].midiClips.empty()) {
        return EXIT_FAILURE;
    }

    std::filesystem::remove(tempArchive, ec);
    return EXIT_SUCCESS;
}
