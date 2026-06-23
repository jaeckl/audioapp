#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectArchive.hpp"
#include "audioapp/ProjectJson.hpp"

#include <filesystem>

class ProjectArchiveTest : public juce::UnitTest {
public:
    ProjectArchiveTest() : juce::UnitTest("ProjectArchive", "Project") {}

    void runTest() override
    {
        const auto tempArchive =
            std::filesystem::temp_directory_path() / "audioapp_project_archive_test.audioapp.zip";
        std::error_code ec;
        std::filesystem::remove(tempArchive, ec);

        auto project = std::make_unique<audioapp::ProjectEngine>();
        project->createProject();
        const std::string trackId = project->addTrack("Bass");
        project->createMidiClip(trackId, 0.0, 4.0);

        const auto before = project->snapshot();
        expect(before.tracks.size() == 1, "should have one track before save");

        expect(audioapp::saveProjectToArchive(*project, tempArchive.string()),
               "save to archive should succeed");

        expect(std::filesystem::exists(tempArchive),
               "archive file should exist after save");

        auto loaded = std::make_unique<audioapp::ProjectEngine>();
        loaded->createProject();
        expect(audioapp::loadProjectFromArchive(*loaded, tempArchive.string()),
               "load from archive should succeed");

        const auto after = loaded->snapshot();
        expect(after.tracks.size() == 1, "should have one track after loading");
        expect(after.tracks[0].name == "Bass", "track name should be preserved");
        expect(!after.tracks[0].midiClips.empty(), "MIDI clips should be preserved");

        std::filesystem::remove(tempArchive, ec);
    }
};

static ProjectArchiveTest projectArchiveTest;