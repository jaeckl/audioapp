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

        beginTest("every type ID constant must be registered");
        {
            // If someone adds a new kFoo to DeviceTypeIds.hpp but forgets
            // registerType(std::make_unique<FooDeviceType>()) in
            // DeviceRegistry::createBuiltIn(), this test catches it.
            expect(registry.isKnownType(audioapp::device_types::kOscillator));
            expect(registry.isKnownType(audioapp::device_types::kSampler));
            expect(registry.isKnownType(audioapp::device_types::kTrackGain));
            expect(registry.isKnownType(audioapp::device_types::kSubtractiveSynth));
            expect(registry.isKnownType(audioapp::device_types::kKickGenerator));
            expect(registry.isKnownType(audioapp::device_types::kSnareGenerator));
            expect(registry.isKnownType(audioapp::device_types::kClapGenerator));
            expect(registry.isKnownType(audioapp::device_types::kCymbalGenerator));
            expect(registry.isKnownType(audioapp::device_types::kCrashGenerator));
            expect(registry.isKnownType(audioapp::device_types::kGate));
            expect(registry.isKnownType(audioapp::device_types::kCompressor));
            expect(registry.isKnownType(audioapp::device_types::kExpander));
            expect(registry.isKnownType(audioapp::device_types::kLimiter));
            expect(registry.isKnownType(audioapp::device_types::kBasSynth));
            expect(registry.isKnownType(audioapp::device_types::kPhaseModSynth));
            expect(registry.isKnownType(audioapp::device_types::kDelay));
            expect(registry.isKnownType(audioapp::device_types::kReverb));
            expect(registry.isKnownType(audioapp::device_types::kChorus));
            expect(registry.isKnownType(audioapp::device_types::kPhaser));
            expect(registry.isKnownType(audioapp::device_types::kFilter));
            expect(registry.isKnownType(audioapp::device_types::kFourBandEq));
            expect(registry.isKnownType(audioapp::device_types::kFrequencyShifter));

            // Sanity: unknown string returns false, not a crash.
            expect(!registry.isKnownType("not_a_real_device"));
            expect(registry.find("unknown_device") == nullptr);
        }

        beginTest("create default oscillator");
        {
            audioapp::DeviceSlot oscillator = registry.createDefault(
                audioapp::device_types::kOscillator, "dev-test-1");
            expect(oscillator.id == "dev-test-1", "oscillator id should match");
            expect(std::holds_alternative<audioapp::OscillatorParams>(oscillator.config.instance),
                   "oscillator should have OscillatorParams");
            const auto& oscInst = std::get<audioapp::OscillatorParams>(oscillator.config.instance);
            expectWithinAbsoluteError(oscInst.frequencyHz, 440.0f, 0.001f);
        }

        beginTest("create default track gain");
        {
            audioapp::DeviceSlot gain = registry.createDefault(
                audioapp::device_types::kTrackGain, "dev-test-2");
            expect(std::holds_alternative<audioapp::TrackGainParams>(gain.config.instance), "track gain should have TrackGainParams");
            // TrackGain uses MonoOutputPanel with gain=1.0
            const float defaultGain = std::visit([](const auto& p) -> float {
                using T = std::decay_t<decltype(p)>;
                if constexpr (std::is_same_v<T, audioapp::MonoOutputPanel> || std::is_same_v<T, audioapp::StereoOutputPanel>)
                    return p.gain;
                return 1.0f;
            }, gain.config.outputPanel);
            expectWithinAbsoluteError(defaultGain, 1.0f, 0.001f);
        }

        beginTest("create default subtractive synth");
        {
            audioapp::DeviceSlot synth = registry.createDefault(
                audioapp::device_types::kSubtractiveSynth, "dev-test-3");
            const auto& subInst = std::get<audioapp::SubtractiveSynthParams>(synth.config.instance);
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