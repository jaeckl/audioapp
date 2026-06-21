#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/EngineHost.hpp"

#include <cmath>

class DeviceRegistryTest : public juce::UnitTest {
public:
    DeviceRegistryTest() : juce::UnitTest("DeviceRegistry", "Devices") {}

    void runTest() override
    {
        const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();

        beginTest("known types count and lookup");
        {
            const auto known = registry.knownTypes();
            expect(known.size() == 14, "should have 14 built-in device types");
            expect(registry.find("unknown_device") == nullptr,
                   "unknown device should return nullptr");
            expect(registry.isKnownType(audioapp::device_types::kOscillator) == true,
                   "oscillator should be known");
        }

        beginTest("create default oscillator");
        {
            audioapp::DeviceSlot oscillator = registry.createDefault(
                audioapp::device_types::kOscillator, "dev-test-1");
            expect(oscillator.id == "dev-test-1", "oscillator id should match");
            expect(std::holds_alternative<audioapp::OscillatorInstance>(oscillator.instance),
                   "oscillator should have OscillatorInstance");
            const auto& oscInst = std::get<audioapp::OscillatorInstance>(oscillator.instance);
            expectWithinAbsoluteError(oscInst.frequencyHz, 440.0f, 0.001f);
        }

        beginTest("create default track gain");
        {
            audioapp::DeviceSlot gain = registry.createDefault(
                audioapp::device_types::kTrackGain, "dev-test-2");
            expectWithinAbsoluteError(gain.gain, 1.0f, 0.001f);
        }

        beginTest("create default subtractive synth");
        {
            audioapp::DeviceSlot synth = registry.createDefault(
                audioapp::device_types::kSubtractiveSynth, "dev-test-3");
            const auto& subInst = std::get<audioapp::SubtractiveSynthInstance>(synth.instance);
            expectWithinAbsoluteError(subInst.filterCutoff, 0.75f, 0.001f);
            expectWithinAbsoluteError(subInst.osc1Shape, 0.5f, 0.001f);
        }

        beginTest("engine integration");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Test");
            expect(!trackId.empty(), "should create track");

            const std::string oscId = host.addDeviceToTrack(trackId, "simple_oscillator");
            expect(!oscId.empty(), "should add oscillator to track");

            expect(host.addDeviceToTrack(trackId, "not_a_real_device").empty(),
                   "unknown device should fail to add");

            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");
            expect(!synthId.empty(), "should add subtractive synth to track");
        }
    }
};

static DeviceRegistryTest deviceRegistryTest;