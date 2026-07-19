#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/ProjectEngine.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/NestingError.hpp"

class DeviceOpenNestingSmokeTest : public juce::UnitTest {
public:
    DeviceOpenNestingSmokeTest()
        : juce::UnitTest("DeviceOpenNestingSmoke", "Devices") {}

    void runTest() override {
        using namespace audioapp;

        beginTest("S1 chain in chain compressor");
        {
            auto project = std::make_unique<ProjectEngine>();
            project->createProject();
            const auto trackId = project->addTrack("S1");
            const auto outer = project->addDeviceToTrack(trackId, device_types::kChain);
            const auto inner = project->addDeviceToChain(outer, device_types::kChain);
            const auto fx = project->addDeviceToChain(inner, device_types::kCompressor);
            expect(!outer.empty() && !inner.empty() && !fx.empty());
            expect(project->setDeviceParameter(fx, "compThreshold", 0.3f));
            expect(project->lastNestingError().ok());
        }

        beginTest("S5 synth audioFx accepts device_chain then FX");
        {
            auto project = std::make_unique<ProjectEngine>();
            project->createProject();
            const auto trackId = project->addTrack("S5");
            const auto synthId =
                project->addDeviceToTrack(trackId, device_types::kSubtractiveSynth);
            expect(!synthId.empty());
            const auto chainId =
                project->addDeviceToSynthAudioFx(synthId, device_types::kChain);
            expect(!chainId.empty(), "synth audioFx accepts device_chain");
            expect(project->lastNestingError().ok());
            const auto fxId =
                project->addDeviceToChain(chainId, device_types::kDelay);
            expect(!fxId.empty(), "FX inside synth-nested chain");
        }

        beginTest("S6 ninth nest branch device returns branch_device_cap");
        {
            auto project = std::make_unique<ProjectEngine>();
            project->createProject();
            const auto trackId = project->addTrack("S6");
            const auto chainId = project->addDeviceToTrack(trackId, device_types::kChain);
            for (int i = 0; i < kMaxDevicesPerNestBranch; ++i) {
                const auto id =
                    project->addDeviceToChain(chainId, device_types::kFilter);
                expect(!id.empty(), "fill branch under cap");
            }
            const auto ninth =
                project->addDeviceToChain(chainId, device_types::kFilter);
            expect(ninth.empty(), "9th device rejected");
            expect(project->lastNestingError().code == NestingErrorCode::BranchDeviceCap);
            expect(std::string(nestingErrorBridgeCode(project->lastNestingError().code)) ==
                   "branch_device_cap");
        }

        beginTest("synth audioFx ninth device returns branch_device_cap");
        {
            auto project = std::make_unique<ProjectEngine>();
            project->createProject();
            const auto trackId = project->addTrack("SynthCap");
            const auto synthId =
                project->addDeviceToTrack(trackId, device_types::kSubtractiveSynth);
            for (int i = 0; i < kMaxDevicesPerNestBranch; ++i) {
                expect(!project->addDeviceToSynthAudioFx(synthId, device_types::kFilter)
                            .empty());
            }
            expect(project->addDeviceToSynthAudioFx(synthId, device_types::kFilter).empty());
            expect(project->lastNestingError().code == NestingErrorCode::BranchDeviceCap);
        }
    }
};

static DeviceOpenNestingSmokeTest deviceOpenNestingSmokeTest;
