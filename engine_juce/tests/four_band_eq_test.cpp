// FourBandEqTest - device type, parameter handling, and serialization for 4-band EQ.
#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/FourBandEqDeviceType.hpp"
#include "audioapp/devices/instances/FrequencyFxModel.hpp"
#include "audioapp/FrequencyFxProcessor.hpp"
#include "audioapp/ProjectJson.hpp"

#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

class FourBandEqTest : public juce::UnitTest {
public:
    FourBandEqTest() : juce::UnitTest("FourBandEqDevice", "FrequencyFx") {}

    void runTest() override
    {
        const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();

        beginTest("eq type id");
        {
            audioapp::FourBandEqDeviceType type;
            expect(type.typeId() == "four_band_eq", "typeId should be 'four_band_eq'");
            expect(registry.isKnownType(audioapp::device_types::kFourBandEq),
                   "registry should know 'four_band_eq' type");
        }

        beginTest("eq create default");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFourBandEq, "eq-default");
            expect(slot.id == "eq-default", "slot id should match");
            const auto& inst = std::get<audioapp::FourBandEqModel>(slot.config.instance);
            expectWithinAbsoluteError(inst.ffxBand1Freq, 0.15f, 0.001f, "default ffxBand1Freq");
            expectWithinAbsoluteError(inst.ffxBand1Gain, 0.5f, 0.001f, "default ffxBand1Gain");
            expectWithinAbsoluteError(inst.ffxBand1Q, 0.5f, 0.001f, "default ffxBand1Q");
            expectWithinAbsoluteError(inst.ffxBand2Freq, 0.35f, 0.001f, "default ffxBand2Freq");
            expectWithinAbsoluteError(inst.ffxBand2Gain, 0.5f, 0.001f, "default ffxBand2Gain");
            expectWithinAbsoluteError(inst.ffxBand2Q, 0.5f, 0.001f, "default ffxBand2Q");
            expectWithinAbsoluteError(inst.ffxBand3Freq, 0.6f, 0.001f, "default ffxBand3Freq");
            expectWithinAbsoluteError(inst.ffxBand3Gain, 0.5f, 0.001f, "default ffxBand3Gain");
            expectWithinAbsoluteError(inst.ffxBand3Q, 0.5f, 0.001f, "default ffxBand3Q");
            expectWithinAbsoluteError(inst.ffxBand4Freq, 0.85f, 0.001f, "default ffxBand4Freq");
            expectWithinAbsoluteError(inst.ffxBand4Gain, 0.5f, 0.001f, "default ffxBand4Gain");
            expectWithinAbsoluteError(inst.ffxBand4Q, 0.5f, 0.001f, "default ffxBand4Q");
        }

        beginTest("eq set parameter ffx band1 freq");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFourBandEq, "eq-b1f");
            const audioapp::DeviceParameterResult r = registry.setParameter(slot, "ffxBand1Freq", 0.3f);
            expect(r.handled, "ffxBand1Freq should be handled");
            const auto& inst = std::get<audioapp::FourBandEqModel>(slot.config.instance);
            expectWithinAbsoluteError(inst.ffxBand1Freq, 0.3f, 0.001f, "ffxBand1Freq updated");
        }

        beginTest("eq set parameter ffx band4 gain");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFourBandEq, "eq-b4g");
            const audioapp::DeviceParameterResult r = registry.setParameter(slot, "ffxBand4Gain", 0.7f);
            expect(r.handled, "ffxBand4Gain should be handled");
            const auto& inst = std::get<audioapp::FourBandEqModel>(slot.config.instance);
            expectWithinAbsoluteError(inst.ffxBand4Gain, 0.7f, 0.001f, "ffxBand4Gain updated");
        }

        beginTest("eq set parameter clamps");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFourBandEq, "eq-clamp");
            registry.setParameter(slot, "ffxBand2Freq", 1.5f);
            const auto& inst = std::get<audioapp::FourBandEqModel>(slot.config.instance);
            expectWithinAbsoluteError(inst.ffxBand2Freq, 1.0f, 0.001f,
                                       "ffxBand2Freq clamped to 1.0");
        }

        beginTest("eq set parameter unknown unhandled");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFourBandEq, "eq-unknown");
            const audioapp::DeviceParameterResult r = registry.setParameter(
                slot, "unknownEqParam", 0.42f);
            expect(!r.handled, "unknown param should not be handled");
        }

        beginTest("eq modulatable params");
        {
            const auto params = registry.modulatableParams(audioapp::device_types::kFourBandEq);
            const std::vector<std::string> expected = {
                "gain", "pan",
                "ffxBand1Freq", "ffxBand1Gain", "ffxBand1Q",
                "ffxBand2Freq", "ffxBand2Gain", "ffxBand2Q",
                "ffxBand3Freq", "ffxBand3Gain", "ffxBand3Q",
                "ffxBand4Freq", "ffxBand4Gain", "ffxBand4Q"};
            bool allFound = true;
            for (const auto& p : expected) {
                if (std::find(params.begin(), params.end(), p) == params.end()) {
                    allFound = false;
                    break;
                }
            }
            expect(allFound, "modulatableParams should include all 12 band params + gain + pan");
        }

        beginTest("eq build playback node kind");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFourBandEq, "eq-build");
            audioapp::DeviceNodePlayback out;
            registry.buildPlaybackNode(slot, audioapp::PlaybackBuildContext{}, out);
            expect(out.kind == audioapp::DeviceNodeKind::FourBandEq,
                   "out.kind should be DeviceNodeKind::FourBandEq");
        }

        beginTest("eq build playback node params");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFourBandEq, "eq-build-params");
            // ffxBand1Freq=0.15 → normalizedToFrequency(0.15) = 20 * 1000^0.15 ≈ 70.79 Hz
            std::get<audioapp::FourBandEqModel>(slot.config.instance).ffxBand1Freq = 0.15f;
            audioapp::DeviceNodePlayback out;
            registry.buildPlaybackNode(slot, audioapp::PlaybackBuildContext{}, out);
            const auto& params = std::get<audioapp::FourBandEqParams>(out.params);
            const float expected = audioapp::normalizedToFrequency(0.15f);
            expectWithinAbsoluteError(params.bands[0].frequencyHz, expected, 0.001f,
                                       "band1 frequencyHz should match normalizedToFrequency(0.15)");
        }

        beginTest("eq build live instrument returns false");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFourBandEq, "eq-live");
            audioapp::LiveInstrumentSnapshot snap;
            const bool ok = registry.buildLiveInstrument(
                slot, audioapp::PlaybackBuildContext{}, snap);
            expect(!ok, "4-band EQ is not a live instrument");
        }

        beginTest("eq slot to var roundtrip");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFourBandEq, "eq-roundtrip");
            auto& inst = std::get<audioapp::FourBandEqModel>(slot.config.instance);
            inst.ffxBand1Freq = 0.1f;
            inst.ffxBand1Gain = 0.2f;
            inst.ffxBand1Q = 0.3f;
            inst.ffxBand2Freq = 0.4f;
            inst.ffxBand2Gain = 0.5f;
            inst.ffxBand2Q = 0.6f;
            inst.ffxBand3Freq = 0.7f;
            inst.ffxBand3Gain = 0.8f;
            inst.ffxBand3Q = 0.9f;
            inst.ffxBand4Freq = 0.95f;
            inst.ffxBand4Gain = 0.05f;
            inst.ffxBand4Q = 0.15f;
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
            const auto& ri = std::get<audioapp::FourBandEqModel>(restored.config.instance);
            expectWithinAbsoluteError(ri.ffxBand1Freq, 0.1f, 0.001f, "b1Freq roundtrip");
            expectWithinAbsoluteError(ri.ffxBand1Gain, 0.2f, 0.001f, "b1Gain roundtrip");
            expectWithinAbsoluteError(ri.ffxBand1Q, 0.3f, 0.001f, "b1Q roundtrip");
            expectWithinAbsoluteError(ri.ffxBand2Freq, 0.4f, 0.001f, "b2Freq roundtrip");
            expectWithinAbsoluteError(ri.ffxBand2Gain, 0.5f, 0.001f, "b2Gain roundtrip");
            expectWithinAbsoluteError(ri.ffxBand2Q, 0.6f, 0.001f, "b2Q roundtrip");
            expectWithinAbsoluteError(ri.ffxBand3Freq, 0.7f, 0.001f, "b3Freq roundtrip");
            expectWithinAbsoluteError(ri.ffxBand3Gain, 0.8f, 0.001f, "b3Gain roundtrip");
            expectWithinAbsoluteError(ri.ffxBand3Q, 0.9f, 0.001f, "b3Q roundtrip");
            expectWithinAbsoluteError(ri.ffxBand4Freq, 0.95f, 0.001f, "b4Freq roundtrip");
            expectWithinAbsoluteError(ri.ffxBand4Gain, 0.05f, 0.001f, "b4Gain roundtrip");
            expectWithinAbsoluteError(ri.ffxBand4Q, 0.15f, 0.001f, "b4Q roundtrip");
        }

        beginTest("eq slot to var json shape");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFourBandEq, "eq-shape");
            const std::string json = audioapp::deviceSlotToVar(slot, registry);
            const auto parsed = juce::JSON::parse(juce::String(json));
            expect(!parsed.isVoid(), "JSON parse should succeed");
            const auto* root = parsed.getDynamicObject();
            expect(root != nullptr, "root should be a DynamicObject");
            if (root != nullptr) {
                expect(root->getProperty("type").toString() == "four_band_eq",
                       "type should be 'four_band_eq'");
                const auto params = root->getProperty("parameters");
                const auto* p = params.getDynamicObject();
                expect(p != nullptr, "parameters should be a DynamicObject");
                if (p != nullptr) {
                    const std::vector<std::string> bandKeys = {
                        "ffxBand1Freq", "ffxBand1Gain", "ffxBand1Q",
                        "ffxBand2Freq", "ffxBand2Gain", "ffxBand2Q",
                        "ffxBand3Freq", "ffxBand3Gain", "ffxBand3Q",
                        "ffxBand4Freq", "ffxBand4Gain", "ffxBand4Q"};
                    bool allFound = true;
                    for (const auto& k : bandKeys) {
                        if (!p->hasProperty(juce::Identifier(k))) {
                            allFound = false;
                            break;
                        }
                    }
                    expect(allFound, "parameters should contain all 12 band params");
                }
            }
        }

        beginTest("eq var to slot defaults");
        {
            // Minimal JSON — missing keys should use defaults.
            const std::string json =
                R"({"id":"eq-min","type":"four_band_eq","parameters":{}})";
            audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(json, registry);
            expect(restored.id == "eq-min", "id preserved");
            const auto& inst = std::get<audioapp::FourBandEqModel>(restored.config.instance);
            expectWithinAbsoluteError(inst.ffxBand1Freq, 0.15f, 0.001f, "default ffxBand1Freq");
            expectWithinAbsoluteError(inst.ffxBand1Gain, 0.5f, 0.001f, "default ffxBand1Gain");
            expectWithinAbsoluteError(inst.ffxBand1Q, 0.5f, 0.001f, "default ffxBand1Q");
            expectWithinAbsoluteError(inst.ffxBand2Freq, 0.35f, 0.001f, "default ffxBand2Freq");
            expectWithinAbsoluteError(inst.ffxBand2Gain, 0.5f, 0.001f, "default ffxBand2Gain");
            expectWithinAbsoluteError(inst.ffxBand2Q, 0.5f, 0.001f, "default ffxBand2Q");
            expectWithinAbsoluteError(inst.ffxBand3Freq, 0.6f, 0.001f, "default ffxBand3Freq");
            expectWithinAbsoluteError(inst.ffxBand3Gain, 0.5f, 0.001f, "default ffxBand3Gain");
            expectWithinAbsoluteError(inst.ffxBand3Q, 0.5f, 0.001f, "default ffxBand3Q");
            expectWithinAbsoluteError(inst.ffxBand4Freq, 0.85f, 0.001f, "default ffxBand4Freq");
            expectWithinAbsoluteError(inst.ffxBand4Gain, 0.5f, 0.001f, "default ffxBand4Gain");
            expectWithinAbsoluteError(inst.ffxBand4Q, 0.5f, 0.001f, "default ffxBand4Q");
        }
    }
};

static FourBandEqTest fourBandEqTest;