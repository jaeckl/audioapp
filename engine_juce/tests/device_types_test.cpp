#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/devices/instances/OscillatorInstance.hpp"
#include "audioapp/devices/instances/SubtractiveSynthInstance.hpp"

#include <cmath>
#include <cstdlib>

namespace {

bool expectFalse(bool value) {
    return !value;
}

} // namespace

int main() {
    const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();
    const audioapp::PlaybackBuildContext context{};

    audioapp::DeviceSlot oscillator =
        registry.createDefault(audioapp::device_types::kOscillator, "dev-osc");
    auto oscResult = registry.setParameter(oscillator, "frequency", 880.0f);
    if (!oscResult.handled || !oscResult.syncActiveFrequency) {
        return EXIT_FAILURE;
    }
    if (std::abs(std::get<audioapp::OscillatorInstance>(oscillator.instance).frequencyHz - 880.0f) >
        0.001f) {
        return EXIT_FAILURE;
    }
    if (!expectFalse(registry.setParameter(oscillator, "filterCutoff", 0.5f).handled)) {
        return EXIT_FAILURE;
    }

    audioapp::DeviceSlot sampler =
        registry.createDefault(audioapp::device_types::kSampler, "dev-sampler");
    if (!registry.setParameter(sampler, "attack", 1.5f).handled) {
        return EXIT_FAILURE;
    }
    const audioapp::DeviceState samplerState = registry.toSnapshotState(sampler);
    if (std::abs(samplerState.attack - 1.0f) > 0.001f) {
        return EXIT_FAILURE;
    }

    audioapp::DeviceSlot synth =
        registry.createDefault(audioapp::device_types::kSubtractiveSynth, "dev-synth");
    const audioapp::DeviceState synthDefaults = registry.toSnapshotState(synth);
    if (std::abs(synthDefaults.filterCutoff - 0.75f) > 0.001f) {
        return EXIT_FAILURE;
    }
    if (!registry.setParameter(synth, "osc1Wave", 3.0f).handled) {
        return EXIT_FAILURE;
    }
    if (std::get<audioapp::SubtractiveSynthInstance>(synth.instance).osc1Wave != 3) {
        return EXIT_FAILURE;
    }

    audioapp::DeviceNodePlayback oscNode{};
    registry.buildPlaybackNode(oscillator, context, oscNode);
    if (oscNode.kind != audioapp::DeviceNodeKind::Oscillator) {
        return EXIT_FAILURE;
    }
    if (std::abs(std::get<audioapp::OscillatorParams>(oscNode.params).frequencyHz - 880.0f) > 0.001f) {
        return EXIT_FAILURE;
    }

    audioapp::DeviceNodePlayback gainNode{};
    audioapp::DeviceSlot gain =
        registry.createDefault(audioapp::device_types::kTrackGain, "dev-gain");
    registry.buildPlaybackNode(gain, context, gainNode);
    if (gainNode.kind != audioapp::DeviceNodeKind::TrackGain) {
        return EXIT_FAILURE;
    }
    if (!expectFalse(registry.setParameter(gain, "pan", 0.0f).handled)) {
        return EXIT_FAILURE;
    }

    audioapp::DeviceNodePlayback synthNode{};
    registry.buildPlaybackNode(synth, context, synthNode);
    if (synthNode.kind != audioapp::DeviceNodeKind::SubtractiveSynth) {
        return EXIT_FAILURE;
    }
    const auto& synthParams = std::get<audioapp::SubtractiveSynthParams>(synthNode.params);
    if (synthParams.osc1Wave != 3) {
        return EXIT_FAILURE;
    }

    audioapp::LiveInstrumentSnapshot live{};
    if (!registry.buildLiveInstrument(oscillator, context, live)) {
        return EXIT_FAILURE;
    }
    if (live.kind != audioapp::LiveInstrumentKind::Oscillator) {
        return EXIT_FAILURE;
    }
    if (!expectFalse(registry.buildLiveInstrument(gain, context, live))) {
        return EXIT_FAILURE;
    }

    const auto modParams = registry.modulatableParams(audioapp::device_types::kOscillator);
    if (modParams.empty()) {
        return EXIT_FAILURE;
    }

    const audioapp::DeviceState roundTrip =
        registry.toSnapshotState(registry.slotFromSnapshot(registry.toSnapshotState(oscillator)));
    if (roundTrip.type != audioapp::device_types::kOscillator ||
        std::abs(roundTrip.frequencyHz - 880.0f) > 0.001f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
