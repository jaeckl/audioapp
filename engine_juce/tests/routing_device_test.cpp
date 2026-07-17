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

bool finiteAndBounded(const std::vector<float>& audio) {
    for (float sample : audio) {
        if (!std::isfinite(sample) || std::abs(sample) > 1.001f) return false;
    }
    return true;
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
    const auto meterTap = audioProject->createGraphTap(
        oscillator, GraphTapKind::Meter, 256);
    const auto recorderTap = audioProject->createGraphTap(
        oscillator, GraphTapKind::Recorder, 256);
    expect(!meterTap.empty() && !recorderTap.empty(),
           "multiple runtime taps attach to one output without a receiver");
    float tapLeft[128]{};
    float tapRight[128]{};
    audioProject->setPlaying(true);
    audioProject->readMasterMixStereo(tapLeft, tapRight, 128, 48000.0, 0.0);
    audioProject->setPlaying(false);
    const auto meterJson = juce::JSON::parse(audioProject->readGraphTapJson(meterTap));
    const auto recorderJson = juce::JSON::parse(
        audioProject->readGraphTapJson(recorderTap, 128));
    expect(static_cast<int>(meterJson["sequence"]) > 0 &&
           static_cast<double>(meterJson["peakL"]) > 0.0,
           "meter tap executes at the source output adapter");
    expect(static_cast<int>(recorderJson["frameCount"]) == 128,
           "recorder tap returns the captured block in order");
    expect(audioProject->removeGraphTap(meterTap) &&
           audioProject->removeGraphTap(recorderTap),
           "runtime taps can be removed safely");
    expect(audioProject->readGraphTapJson(meterTap).find("tap_not_found") != std::string::npos,
           "removed tap generations are no longer readable");
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
    expect(audioProject->setDeviceParameter(audioReceiver, "bypass", 0.0f),
           "audio receiver can be re-enabled");
    expect(audioProject->setDeviceStringParameter(audioReceiver, "sourceId", ""),
           "audio receiver can disconnect without rebuilding playback");
    const float disconnected = rms(audioProject->renderOffline(0.5, 48000.0));
    expect(disconnected < routed * 0.8f, "disconnect removes the graph edge");

    // Exercise the actual playback publication path: the graph is rebuilt
    // while playing, feedback is repeatedly created/destroyed, and a nearby
    // processor is inserted/removed. This catches stale feedback-bank reads
    // and invalid snapshot swaps without relying on a device callback.
    audioProject->setPlaying(true);
    for (int iteration = 0; iteration < 24; ++iteration) {
        const bool connected = (iteration & 1) == 0;
        expect(audioProject->setDeviceStringParameter(
                   audioReceiver, "sourceId", connected ? oscillator : ""),
               "live routing source update succeeds");
        expect(audioProject->setDeviceParameter(
                   audioReceiver, "feedback", connected ? 1.0f : 0.0f),
               "live feedback update succeeds");
        const auto effect = audioProject->addDeviceToTrack(destination, "bitcrusher", 0);
        expect(!effect.empty(), "live structural insert succeeds");
        const auto rendered = audioProject->renderOffline(0.04, 48000.0);
        expect(finiteAndBounded(rendered),
               "live graph swap produces finite, bounded audio");
        expect(audioProject->removeDeviceFromTrack(effect),
               "live structural removal succeeds");
    }
    audioProject->setPlaying(false);

    auto chainProject = std::make_unique<ProjectEngine>();
    chainProject->createProject();
    const auto chainTrack = chainProject->addTrack("Chain Tap");
    const auto chain = chainProject->addDeviceToTrack(chainTrack, device_types::kChain);
    const auto chainChild = chainProject->addDeviceToChain(
        chain, device_types::kOscillator);
    const auto chainTap = chainProject->createGraphTap(
        chainChild, GraphTapKind::Meter, 256);
    expect(!chainTap.empty(), "tap attaches to a nested Chain output adapter");
    chainProject->setPlaying(true);
    chainProject->readMasterMixStereo(tapLeft, tapRight, 128, 48000.0, 0.0);
    chainProject->setPlaying(false);
    const auto chainTapJson = juce::JSON::parse(
        chainProject->readGraphTapJson(chainTap));
    expect(static_cast<int>(chainTapJson["sequence"]) > 0,
           "nested Chain context publishes graph taps");

    auto drumProject = std::make_unique<ProjectEngine>();
    drumProject->createProject();
    const auto drumTrack = drumProject->addTrack("Drum Tap");
    const auto drum = drumProject->addDeviceToTrack(
        drumTrack, device_types::kDrumMachine);
    const auto drumChild = drumProject->addDeviceToDrumPad(
        drum, 60, device_types::kOscillator);
    const auto drumClip = drumProject->createMidiClip(drumTrack, 0.0, 4.0);
    expect(drumProject->setMidiClipNotes(
               drumClip, {{60, 0.0, 1.0, 100.0f}}),
           "drum tap test creates a pad trigger");
    const auto drumTap = drumProject->createGraphTap(
        drumChild, GraphTapKind::Recorder, 256);
    expect(!drumTap.empty(), "tap attaches to a Drum Machine pad child output");
    drumProject->setPlaying(true);
    drumProject->readMasterMixStereo(tapLeft, tapRight, 128, 48000.0, 0.0);
    drumProject->setPlaying(false);
    const auto drumTapJson = juce::JSON::parse(
        drumProject->readGraphTapJson(drumTap, 128));
    expect(static_cast<int>(drumTapJson["frameCount"]) == 128,
           "nested Drum Machine context publishes graph taps");

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

    auto delayedProject = std::make_unique<ProjectEngine>();
    delayedProject->createProject();
    const auto delayedSource = delayedProject->addTrack("Delayed MIDI");
    const auto delayedDestination = delayedProject->addTrack("Delayed Synth");
    const auto delayClip = delayedProject->createMidiClip(delayedSource, 0.0, 4.0);
    expect(delayedProject->setMidiClipNotes(delayClip, {{60, 0.0, 1.0, 100.0f}}),
           "delayed MIDI note is created");
    const auto midiDelay = delayedProject->addDeviceToTrack(
        delayedSource, device_types::kMidiDelay, 0);
    expect(!midiDelay.empty(), "MIDI delay is created");
    expect(delayedProject->setDeviceParameter(midiDelay, "midiDelayMode", 1.0f),
           "MIDI delay uses tempo sync");
    expect(delayedProject->setDeviceParameter(midiDelay, "midiDelayDivision", 1.0f),
           "MIDI delay uses a quarter-note delay");
    const auto delayedReceiver = delayedProject->addDeviceToTrack(
        delayedDestination, device_types::kMidiReceiver, 0);
    expect(!delayedReceiver.empty(), "delayed MIDI receiver is created");
    expect(delayedProject->addDeviceToTrack(
               delayedDestination, device_types::kSubtractiveSynth, 1).size() > 0,
           "delayed destination synth is created");
    expect(delayedProject->setDeviceStringParameter(delayedReceiver, "sourceId", midiDelay),
           "MIDI receiver targets the MIDI delay output");
    const float beforeDelay = rms(delayedProject->renderOffline(0.45, 48000.0));
    const float afterDelay = rms(delayedProject->renderOffline(1.5, 48000.0));
    expect(beforeDelay < 1.0e-5f, "MIDI delay is silent before its sync offset");
    expect(afterDelay > 0.001f, "MIDI delay publishes delayed notes to the graph");

    if (failures != 0) return 1;
    std::cout << "All routing device tests passed\n";
    return 0;
}
