#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"

#include <string>

class RemoveDeviceTest : public juce::UnitTest {
public:
    RemoveDeviceTest() : juce::UnitTest("RemoveDevice", "Devices") {}
    void runTest() override {
        beginTest("remove device from track");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Devices");
            host.selectTrack(trackId);

            const std::string samplerId = host.addDeviceToTrack(trackId, "simple_sampler");
            const std::string fxId = host.addDeviceToTrack(trackId, "compressor");
            expect(!samplerId.empty(), "sampler created");
            expect(!fxId.empty(), "compressor created");

            const std::string clipId = host.createAutomationClip(trackId, 0.0, 4.0);
            expect(!clipId.empty(), "auto clip created");
            expect(host.assignAutomationTarget(clipId, fxId, "threshold"),
                   "assign auto target");
            const int lfoId = host.createLfo();
            expect(lfoId > 0, "LFO created");
            expect(host.assignModulation(lfoId, fxId, "threshold", 0.5f),
                   "assign modulation");

            expect(host.removeDeviceFromTrack(fxId), "remove fx device");

            const std::string json = host.getProjectSnapshotJson();
            expect(!audioapp::test::snapshotContainsDevice(json, fxId),
                   "removed device not in snapshot");
            expect(json.find("\"deviceId\":\"" + fxId + "\"") == std::string::npos,
                   "no auto target referencing removed device");
            expect(json.find("\"deviceId\":\"" + samplerId + "\"") != std::string::npos,
                   "sampler still in snapshot");
        }
        beginTest("remove missing device returns false");
        {
            audioapp::EngineHost host;
            host.createProject();
            expect(!host.removeDeviceFromTrack("dev-missing"),
                   "remove missing returns false");
        }
        beginTest("remove track-1 (always-present device) returns false");
        {
            audioapp::EngineHost host;
            host.createProject();
            host.addTrack("Devices");
            host.selectTrack("track-1");
            expect(!host.removeDeviceFromTrack("dev-1"),
                   "remove track_gain returns false");
        }
        beginTest("remove all devices from track");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Devices");
            host.selectTrack(trackId);

            const std::string samplerId = host.addDeviceToTrack(trackId, "simple_sampler");
            expect(!samplerId.empty(), "sampler created");

            expect(host.removeDeviceFromTrack(samplerId),
                   "remove sampler device");
        }
    }
};
static RemoveDeviceTest removeDeviceTest;