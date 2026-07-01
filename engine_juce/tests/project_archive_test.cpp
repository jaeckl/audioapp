#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectArchive.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/TrackFreezeAssetStore.hpp"

class ProjectArchiveTest : public juce::UnitTest {
public:
    ProjectArchiveTest() : juce::UnitTest("ProjectArchive", "Project") {}

    void runTest() override
    {
        const auto tempArchive =
            juce::File::getSpecialLocation(juce::File::tempDirectory)
                .getChildFile("audioapp_project_archive_test.audioapp.zip");
        tempArchive.deleteFile();

        auto project = std::make_unique<audioapp::ProjectEngine>();
        project->createProject();
        const std::string trackId = project->addTrack("Bass");
        project->createMidiClip(trackId, 0.0, 4.0);

        audioapp::TrackFreezeAssetStore freezeAssets;
        bool ok = true;

        const auto before = project->snapshot();
        ok = ok && (before.tracks.size() == 1u);

        ok = ok && audioapp::saveProjectToArchive(*project, freezeAssets,
                                                 tempArchive.getFullPathName().toStdString());
        ok = ok && tempArchive.existsAsFile();

        auto loaded = std::make_unique<audioapp::ProjectEngine>();
        loaded->createProject();
        audioapp::TrackFreezeAssetStore loadedFreezeAssets;
        ok = ok && audioapp::loadProjectFromArchive(*loaded, loadedFreezeAssets,
                                                   tempArchive.getFullPathName().toStdString());

        const auto after = loaded->snapshot();
        ok = ok && (after.tracks.size() == 1u);
        ok = ok && (after.tracks[0].name == "Bass");
        ok = ok && !after.tracks[0].midiClips.empty();

        tempArchive.deleteFile();

        if (!ok)
            std::fprintf(stderr, "FAIL: archive roundtrip failed\n");
    }
};

static ProjectArchiveTest projectArchiveTest;
