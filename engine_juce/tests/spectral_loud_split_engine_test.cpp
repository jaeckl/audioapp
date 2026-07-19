#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/instances/SpectralLoudSplitModel.hpp"

#include <memory>
#include <string>

class SpectralLoudSplitEngineTest : public juce::UnitTest {
public:
    SpectralLoudSplitEngineTest()
        : juce::UnitTest("SpectralLoudSplitEngine", "Devices") {}

    void runTest() override {
        beginTest("add/remove band, pre, post FX");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            const auto track = project->addTrack("SL");
            expect(!track.empty());
            const auto slId =
                project->addDeviceToTrack(track, audioapp::device_types::kSpectralLoudSplit);
            expect(!slId.empty(), "should add spectral loud split");

            const auto bandFx =
                project->addDeviceToSpectralLoudBand(slId, 0, audioapp::device_types::kCompressor);
            expect(!bandFx.empty(), "compressor on loud band");
            const auto preFx =
                project->addDeviceToSpectralLoudPreFx(slId, audioapp::device_types::kFilter);
            expect(!preFx.empty(), "filter on PRE");
            const auto postFx =
                project->addDeviceToSpectralLoudPostFx(slId, audioapp::device_types::kDelay);
            expect(!postFx.empty(), "delay on POST");

            expect(project->removeDeviceFromSpectralLoudBand(slId, 0, bandFx));
            expect(project->removeDeviceFromSpectralLoudPreFx(slId, preFx));
            expect(project->removeDeviceFromSpectralLoudPostFx(slId, postFx));
        }

        // Current product policy rejects container nesting. Planned: open nesting.
        beginTest("nest reject: containers blocked on band/pre/post");
        {
            auto project = std::make_unique<audioapp::ProjectEngine>();
            project->createProject();
            const auto track = project->addTrack("SL");
            const auto slId =
                project->addDeviceToTrack(track, audioapp::device_types::kSpectralLoudSplit);
            expect(!slId.empty());

            expect(project
                       ->addDeviceToSpectralLoudBand(slId, 1,
                                                     audioapp::device_types::kMbSplit2)
                       .empty(),
                   "mb_split rejected on band");
            expect(project
                       ->addDeviceToSpectralLoudBand(slId, 1,
                                                     audioapp::device_types::kSpectralLoudSplit)
                       .empty(),
                   "spectral rejected on band");
            expect(project
                       ->addDeviceToSpectralLoudBand(slId, 1, audioapp::device_types::kChain)
                       .empty(),
                   "chain rejected on band");
            expect(project
                       ->addDeviceToSpectralLoudBand(slId, 1, audioapp::device_types::kLrSplit)
                       .empty(),
                   "lr_split rejected on band");

            expect(project
                       ->addDeviceToSpectralLoudPreFx(slId,
                                                     audioapp::device_types::kMbSplit3)
                       .empty(),
                   "mb_split rejected on PRE");
            expect(project
                       ->addDeviceToSpectralLoudPreFx(slId,
                                                     audioapp::device_types::kSpectralLoudSplit)
                       .empty(),
                   "spectral rejected on PRE");
            expect(project
                       ->addDeviceToSpectralLoudPostFx(slId, audioapp::device_types::kChain)
                       .empty(),
                   "chain rejected on POST");
            expect(project
                       ->addDeviceToSpectralLoudPostFx(slId, audioapp::device_types::kMsSplit)
                       .empty(),
                   "ms_split rejected on POST");
        }

        beginTest("parameter + JSON round-trip nested spectral loud");
        {
            const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
            audioapp::DeviceSlot slot =
                registry.createDefault(audioapp::device_types::kSpectralLoudSplit, "sl-rt");
            expect(!slot.id.empty());

            auto result = registry.setParameter(slot, "highDb", -12.0f);
            expect(result.handled);
            result = registry.setParameter(slot, "lowDb", -36.0f);
            expect(result.handled);
            result = registry.setParameter(slot, "band0Gain", 0.9f);
            expect(result.handled);
            result = registry.setParameter(slot, "band2Solo", 1.0f);
            expect(result.handled);
            result = registry.setParameter(slot, "outputMix", 0.55f);
            expect(result.handled);

            auto& model = std::get<audioapp::SpectralLoudSplitModel>(slot.config.instance);
            model.bands[0].push_back(std::make_shared<audioapp::DeviceSlot>(
                registry.createDefault(audioapp::device_types::kCompressor, "eq-loud")));
            model.preFxDevices.push_back(std::make_shared<audioapp::DeviceSlot>(
                registry.createDefault(audioapp::device_types::kFilter, "pre-f")));
            model.postFxDevices.push_back(std::make_shared<audioapp::DeviceSlot>(
                registry.createDefault(audioapp::device_types::kDelay, "post-d")));

            const std::string json = audioapp::deviceSlotToVar(slot, registry);
            audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(json, registry);
            expect(restored.id == slot.id);
            expect(restored.config.typeId == audioapp::device_types::kSpectralLoudSplit);

            const auto& restoredModel =
                std::get<audioapp::SpectralLoudSplitModel>(restored.config.instance);
            expectWithinAbsoluteError(restoredModel.highDb, -12.0f, 0.01f);
            expectWithinAbsoluteError(restoredModel.lowDb, -36.0f, 0.01f);
            expectWithinAbsoluteError(restoredModel.bandGain[0], 0.9f, 0.01f);
            expect(restoredModel.bandSolo[2] >= 0.5f);
            expect(restoredModel.bandSolo[0] < 0.5f);
            expect(restoredModel.bands[0].size() == 1);
            expect(restoredModel.preFxDevices.size() == 1);
            expect(restoredModel.postFxDevices.size() == 1);
            expect(restoredModel.bands[0][0]->config.typeId ==
                   audioapp::device_types::kCompressor);
            expect(restoredModel.preFxDevices[0]->config.typeId ==
                   audioapp::device_types::kFilter);
            expect(restoredModel.postFxDevices[0]->config.typeId ==
                   audioapp::device_types::kDelay);

            const float mix = std::visit(
                [](const auto& p) -> float {
                    using T = std::decay_t<decltype(p)>;
                    if constexpr (std::is_same_v<T, audioapp::PrePostMixOutputPanel>)
                        return p.outputMix;
                    return -1.0f;
                },
                restored.config.outputPanel);
            expectWithinAbsoluteError(mix, 0.55f, 0.01f);
        }

        beginTest("JSON ingest drops forbidden nested containers");
        {
            const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
            audioapp::DeviceSlot slot =
                registry.createDefault(audioapp::device_types::kSpectralLoudSplit, "sl-bad");
            auto& model = std::get<audioapp::SpectralLoudSplitModel>(slot.config.instance);
            model.bands[1].push_back(std::make_shared<audioapp::DeviceSlot>(
                registry.createDefault(audioapp::device_types::kMbSplit2, "bad-mb")));
            model.preFxDevices.push_back(std::make_shared<audioapp::DeviceSlot>(
                registry.createDefault(audioapp::device_types::kChain, "bad-chain")));

            const std::string json = audioapp::deviceSlotToVar(slot, registry);
            audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(json, registry);
            const auto& restoredModel =
                std::get<audioapp::SpectralLoudSplitModel>(restored.config.instance);
            expect(restoredModel.bands[1].empty(), "forbidden mb nest dropped on ingest");
            expect(restoredModel.preFxDevices.empty(), "forbidden chain nest dropped on ingest");
        }
    }
};

static SpectralLoudSplitEngineTest spectralLoudSplitEngineTest;
