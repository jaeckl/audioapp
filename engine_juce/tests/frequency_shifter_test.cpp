// FrequencyShifterTest - device type, parameter handling, and serialization for frequency shifter.
#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/FrequencyShifterDeviceType.hpp"
#include "audioapp/devices/instances/FrequencyFxModel.hpp"
#include "audioapp/FrequencyFxProcessor.hpp"
#include "audioapp/ProjectJson.hpp"

#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

class FrequencyShifterTest : public juce::UnitTest {
public:
    FrequencyShifterTest() : juce::UnitTest("FrequencyShifterDevice", "FrequencyFx") {}

    void runTest() override
    {
        const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();

        beginTest("shifter type id");
        {
            audioapp::FrequencyShifterDeviceType type;
            expect(type.typeId() == "frequency_shifter",
                   "typeId should be 'frequency_shifter'");
            expect(registry.isKnownType(audioapp::device_types::kFrequencyShifter),
                   "registry should know 'frequency_shifter' type");
        }

        beginTest("shifter create default");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFrequencyShifter, "shifter-default");
            expect(slot.id == "shifter-default", "slot id should match");
            const auto& inst = std::get<audioapp::FrequencyShifterModel>(slot.config.instance);
            expectWithinAbsoluteError(inst.ffxShift, 0.5f, 0.001f, "default ffxShift=0.5");
            expectWithinAbsoluteError(inst.ffxFine, 0.5f, 0.001f, "default ffxFine=0.5");
            expectWithinAbsoluteError(inst.ffxMix, 1.0f, 0.001f, "default ffxMix=1");
            expectWithinAbsoluteError(inst.ffxTone, 1.0f, 0.001f, "default ffxTone=1");
            expectWithinAbsoluteError(inst.ffxFeedback, 0.0f, 0.001f, "default ffxFeedback=0");
        }

        beginTest("shifter set parameter ffx shift");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFrequencyShifter, "shifter-shift");
            const audioapp::DeviceParameterResult r = registry.setParameter(slot, "ffxShift", 0.7f);
            expect(r.handled, "ffxShift should be handled");
            const auto& inst = std::get<audioapp::FrequencyShifterModel>(slot.config.instance);
            expectWithinAbsoluteError(inst.ffxShift, 0.7f, 0.001f, "ffxShift updated");
        }

        beginTest("shifter set parameter clamps");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFrequencyShifter, "shifter-clamp");
            registry.setParameter(slot, "ffxShift", 1.5f);
            const auto& inst = std::get<audioapp::FrequencyShifterModel>(slot.config.instance);
            expectWithinAbsoluteError(inst.ffxShift, 1.0f, 0.001f, "ffxShift clamped to 1.0");
        }

        beginTest("shifter set parameter unknown unhandled");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFrequencyShifter, "shifter-unknown");
            const audioapp::DeviceParameterResult r = registry.setParameter(
                slot, "unknownShiftParam", 0.42f);
            expect(!r.handled, "unknown param should not be handled");
        }

        beginTest("shifter modulatable params");
        {
            const auto params = registry.modulatableParams(
                audioapp::device_types::kFrequencyShifter);
            const std::vector<std::string> expected = {
                "gain", "pan", "ffxShift", "ffxFine", "ffxMix", "ffxTone", "ffxFeedback"};
            bool allFound = true;
            for (const auto& p : expected) {
                if (std::find(params.begin(), params.end(), p) == params.end()) {
                    allFound = false;
                    break;
                }
            }
            expect(allFound, "modulatableParams should include 'ffxShift' and strip params");
        }

        beginTest("shifter build playback node kind");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFrequencyShifter, "shifter-build");
            audioapp::DeviceNodePlayback out;
            registry.buildPlaybackNode(slot, audioapp::PlaybackBuildContext{}, out);
            expect(out.kind == audioapp::DeviceNodeKind::FrequencyShifter,
                   "out.kind should be DeviceNodeKind::FrequencyShifter");
        }

        beginTest("shifter build playback node center");
        {
            // ffxShift=0.5 → shiftHz = (0.5 - 0.5) * 4000 = 0
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFrequencyShifter, "shifter-center");
            std::get<audioapp::FrequencyShifterModel>(slot.config.instance).ffxShift = 0.5f;
            audioapp::DeviceNodePlayback out;
            registry.buildPlaybackNode(slot, audioapp::PlaybackBuildContext{}, out);
            const auto& params = std::get<audioapp::FrequencyShifterParams>(out.params);
            expectWithinAbsoluteError(params.shiftHz, 0.0f, 0.001f,
                                       "ffxShift=0.5 → shiftHz=0");
        }

        beginTest("shifter build playback node positive");
        {
            // ffxShift=1.0 → shiftHz = (1.0 - 0.5) * 4000 = 2000
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFrequencyShifter, "shifter-pos");
            std::get<audioapp::FrequencyShifterModel>(slot.config.instance).ffxShift = 1.0f;
            audioapp::DeviceNodePlayback out;
            registry.buildPlaybackNode(slot, audioapp::PlaybackBuildContext{}, out);
            const auto& params = std::get<audioapp::FrequencyShifterParams>(out.params);
            expectWithinAbsoluteError(params.shiftHz, 2000.0f, 0.001f,
                                       "ffxShift=1.0 → shiftHz=2000");
        }

        beginTest("shifter build playback node negative");
        {
            // ffxShift=0.0 → shiftHz = (0.0 - 0.5) * 4000 = -2000
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFrequencyShifter, "shifter-neg");
            std::get<audioapp::FrequencyShifterModel>(slot.config.instance).ffxShift = 0.0f;
            audioapp::DeviceNodePlayback out;
            registry.buildPlaybackNode(slot, audioapp::PlaybackBuildContext{}, out);
            const auto& params = std::get<audioapp::FrequencyShifterParams>(out.params);
            expectWithinAbsoluteError(params.shiftHz, -2000.0f, 0.001f,
                                       "ffxShift=0.0 → shiftHz=-2000");
        }

        beginTest("shifter build playback node fine offset");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFrequencyShifter, "shifter-fine");
            auto& inst = std::get<audioapp::FrequencyShifterModel>(slot.config.instance);
            inst.ffxShift = 0.5f;
            inst.ffxFine = 1.0f; // +50 Hz
            audioapp::DeviceNodePlayback out;
            registry.buildPlaybackNode(slot, audioapp::PlaybackBuildContext{}, out);
            const auto& params = std::get<audioapp::FrequencyShifterParams>(out.params);
            expectWithinAbsoluteError(params.shiftHz, 50.0f, 0.001f,
                                       "ffxFine=1 → +50 Hz");
            expectWithinAbsoluteError(params.mix, 1.0f, 0.001f, "default mix");
        }

        beginTest("shifter build live instrument returns false");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFrequencyShifter, "shifter-live");
            audioapp::LiveInstrumentSnapshot snap;
            const bool ok = registry.buildLiveInstrument(
                slot, audioapp::PlaybackBuildContext{}, snap);
            expect(!ok, "frequency shifter is not a live instrument");
        }

        beginTest("shifter slot to var roundtrip");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFrequencyShifter, "shifter-roundtrip");
            std::get<audioapp::FrequencyShifterModel>(slot.config.instance).ffxShift = 0.42f;
            std::get<audioapp::FrequencyShifterModel>(slot.config.instance).ffxFine = 0.2f;
            std::get<audioapp::FrequencyShifterModel>(slot.config.instance).ffxMix = 0.6f;
            std::get<audioapp::FrequencyShifterModel>(slot.config.instance).ffxTone = 0.7f;
            std::get<audioapp::FrequencyShifterModel>(slot.config.instance).ffxFeedback = 0.3f;
            std::get<audioapp::StereoOutputPanel>(slot.config.outputPanel).gain = 0.5f;
            std::get<audioapp::StereoOutputPanel>(slot.config.outputPanel).pan = 0.3f;
            slot.config.bypassed = true;

            const std::string json = audioapp::deviceSlotToVar(slot, registry);
            audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(json, registry);
            expect(restored.id == slot.id, "id roundtrip");
            expectWithinAbsoluteError(std::get<audioapp::StereoOutputPanel>(restored.config.outputPanel).gain,
                                  std::get<audioapp::StereoOutputPanel>(slot.config.outputPanel).gain, 0.001f, "gain roundtrip");
            expectWithinAbsoluteError(std::get<audioapp::StereoOutputPanel>(restored.config.outputPanel).pan,
                                  std::get<audioapp::StereoOutputPanel>(slot.config.outputPanel).pan, 0.001f, "pan roundtrip");
            expect(restored.config.bypassed == slot.config.bypassed, "bypass roundtrip");
            const auto& inst = std::get<audioapp::FrequencyShifterModel>(restored.config.instance);
            expectWithinAbsoluteError(inst.ffxShift, 0.42f, 0.001f, "ffxShift roundtrip");
            expectWithinAbsoluteError(inst.ffxFine, 0.2f, 0.001f, "ffxFine roundtrip");
            expectWithinAbsoluteError(inst.ffxMix, 0.6f, 0.001f, "ffxMix roundtrip");
            expectWithinAbsoluteError(inst.ffxTone, 0.7f, 0.001f, "ffxTone roundtrip");
            expectWithinAbsoluteError(inst.ffxFeedback, 0.3f, 0.001f, "ffxFeedback roundtrip");
        }

        beginTest("shifter slot to var json shape");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFrequencyShifter, "shifter-shape");
            const std::string json = audioapp::deviceSlotToVar(slot, registry);
            const auto parsed = juce::JSON::parse(juce::String(json));
            expect(!parsed.isVoid(), "JSON parse should succeed");
            const auto* root = parsed.getDynamicObject();
            expect(root != nullptr, "root should be a DynamicObject");
            if (root != nullptr) {
                expect(root->hasProperty("id"), "should have 'id' property");
                expect(root->hasProperty("type"), "should have 'type' property");
                expect(root->getProperty("type").toString() == "frequency_shifter",
                       "type should be 'frequency_shifter'");
                expect(root->hasProperty("parameters"), "should have 'parameters' property");
                expect(root->hasProperty("meters"), "should have 'meters' property");
                const auto params = root->getProperty("parameters");
                const auto* p = params.getDynamicObject();
                expect(p != nullptr, "parameters should be a DynamicObject");
                if (p != nullptr) {
                    expect(p->hasProperty("ffxShift"), "parameters should have 'ffxShift'");
                }
                // gain/pan/bypass are now in outputPanel and root level
                expect(root->hasProperty("outputPanel"), "should have 'outputPanel' property");
            }
        }

        beginTest("shifter var to slot defaults");
        {
            // Minimal JSON — missing keys should use defaults (ffxShift=0.5).
            const std::string json =
                R"({"id":"shifter-min","type":"frequency_shifter","parameters":{}})";
            audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(json, registry);
            expect(restored.id == "shifter-min", "id preserved");
            const auto& inst = std::get<audioapp::FrequencyShifterModel>(restored.config.instance);
            expectWithinAbsoluteError(inst.ffxShift, 0.5f, 0.001f, "default ffxShift=0.5");
        }
    }
};

static FrequencyShifterTest frequencyShifterTest;