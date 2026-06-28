#include "audioapp/ProjectEngine.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

#include <cmath>
#include <iostream>
#include <memory>
#include <vector>

namespace {

int failures = 0;

void expect(bool condition, const char* message) {
    if (condition) return;
    ++failures;
    std::cerr << "FAIL: " << message << '\n';
}

float rms(const std::vector<float>& audio) {
    double sum = 0.0;
    for (float sample : audio) sum += static_cast<double>(sample) * sample;
    return audio.empty() ? 0.0f : static_cast<float>(std::sqrt(sum / audio.size()));
}

} // namespace

int main() {
    using namespace audioapp;

    auto audioProject = std::make_unique<ProjectEngine>();
    audioProject->createProject();
    const auto source = audioProject->addTrack("Source");
    const auto destination = audioProject->addTrack("Destination");
    const auto oscillator = audioProject->addDeviceToTrack(source, device_types::kOscillator);
    expect(!oscillator.empty(),
           "source oscillator is created");
    const float baseline = rms(audioProject->renderOffline(0.5, 48000.0));
    const auto audioReceiver = audioProject->addDeviceToTrack(destination, device_types::kAudioReceiver);
    expect(!audioReceiver.empty(), "audio receiver is created");
    expect(audioProject->setDeviceStringParameter(audioReceiver, "sourceId", oscillator),
           "audio receiver targets the oscillator output");
    const float routed = rms(audioProject->renderOffline(0.5, 48000.0));
    expect(baseline > 0.01f, "baseline oscillator is audible");
    expect(routed > baseline * 1.5f, "audio receiver adds the routed source signal");
    expect(audioProject->setDeviceParameter(audioReceiver, "bypass", 1.0f),
           "audio receiver can be bypassed");
    const float bypassed = rms(audioProject->renderOffline(0.5, 48000.0));
    expect(bypassed < routed * 0.8f, "bypassing receiver removes the graph route");

    auto midiProject = std::make_unique<ProjectEngine>();
    midiProject->createProject();
    const auto midiSource = midiProject->addTrack("MIDI Source");
    const auto synthDestination = midiProject->addTrack("Synth Destination");
    expect(!midiProject->addDeviceToTrack(synthDestination, device_types::kSubtractiveSynth).empty(),
           "destination synth is created");
    const auto clip = midiProject->createMidiClip(midiSource, 0.0, 4.0);
    expect(midiProject->setMidiClipNotes(clip, {{60, 0.0, 1.0, 100.0f}}),
           "source MIDI note is created");
    const float silent = rms(midiProject->renderOffline(0.5, 48000.0));
    const auto midiReceiver = midiProject->addDeviceToTrack(
        synthDestination, device_types::kMidiReceiver, 0);
    expect(!midiReceiver.empty(),
           "MIDI receiver is created");
    expect(midiProject->setDeviceStringParameter(
               midiReceiver, "sourceId", "track-midi:" + midiSource),
           "MIDI receiver targets the source track input");
    const float midiRouted = rms(midiProject->renderOffline(0.5, 48000.0));
    expect(silent < 1.0e-5f, "destination synth is silent without routed MIDI");
    expect(midiRouted > 0.001f, "MIDI receiver drives the destination synth");

    if (failures != 0) return 1;
    std::cout << "All routing device tests passed\n";
    return 0;
}
