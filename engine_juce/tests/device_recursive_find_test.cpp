#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/ProjectEngine.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

class DeviceRecursiveFindTest : public juce::UnitTest {
public:
    DeviceRecursiveFindTest()
        : juce::UnitTest("DeviceRecursiveFind", "Devices") {}

    void runTest() override {
        using namespace audioapp;

        beginTest("findDeviceLocked + setDeviceParameter depth-3 chain chain device");
        {
            auto project = std::make_unique<ProjectEngine>();
            project->createProject();
            const auto trackId = project->addTrack("Nest");
            const auto chainId = project->addDeviceToTrack(trackId, device_types::kChain);
            const auto splitId = project->addDeviceToChain(chainId, device_types::kLrSplit);
            const auto fxId = project->addDeviceToSplitBranch(splitId, 0, device_types::kFilter);
            expect(!chainId.empty() && !splitId.empty() && !fxId.empty());

            expect(project->setDeviceParameter(fxId, "ffxCutoff", 0.4f),
                   "set param on depth-3 chain split filter");
            expect(project->setDeviceParameter(splitId, "branch0Gain", 0.8f),
                   "set param on depth-2 split container");
        }

        beginTest("modulation edge resolves to depth-3 nested leaf");
        {
            auto project = std::make_unique<ProjectEngine>();
            project->createProject();
            const auto trackId = project->addTrack("NestMod");
            const auto chainId = project->addDeviceToTrack(trackId, device_types::kChain);
            const auto splitId = project->addDeviceToChain(chainId, device_types::kLrSplit);
            const auto fxId = project->addDeviceToSplitBranch(splitId, 0, device_types::kFilter);
            expect(!fxId.empty());

            const int lfoId = project->createLfo(0);
            expect(lfoId >= 0, "lfo created");
            expect(project->assignModulation(lfoId, fxId, "ffxCutoff", 0.5f),
                   "mod edge assigned to nested leaf");

            const auto snap = project->snapshot();
            expect(!snap.modEdges.empty(), "mod edge persisted in snapshot");
            expect(snap.modEdges[0].deviceId == fxId);
        }

        beginTest("automation target resolves for spectral PRE nested device");
        {
            auto project = std::make_unique<ProjectEngine>();
            project->createProject();
            const auto trackId = project->addTrack("Spectral");
            const auto slId =
                project->addDeviceToTrack(trackId, device_types::kSpectralLoudSplit);
            expect(!slId.empty());
            const auto preFxId =
                project->addDeviceToSpectralLoudPreFx(slId, device_types::kFilter);
            expect(!preFxId.empty(), "PRE filter added");

            const auto clipId = project->createAutomationClip(trackId, 0.0, 4.0);
            expect(!clipId.empty());
            expect(project->assignAutomationTarget(clipId, preFxId, "ffxCutoff"),
                   "automation assigned to PRE nested filter");
        }
    }
};

static DeviceRecursiveFindTest deviceRecursiveFindTest;
