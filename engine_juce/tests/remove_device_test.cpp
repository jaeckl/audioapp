#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"

#include <cmath>
#include <string>
#include <vector>

namespace {

float meanAbsDifference(const std::vector<float>& a, const std::vector<float>& b) noexcept {
    const size_t count = std::min(a.size(), b.size());
    if (count == 0) return 0.0f;
    double acc = 0.0;
    for (size_t i = 0; i < count; ++i) {
        acc += std::abs(a[i] - b[i]);
    }
    return static_cast<float>(acc / static_cast<double>(count));
}

} // namespace

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
            expect(audioapp::test::snapshotContainsDevice(json, samplerId),
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
        beginTest("fx after removed device still processes");
        {
            auto renderAfterRemove = [](bool bypassDistortion) {
                audioapp::EngineHost host;
                host.createProject();
                const std::string trackId = host.addTrack("FX chain");
                host.selectTrack(trackId);

                const std::string oscId = host.addDeviceToTrack(trackId, "simple_oscillator");
                const std::string removedFxId = host.addDeviceToTrack(trackId, "bitcrusher");
                const std::string tremoloId = host.addDeviceToTrack(trackId, "tremolo");
                const std::string distortionId = host.addDeviceToTrack(trackId, "distortion");
                if (oscId.empty() || removedFxId.empty() || tremoloId.empty() || distortionId.empty()) {
                    return std::vector<float>{};
                }

                host.setDeviceParameter(tremoloId, "tremDepth", 0.75f);
                host.setDeviceParameter(distortionId, "distDrive", 1.0f);
                host.setDeviceParameter(distortionId, "distMix", 1.0f);

                const std::string clipId = host.createMidiClip(trackId, 0.0, 4.0);
                std::vector<audioapp::MidiNoteState> notes;
                notes.push_back({60, 0.0, 4.0, 100.0f});
                host.setMidiClipNotes(clipId, notes);

                host.removeDeviceFromTrack(removedFxId);
                if (bypassDistortion) {
                    host.setDeviceParameter(distortionId, "bypass", 1.0f);
                }
                return host.renderOffline(4.0, 48000.0);
            };

            const auto active = renderAfterRemove(false);
            const auto bypassed = renderAfterRemove(true);
            expect(audioapp::test::hasNonZeroSample(active), "active chain renders audio");
            expect(audioapp::test::hasNonZeroSample(bypassed), "bypassed comparison renders audio");
            expect(meanAbsDifference(active, bypassed) > 1.0e-4f,
                   "second remaining FX still changes audio after removing earlier FX");
        }
    }
};
static RemoveDeviceTest removeDeviceTest;
