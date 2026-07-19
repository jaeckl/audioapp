#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectEngine.hpp"

class PlayTransportResponsivenessTest : public juce::UnitTest {
public:
    PlayTransportResponsivenessTest()
        : juce::UnitTest("PlayTransportResponsiveness", "Transport") {}

    void runTest() override {
        beginTest("setPlaying does not rebuild playback graph");
        {
            audioapp::ProjectEngine project;
            project.createProject();
            expectEquals(static_cast<int>(project.playbackRebuildCount()), 0);

            const std::string trackId = project.addTrack("Drums");
            expect(!trackId.empty(), "track created");
            const uint32_t rebuildsAfterTrack = project.playbackRebuildCount();
            expect(rebuildsAfterTrack > 0u, "addTrack should rebuild playback");

            project.setPlaying(true);
            expect(project.isPlaying(), "transport should be playing");
            expect(project.playbackRebuildCount() == rebuildsAfterTrack,
                   "setPlaying(true) should not rebuild");

            project.setPlaying(false);
            expect(!project.isPlaying(), "transport should be stopped");
            expect(project.playbackRebuildCount() == rebuildsAfterTrack,
                   "setPlaying(false) should not rebuild");

            project.setPlaying(true);
            expect(project.isPlaying(), "transport should play again");
            expect(project.playbackRebuildCount() == rebuildsAfterTrack,
                   "second setPlaying(true) should not rebuild");
        }

        beginTest("play stop play still renders arrangement audio");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Drums");
            const std::string kickId = host.addDeviceToTrack(trackId, "kick_generator");
            expect(!kickId.empty(), "kick device created");

            const std::string clipId = host.createMidiClip(trackId, 0.0, 4.0);
            host.setMidiClipNotes(clipId, {{36, 0.0, 1.0, 127.0f}});

            host.setPlaying(true);
            const std::vector<float> firstPass = host.renderOffline(1.0, 48000.0);
            expect(audioapp::test::peakAbs(firstPass.data(), static_cast<int>(firstPass.size())) > 1.0e-4f,
                   "first play pass should render audio");

            host.setPlaying(false);
            host.setPlaying(true);
            const std::vector<float> secondPass = host.renderOffline(1.0, 48000.0);
            expect(audioapp::test::peakAbs(secondPass.data(), static_cast<int>(secondPass.size())) > 1.0e-4f,
                   "second play pass should render audio without play-time rebuild");
        }

        beginTest("edits rebuild playback; play reuses latest graph");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Synth");
            const std::string deviceId = host.addDeviceToTrack(trackId, "simple_oscillator");
            expect(!deviceId.empty(), "oscillator device created");

            const std::string clipId = host.createMidiClip(trackId, 0.0, 4.0);
            host.setMidiClipNotes(clipId, {{60, 0.0, 1.0, 127.0f}});

            expect(host.setDeviceParameter(deviceId, "gain", 0.05f), "lower gain");
            host.setPlaying(true);
            const std::vector<float> quiet = host.renderOffline(1.0, 48000.0);
            const float quietPeak =
                audioapp::test::peakAbs(quiet.data(), static_cast<int>(quiet.size()));

            host.setPlaying(false);
            expect(host.setDeviceParameter(deviceId, "gain", 1.0f), "raise gain");
            host.setPlaying(true);
            const std::vector<float> loud = host.renderOffline(1.0, 48000.0);
            const float loudPeak =
                audioapp::test::peakAbs(loud.data(), static_cast<int>(loud.size()));

            expect(loudPeak > quietPeak * 1.5f,
                   "play after edit should use graph rebuilt by the edit");
        }
    }
};

static PlayTransportResponsivenessTest playTransportResponsivenessTest;
