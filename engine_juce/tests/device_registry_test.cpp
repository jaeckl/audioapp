#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/EngineHost.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    const audioapp::DeviceRegistry registry = audioapp::DeviceRegistry::createBuiltIn();

    const auto known = registry.knownTypes();
    if (known.size() != 5) {
        return EXIT_FAILURE;
    }

    if (registry.find("unknown_device") != nullptr) {
        return EXIT_FAILURE;
    }
    if (registry.isKnownType(audioapp::device_types::kOscillator) != true) {
        return EXIT_FAILURE;
    }

    const audioapp::DeviceState oscillator = registry.toSnapshotState(registry.createDefault(
        audioapp::device_types::kOscillator, "dev-test-1"));
    if (oscillator.type != audioapp::device_types::kOscillator) {
        return EXIT_FAILURE;
    }
    if (oscillator.id != "dev-test-1") {
        return EXIT_FAILURE;
    }
    if (std::abs(oscillator.frequencyHz - 440.0f) > 0.001f) {
        return EXIT_FAILURE;
    }

    const audioapp::DeviceState gain = registry.toSnapshotState(registry.createDefault(
        audioapp::device_types::kTrackGain, "dev-test-2"));
    if (gain.type != audioapp::device_types::kTrackGain) {
        return EXIT_FAILURE;
    }
    if (std::abs(gain.gain - 1.0f) > 0.001f) {
        return EXIT_FAILURE;
    }

    const audioapp::DeviceState synth = registry.toSnapshotState(registry.createDefault(
        audioapp::device_types::kSubtractiveSynth, "dev-test-3"));
    if (synth.type != audioapp::device_types::kSubtractiveSynth) {
        return EXIT_FAILURE;
    }
    if (std::abs(synth.filterCutoff - 0.75f) > 0.001f) {
        return EXIT_FAILURE;
    }
    if (std::abs(synth.osc1Shape - 0.5f) > 0.001f) {
        return EXIT_FAILURE;
    }

    audioapp::EngineHost host;
    host.createProject();
    const std::string trackId = host.addTrack("Test");
    if (trackId.empty()) {
        return EXIT_FAILURE;
    }

    const std::string oscId = host.addDeviceToTrack(trackId, "simple_oscillator");
    if (oscId.empty()) {
        return EXIT_FAILURE;
    }

    if (!host.addDeviceToTrack(trackId, "not_a_real_device").empty()) {
        return EXIT_FAILURE;
    }

    const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");
    if (synthId.empty()) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
