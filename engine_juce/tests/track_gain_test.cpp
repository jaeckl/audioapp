#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"

class TrackGainTest : public juce::UnitTest {
public:
    TrackGainTest() : juce::UnitTest("TrackGain", "Dynamics") {}
    void runTest() override {
        beginTest("track gain reduces level");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("A");
            expect(!trackId.empty(), "track created");

            expect(!host.createSampleClip(trackId, "sample_kick", 0.0, 0.0).empty(),
                   "sample clip created");

            const std::string json = host.getProjectSnapshotJson();
            const auto gainPos = json.rfind("\"type\":\"track_gain\"");
            expect(gainPos != std::string::npos, "track_gain in snapshot");
            const auto idPos = json.rfind("\"id\":\"dev-", gainPos);
            expect(idPos != std::string::npos, "device id in snapshot");
            const auto idStart = idPos + 6;
            const auto idEnd = json.find('"', idStart);
            const std::string gainDeviceId = json.substr(idStart, idEnd - idStart);

            expect(host.setDeviceParameter(gainDeviceId, "gain", 0.5f), "set gain to 0.5");

            host.setPlaying(true);
            float full[256] = {};
            float half[256] = {};
            host.readMasterMix(full, 256, 48000.0, 0.0);

            expect(host.setDeviceParameter(gainDeviceId, "gain", 0.25f), "set gain to 0.25");
            host.readMasterMix(half, 256, 48000.0, 0.0);

            float peakFull = 0.0f;
            float peakHalf = 0.0f;
            for (int i = 0; i < 256; ++i) {
                peakFull = std::max(peakFull, std::abs(full[i]));
                peakHalf = std::max(peakHalf, std::abs(half[i]));
            }
            expect(peakFull > 0.0f && peakHalf > 0.0f, "both buffers non-zero");
            expect(peakHalf < peakFull * 0.9f, "reduced gain reduces peak");
        }
        beginTest("master gain reduces level");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("A");
            host.createSampleClip(trackId, "sample_kick", 0.0, 0.0);

            const std::string json = host.getProjectSnapshotJson();
            const auto gainPos = json.rfind("\"type\":\"track_gain\"");
            const auto idPos = json.rfind("\"id\":\"dev-", gainPos);
            const auto idStart = idPos + 6;
            const auto idEnd = json.find('"', idStart);
            const std::string gainDeviceId = json.substr(idStart, idEnd - idStart);
            host.setDeviceParameter(gainDeviceId, "gain", 0.5f);

            host.setPlaying(true);
            float half[256] = {};
            host.readMasterMix(half, 256, 48000.0, 0.0);
            float peakHalf = 0.0f;
            for (const float sample : half)
                peakHalf = std::max(peakHalf, std::abs(sample));

            expect(host.setMasterGain(0.5f), "set master gain");

            float masterHalf[256] = {};
            host.readMasterMix(masterHalf, 256, 48000.0, 0.0);
            float peakMasterHalf = 0.0f;
            for (const float sample : masterHalf)
                peakMasterHalf = std::max(peakMasterHalf, std::abs(sample));

            expect(peakMasterHalf < peakHalf * 0.95f, "master gain reduces peak");
        }
    }
};
static TrackGainTest trackGainTest;