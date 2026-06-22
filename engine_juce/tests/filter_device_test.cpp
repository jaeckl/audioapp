// FilterDeviceTest - device type, parameter handling, and serialization for filter.
#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/FilterDeviceType.hpp"
#include "audioapp/devices/instances/FrequencyFxModel.hpp"
#include "audioapp/FrequencyFxProcessor.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cmath>
#include <string>

class FilterDeviceTest : public juce::UnitTest {
public:
    FilterDeviceTest() : juce::UnitTest("FilterDevice", "FrequencyFx") {}

    void runTest() override
    {
        const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();

        beginTest("filter type id");
        {
            audioapp::FilterDeviceType type;
            expect(type.typeId() == "filter", "typeId should be 'filter'");
            expect(registry.isKnownType(audioapp::device_types::kFilter),
                   "registry should know 'filter' type");
        }

        beginTest("filter create default");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFilter, "filter-default");
            expect(slot.id == "filter-default", "slot id should match");
            const auto& inst = std::get<audioapp::FilterModel>(slot.instance);
            expectWithinAbsoluteError(inst.ffxCutoff, 0.6f, 0.001f, "default ffxCutoff");
            expectWithinAbsoluteError(inst.ffxResonance, 0.3f, 0.001f, "default ffxResonance");
            expectWithinAbsoluteError(inst.ffxFilterMode, 0.0f, 0.001f, "default ffxFilterMode");
        }

        beginTest("filter set parameter ffx cutoff");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFilter, "f-cut");
            const audioapp::DeviceParameterResult r = registry.setParameter(slot, "ffxCutoff", 0.5f);
            expect(r.handled, "ffxCutoff should be handled");
            const auto& inst = std::get<audioapp::FilterModel>(slot.instance);
            expectWithinAbsoluteError(inst.ffxCutoff, 0.5f, 0.001f, "ffxCutoff updated");
        }

        beginTest("filter set parameter ffx cutoff clamps");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFilter, "f-cut-clamp");
            registry.setParameter(slot, "ffxCutoff", 1.5f);
            const auto& inst = std::get<audioapp::FilterModel>(slot.instance);
            expectWithinAbsoluteError(inst.ffxCutoff, 1.0f, 0.001f, "ffxCutoff clamped to 1.0");
        }

        beginTest("filter set parameter ffx resonance");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFilter, "f-res");
            registry.setParameter(slot, "ffxResonance", 0.7f);
            const auto& inst = std::get<audioapp::FilterModel>(slot.instance);
            expectWithinAbsoluteError(inst.ffxResonance, 0.7f, 0.001f, "ffxResonance updated");
        }

        beginTest("filter set parameter ffx filter mode");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFilter, "f-mode");
            registry.setParameter(slot, "ffxFilterMode", 0.5f);
            const auto& inst = std::get<audioapp::FilterModel>(slot.instance);
            expectWithinAbsoluteError(inst.ffxFilterMode, 0.5f, 0.001f, "ffxFilterMode updated");
        }

        beginTest("filter set parameter unknown returns unhandled");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFilter, "f-unknown");
            const audioapp::DeviceParameterResult r = registry.setParameter(
                slot, "totallyUnknownParam", 0.42f);
            expect(!r.handled, "unknown param should not be handled");
        }

        beginTest("filter set parameter gain delegates");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFilter, "f-gain");
            const float origGain = slot.gain;
            const audioapp::DeviceParameterResult r = registry.setParameter(slot, "gain", 0.25f);
            expect(r.handled, "gain should be handled by strip params");
            expect(std::fabs(slot.gain - 0.25f) > 1.0e-6f || origGain != 0.25f,
                   "slot.gain should reflect new value (was either changed or wasn't 0.25 before)");
            expectWithinAbsoluteError(slot.gain, 0.25f, 0.001f, "slot.gain updated to 0.25");
        }

        beginTest("filter modulatable params");
        {
            const auto params = registry.modulatableParams(audioapp::device_types::kFilter);
            const std::vector<std::string> expected = {
                "gain", "pan", "ffxCutoff", "ffxResonance", "ffxFilterMode"};
            bool allFound = true;
            for (const auto& p : expected) {
                if (std::find(params.begin(), params.end(), p) == params.end()) {
                    allFound = false;
                    break;
                }
            }
            expect(allFound, "modulatableParams should include all expected names");
        }

        beginTest("filter build playback node kind");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFilter, "f-build");
            audioapp::DeviceNodePlayback out;
            registry.buildPlaybackNode(slot, audioapp::PlaybackBuildContext{}, out);
            expect(out.kind == audioapp::DeviceNodeKind::Filter,
                   "out.kind should be DeviceNodeKind::Filter");
        }

        beginTest("filter build playback node params");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFilter, "f-build-params");
            // ffxCutoff=0.6 → normalizedToFrequency(0.6) = 20 * 1000^0.6 ≈ 6309.57 Hz
            std::get<audioapp::FilterModel>(slot.instance).ffxCutoff = 0.6f;
            audioapp::DeviceNodePlayback out;
            registry.buildPlaybackNode(slot, audioapp::PlaybackBuildContext{}, out);
            const auto& params = std::get<audioapp::FilterParams>(out.params);
            const float expected = audioapp::normalizedToFrequency(0.6f);
            expectWithinAbsoluteError(params.cutoffHz, expected, 0.001f,
                                       "filter cutoffHz should match normalizedToFrequency(0.6)");
        }

        beginTest("filter build live instrument returns false");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFilter, "f-live");
            audioapp::LiveInstrumentSnapshot snap;
            const bool ok = registry.buildLiveInstrument(
                slot, audioapp::PlaybackBuildContext{}, snap);
            expect(!ok, "filter is not a live instrument");
        }

        beginTest("filter slot to var roundtrip");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFilter, "f-roundtrip");
            std::get<audioapp::FilterModel>(slot.instance).ffxCutoff = 0.42f;
            std::get<audioapp::FilterModel>(slot.instance).ffxResonance = 0.77f;
            std::get<audioapp::FilterModel>(slot.instance).ffxFilterMode = 0.5f;
            slot.gain = 0.5f;
            slot.pan = 0.3f;
            slot.bypassed = true;

            const std::string json = audioapp::deviceSlotToVar(slot, registry);
            audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(json, registry);
            expect(restored.id == slot.id, "id roundtrip");
            expectWithinAbsoluteError(restored.gain, slot.gain, 0.001f, "gain roundtrip");
            expectWithinAbsoluteError(restored.pan, slot.pan, 0.001f, "pan roundtrip");
            expect(restored.bypassed == slot.bypassed, "bypass roundtrip");
            const auto& inst = std::get<audioapp::FilterModel>(restored.instance);
            expectWithinAbsoluteError(inst.ffxCutoff, 0.42f, 0.001f, "ffxCutoff roundtrip");
            expectWithinAbsoluteError(inst.ffxResonance, 0.77f, 0.001f, "ffxResonance roundtrip");
            expectWithinAbsoluteError(inst.ffxFilterMode, 0.5f, 0.001f, "ffxFilterMode roundtrip");
        }

        beginTest("filter slot to var json shape");
        {
            audioapp::DeviceSlot slot = registry.createDefault(
                audioapp::device_types::kFilter, "f-shape");
            const std::string json = audioapp::deviceSlotToVar(slot, registry);
            const auto parsed = juce::JSON::parse(juce::String(json));
            expect(!parsed.isVoid(), "JSON parse should succeed");
            const auto* root = parsed.getDynamicObject();
            expect(root != nullptr, "root should be a DynamicObject");
            if (root != nullptr) {
                expect(root->hasProperty("id"), "should have 'id' property");
                expect(root->hasProperty("type"), "should have 'type' property");
                expect(root->getProperty("type").toString() == "filter",
                       "type should be 'filter'");
                expect(root->hasProperty("parameters"), "should have 'parameters' property");
                expect(root->hasProperty("meters"), "should have 'meters' property");
                const auto params = root->getProperty("parameters");
                const auto* p = params.getDynamicObject();
                expect(p != nullptr, "parameters should be a DynamicObject");
                if (p != nullptr) {
                    expect(p->hasProperty("gain"), "parameters should have 'gain'");
                    expect(p->hasProperty("pan"), "parameters should have 'pan'");
                    expect(p->hasProperty("bypass"), "parameters should have 'bypass'");
                    expect(p->hasProperty("ffxCutoff"), "parameters should have 'ffxCutoff'");
                    expect(p->hasProperty("ffxResonance"), "parameters should have 'ffxResonance'");
                    expect(p->hasProperty("ffxFilterMode"), "parameters should have 'ffxFilterMode'");
                }
            }
        }

        beginTest("filter var to slot defaults");
        {
            // Minimal JSON with only id and type — everything else should use defaults.
            const std::string json =
                R"({"id":"f-min","type":"filter","parameters":{}})";
            audioapp::DeviceSlot restored = audioapp::deviceVarToSlot(json, registry);
            expect(restored.id == "f-min", "id preserved");
            const auto& inst = std::get<audioapp::FilterModel>(restored.instance);
            expectWithinAbsoluteError(inst.ffxCutoff, 0.6f, 0.001f, "default ffxCutoff");
            expectWithinAbsoluteError(inst.ffxResonance, 0.3f, 0.001f, "default ffxResonance");
            expectWithinAbsoluteError(inst.ffxFilterMode, 0.0f, 0.001f, "default ffxFilterMode");
        }
    }
};

static FilterDeviceTest filterDeviceTest;