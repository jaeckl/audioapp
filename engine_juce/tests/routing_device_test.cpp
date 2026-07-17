#include "audioapp/ProjectEngine.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

#include <algorithm>
#include <cmath>
#include <atomic>
#include <iostream>
#include <memory>
#include <thread>
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

std::vector<float> jsonFloatArray(const juce::var& object, const char* key) {
    std::vector<float> result;
    if (const auto* values = object[key].getArray()) {
        result.reserve(static_cast<size_t>(values->size()));
        for (const auto& value : *values) result.push_back(static_cast<float>(value));
    }
    return result;
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
    const auto capturedLeft = jsonFloatArray(recorderJson, "left");
    bool outputSamplesMatch = capturedLeft.size() == 128;
    for (size_t i = 0; outputSamplesMatch && i < capturedLeft.size(); ++i) {
        outputSamplesMatch = std::abs(capturedLeft[i] - tapLeft[i]) < 1.0e-6f;
    }
    expect(outputSamplesMatch,
           "recorder observes the exact post-output-adapter signal sent to the track");
    expect(audioProject->removeGraphTap(meterTap) &&
           audioProject->removeGraphTap(recorderTap),
           "runtime taps can be removed safely");
    expect(audioProject->readGraphTapJson(meterTap).find("tap_not_found") != std::string::npos,
           "removed tap generations are no longer readable");

    expect(audioProject->createGraphTap("missing-device", GraphTapKind::Meter).empty() &&
           audioProject->createGraphTap(oscillator, GraphTapKind::None).empty(),
           "invalid targets and tap kinds are rejected");
    std::vector<std::string> capacityTaps;
    for (int i = 0; i < kMaxProcessorGraphTaps; ++i) {
        capacityTaps.push_back(audioProject->createGraphTap(
            oscillator, GraphTapKind::Meter, 1));
    }
    bool allCapacitySlotsCreated = true;
    for (const auto& id : capacityTaps) allCapacitySlotsCreated &= !id.empty();
    expect(allCapacitySlotsCreated &&
           audioProject->createGraphTap(oscillator, GraphTapKind::Meter, 1).empty(),
           "runtime accepts exactly the fixed 16-tap capacity");
    for (const auto& id : capacityTaps) expect(audioProject->removeGraphTap(id),
        "capacity tap can be removed");

    const auto clampedTap = audioProject->createGraphTap(
        oscillator, GraphTapKind::Recorder, 0);
    audioProject->setPlaying(true);
    audioProject->readMasterMixStereo(tapLeft, tapRight, 8, 48000.0, 0.0);
    audioProject->setPlaying(false);
    const auto clampedJson = juce::JSON::parse(audioProject->readGraphTapJson(clampedTap, 8));
    expect(static_cast<int>(clampedJson["frameCount"]) == 1 &&
           static_cast<int>(clampedJson["droppedFrames"]) == 7,
           "zero requested capacity clamps to one bounded frame");
    expect(audioProject->removeGraphTap(clampedTap), "clamped recorder tap is removable");

    const auto drainingTap = audioProject->createGraphTap(
        oscillator, GraphTapKind::Recorder, 32);
    audioProject->setPlaying(true);
    audioProject->readMasterMixStereo(tapLeft, tapRight, 32, 48000.0, 0.0);
    audioProject->setPlaying(false);
    const auto firstDrain = juce::JSON::parse(audioProject->readGraphTapJson(drainingTap, 7));
    const auto secondDrain = juce::JSON::parse(audioProject->readGraphTapJson(drainingTap, 32));
    auto drained = jsonFloatArray(firstDrain, "left");
    const auto remainder = jsonFloatArray(secondDrain, "left");
    drained.insert(drained.end(), remainder.begin(), remainder.end());
    bool drainOrderMatches = drained.size() == 32;
    for (size_t i = 0; drainOrderMatches && i < drained.size(); ++i) {
        drainOrderMatches = std::abs(drained[i] - tapLeft[i]) < 1.0e-6f;
    }
    expect(static_cast<int>(firstDrain["frameCount"]) == 7 &&
           static_cast<int>(secondDrain["frameCount"]) == 25 && drainOrderMatches,
           "multiple recorder drains preserve exact sample order");
    expect(audioProject->removeGraphTap(drainingTap), "drained recorder tap is removable");

    const auto analyzerTap = audioProject->createGraphTap(
        oscillator, GraphTapKind::Analyzer, 64);
    audioProject->setPlaying(true);
    audioProject->readMasterMixStereo(tapLeft, tapRight, 128, 48000.0, 0.0);
    audioProject->setPlaying(false);
    const auto analyzerOverflow = juce::JSON::parse(
        audioProject->readGraphTapJson(analyzerTap));
    const auto waveform = jsonFloatArray(analyzerOverflow, "waveform");
    const auto spectrum = jsonFloatArray(analyzerOverflow, "spectrum");
    expect(static_cast<bool>(analyzerOverflow["overflowed"]) &&
           static_cast<int>(analyzerOverflow["droppedFrames"]) == 64 &&
           waveform.size() == 32 && spectrum.size() == 24 &&
           *std::max_element(waveform.begin(), waveform.end()) > 0.0f &&
           *std::max_element(spectrum.begin(), spectrum.end()) > 0.0f,
           "analyzer returns non-silent waveform/spectrum data and reports overflow");
    audioProject->setPlaying(true);
    audioProject->readMasterMixStereo(tapLeft, tapRight, 32, 48000.0, 0.0);
    audioProject->setPlaying(false);
    const auto analyzerRecovered = juce::JSON::parse(
        audioProject->readGraphTapJson(analyzerTap));
    expect(static_cast<int>(analyzerRecovered["sequence"]) >= 96,
           "analyzer resumes accepting samples after a drain");
    expect(audioProject->removeGraphTap(analyzerTap), "analyzer tap is removable");

    const auto spectrumTap = audioProject->createGraphTap(
        oscillator, GraphTapKind::Analyzer, kGraphTapAnalyzerWindowFrames);
    audioProject->setPlaying(true);
    audioProject->readMasterMixStereo(tapLeft, tapRight, 128, 48000.0, 0.0);
    audioProject->readMasterMixStereo(tapLeft, tapRight, 128, 48000.0, 0.0);
    audioProject->setPlaying(false);
    const auto spectrumJson = juce::JSON::parse(
        audioProject->readGraphTapJson(spectrumTap));
    const auto accurateSpectrum = jsonFloatArray(spectrumJson, "spectrum");
    const auto strongestBin = std::distance(
        accurateSpectrum.begin(),
        std::max_element(accurateSpectrum.begin(), accurateSpectrum.end()));
    // The analyzer bins are 187.5 Hz apart at 48 kHz / 256 frames. A 440 Hz
    // oscillator is therefore closest to the second reported bin (375 Hz).
    expect(accurateSpectrum.size() == 24 && strongestBin == 1,
           "analyzer spectrum places a known 440 Hz tone in the nearest DFT bin");
    expect(audioProject->removeGraphTap(spectrumTap), "spectrum accuracy tap is removable");

    const auto bypassTap = audioProject->createGraphTap(
        oscillator, GraphTapKind::Recorder, 32);
    expect(audioProject->setDeviceParameter(oscillator, "bypass", 1.0f),
           "tapped source can be bypassed");
    audioProject->setPlaying(true);
    audioProject->readMasterMixStereo(tapLeft, tapRight, 32, 48000.0, 0.0);
    audioProject->setPlaying(false);
    const auto bypassJson = juce::JSON::parse(
        audioProject->readGraphTapJson(bypassTap, 32));
    const auto bypassCaptured = jsonFloatArray(bypassJson, "left");
    bool bypassMatches = bypassCaptured.size() == 32;
    for (size_t i = 0; bypassMatches && i < bypassCaptured.size(); ++i) {
        bypassMatches = std::abs(bypassCaptured[i] - tapLeft[i]) < 1.0e-6f;
    }
    expect(bypassMatches,
           "tap and track observe equivalent output when the source is bypassed");
    expect(audioProject->removeGraphTap(bypassTap) &&
           audioProject->setDeviceParameter(oscillator, "bypass", 0.0f),
           "bypass tap is removed and source is restored");

    const auto deletedSourceTap = audioProject->createGraphTap(
        oscillator, GraphTapKind::Meter, 64);
    expect(audioProject->removeDeviceFromTrack(oscillator),
           "tapped source can be deleted");
    const auto deletedSourceJson = juce::JSON::parse(
        audioProject->readGraphTapJson(deletedSourceTap));
    expect(!static_cast<bool>(deletedSourceJson["sourceAvailable"]),
           "tap readback explicitly reports a deleted source");
    const auto persistedData = audioProject->toProjectFileData();
    expect(audioProject->loadFromProjectFileData(persistedData),
           "project reload succeeds while a runtime-only tap exists");
    expect(audioProject->readGraphTapJson(deletedSourceTap).find("tap_not_found") != std::string::npos,
           "project reload clears runtime-only taps instead of persisting them");

    // Recreate an oscillator for routing and concurrent lifecycle tests.
    const auto replacementOscillator = audioProject->addDeviceToTrack(
        source, device_types::kOscillator);
    std::atomic<bool> keepRendering{true};
    std::atomic<bool> callbackAudioValid{true};
    std::thread callbackThread([&] {
        float concurrentLeft[64]{};
        float concurrentRight[64]{};
        while (keepRendering.load(std::memory_order_acquire)) {
            audioProject->readMasterMixStereo(
                concurrentLeft, concurrentRight, 64, 48000.0, 0.0);
            for (int i = 0; i < 64; ++i) {
                if (!std::isfinite(concurrentLeft[i]) ||
                    !std::isfinite(concurrentRight[i])) {
                    callbackAudioValid.store(false, std::memory_order_release);
                }
            }
        }
    });
    bool concurrentLifecycleSucceeded = true;
    for (int iteration = 0; iteration < 64; ++iteration) {
        const auto liveTap = audioProject->createGraphTap(
            replacementOscillator, GraphTapKind::Recorder, 64);
        concurrentLifecycleSucceeded &= !liveTap.empty();
        concurrentLifecycleSucceeded &= audioProject->removeGraphTap(liveTap);
    }
    keepRendering.store(false, std::memory_order_release);
    callbackThread.join();
    expect(concurrentLifecycleSucceeded && callbackAudioValid.load(std::memory_order_acquire),
           "tap slots survive concurrent callback creation, removal, and immediate reuse");

    const auto audioReceiver = audioProject->addDeviceToTrack(destination, device_types::kAudioReceiver);
    expect(!audioReceiver.empty(), "audio receiver is created");
    expect(audioProject->setDeviceStringParameter(audioReceiver, "sourceId", replacementOscillator),
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
                   audioReceiver, "sourceId", connected ? replacementOscillator : ""),
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
