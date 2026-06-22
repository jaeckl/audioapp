#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"

class SampleClipTest : public juce::UnitTest {
public:
    SampleClipTest() : juce::UnitTest("SampleClip", "Engine") {}
    void runTest() override {
        beginTest("create and snapshot sample clip");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Drums");
            const std::string clipId = host.createSampleClip(trackId, "sample_kick", 0.0, 0.0);
            expect(!clipId.empty(), "sample clip created");

            const std::string json = host.getProjectSnapshotJson();
            expect(json.find("sample_kick") != std::string::npos,
                   "snapshot contains sample_kick");
            expect(json.find("sampleClips") != std::string::npos,
                   "snapshot contains sampleClips");
        }
        beginTest("save and load round-trip");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Drums");
            host.createSampleClip(trackId, "sample_kick", 0.0, 0.0);

            const std::string projectJson = host.getProjectFileJson();
            audioapp::EngineHost loaded;
            loaded.createProject();
            expect(loaded.loadProjectFileJson(projectJson), "loadProjectFileJson succeeded");

            const std::string loadedSnapshot = loaded.getProjectSnapshotJson();
            expect(loadedSnapshot.find("sample_kick") != std::string::npos,
                   "loaded snapshot contains sample_kick");
        }
        beginTest("natural length preserved across resize");
        {
            // Resize changes lengthBeats but must never touch naturalLengthBeats.
            // The arranger view uses naturalLengthBeats to render the waveform
            // at its natural density.
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Drums");
            const std::string clipId = host.createSampleClip(trackId, "sample_kick", 0.0, 0.0);
            expect(!clipId.empty(), "sample clip created");

            const auto initialSnap = host.getProjectSnapshot();
            expect(!initialSnap.tracks.empty() && !initialSnap.tracks[0].sampleClips.empty(),
                   "snapshot has sample clip");
            const double initialNatural = initialSnap.tracks[0].sampleClips[0].naturalLengthBeats;
            expect(initialNatural > 0.0, "naturalLengthBeats is positive after creation");

            // Shorten the clip; naturalLengthBeats must NOT change.
            expect(host.setClipLength(clipId, 1.0),
                   "setClipLength shortens clip");
            const auto shortenedSnap = host.getProjectSnapshot();
            const double shortenedNatural =
                shortenedSnap.tracks[0].sampleClips[0].naturalLengthBeats;
            expectWithinAbsoluteError(shortenedNatural, initialNatural, 0.001,
                                      "naturalLengthBeats unchanged after shorten");

            // Lengthen the clip past the natural length; still unchanged.
            expect(host.setClipLength(clipId, 12.0),
                   "setClipLength lengthens clip");
            const auto lengthenedSnap = host.getProjectSnapshot();
            const double lengthenedNatural =
                lengthenedSnap.tracks[0].sampleClips[0].naturalLengthBeats;
            expectWithinAbsoluteError(lengthenedNatural, initialNatural, 0.001,
                                      "naturalLengthBeats unchanged after lengthen");
        }
    }
};
static SampleClipTest sampleClipTest;