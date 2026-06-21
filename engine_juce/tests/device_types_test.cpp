#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/devices/instances/OscillatorInstance.hpp"
#include "audioapp/devices/instances/SubtractiveSynthInstance.hpp"

#include <cmath>

namespace {
bool expectFalse(bool value) { return !value; }
} // namespace

class DeviceTypesTest : public juce::UnitTest {
public:
    DeviceTypesTest() : juce::UnitTest("DeviceTypes", "Devices") {}

    void runTest() override
    {
        const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
        const audioapp::PlaybackBuildContext context{};

        beginTest("parameter set and round-trip");
        {
            audioapp::DeviceSlot oscillator =
                registry.createDefault(audioapp::device_types::kOscillator, "dev-osc");
            auto oscResult = registry.setParameter(oscillator, "frequency", 880.0f);
            expect(oscResult.handled, "oscillator frequency set should be handled");
            expect(oscResult.syncActiveFrequency, "oscillator frequency should sync active");
            expectWithinAbsoluteError(
                std::get<audioapp::OscillatorInstance>(oscillator.instance).frequencyHz,
                880.0f, 0.001f);

            expect(expectFalse(registry.setParameter(oscillator, "filterCutoff", 0.5f).handled),
                   "oscillator should not handle filterCutoff");
        }

        beginTest("sampler parameter");
        {
            audioapp::DeviceSlot sampler =
                registry.createDefault(audioapp::device_types::kSampler, "dev-sampler");
            expect(registry.setParameter(sampler, "attack", 1.5f).handled,
                   "sampler attack set should be handled");
            const auto& samplerInst = std::get<audioapp::SamplerInstance>(sampler.instance);
            expectWithinAbsoluteError(samplerInst.attack, 1.0f, 0.001f);
        }

        beginTest("subtractive synth parameters");
        {
            audioapp::DeviceSlot synth =
                registry.createDefault(audioapp::device_types::kSubtractiveSynth, "dev-synth");
            const auto& synthInst = std::get<audioapp::SubtractiveSynthInstance>(synth.instance);
            expectWithinAbsoluteError(synthInst.filterCutoff, 0.75f, 0.001f);

            expect(registry.setParameter(synth, "osc1Shape", 0.75f).handled,
                   "synth osc1Shape set should be handled");
            expectWithinAbsoluteError(
                std::get<audioapp::SubtractiveSynthInstance>(synth.instance).osc1Shape,
                0.75f, 0.001f);
        }

        beginTest("build playback nodes");
        {
            audioapp::DeviceSlot oscillator =
                registry.createDefault(audioapp::device_types::kOscillator, "dev-osc");
            registry.setParameter(oscillator, "frequency", 880.0f);

            audioapp::DeviceNodePlayback oscNode{};
            registry.buildPlaybackNode(oscillator, context, oscNode);
            expect(oscNode.kind == audioapp::DeviceNodeKind::Oscillator,
                   "oscillator node kind should be Oscillator");
            expectWithinAbsoluteError(
                std::get<audioapp::OscillatorParams>(oscNode.params).frequencyHz,
                880.0f, 0.001f);

            audioapp::DeviceNodePlayback gainNode{};
            audioapp::DeviceSlot gain =
                registry.createDefault(audioapp::device_types::kTrackGain, "dev-gain");
            registry.buildPlaybackNode(gain, context, gainNode);
            expect(gainNode.kind == audioapp::DeviceNodeKind::TrackGain,
                   "gain node kind should be TrackGain");
            expect(expectFalse(registry.setParameter(gain, "pan", 0.0f).handled),
                   "track gain should not handle pan");

            audioapp::DeviceNodePlayback synthNode{};
            audioapp::DeviceSlot synth =
                registry.createDefault(audioapp::device_types::kSubtractiveSynth, "dev-synth");
            registry.buildPlaybackNode(synth, context, synthNode);
            expect(synthNode.kind == audioapp::DeviceNodeKind::SubtractiveSynth,
                   "synth node kind should be SubtractiveSynth");
            const auto& synthParams =
                std::get<audioapp::SubtractiveSynthParams>(synthNode.params);
            expectWithinAbsoluteError(synthParams.osc1Shape, 0.75f, 0.001f);
        }

        beginTest("build live instrument");
        {
            audioapp::DeviceSlot oscillator =
                registry.createDefault(audioapp::device_types::kOscillator, "dev-osc");

            audioapp::LiveInstrumentSnapshot live{};
            expect(registry.buildLiveInstrument(oscillator, context, live),
                   "oscillator should build live instrument");
            expect(live.kind == audioapp::LiveInstrumentKind::Oscillator,
                   "live instrument kind should be Oscillator");

            audioapp::DeviceSlot gain =
                registry.createDefault(audioapp::device_types::kTrackGain, "dev-gain");
            expect(expectFalse(registry.buildLiveInstrument(gain, context, live)),
                   "track gain should not build live instrument");
        }

        beginTest("modulatable params");
        {
            const auto modParams =
                registry.modulatableParams(audioapp::device_types::kOscillator);
            expect(!modParams.empty(), "oscillator should have modulatable params");
        }

        beginTest("slot var round-trip");
        {
            audioapp::DeviceSlot oscillator =
                registry.createDefault(audioapp::device_types::kOscillator, "dev-osc");
            registry.setParameter(oscillator, "frequency", 880.0f);

            const auto roundTripJson = audioapp::deviceSlotToVar(oscillator, registry);
            const audioapp::DeviceSlot roundTripSlot =
                audioapp::deviceVarToSlot(roundTripJson, registry);
            expect(roundTripSlot.id == oscillator.id,
                   "round-trip id should match");
            expectWithinAbsoluteError(
                std::get<audioapp::OscillatorInstance>(roundTripSlot.instance).frequencyHz,
                880.0f, 0.001f);
        }
    }
};

static DeviceTypesTest deviceTypesTest;