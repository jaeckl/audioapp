#include "audioapp/ProjectEngine.hpp"
#include "audioapp/SampleBank.hpp"
#include "audioapp/WavetableBank.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <memory>
#include <numeric>
#include <string>
#include <string_view>
#include <vector>

namespace {

#ifndef AUDIOAPP_BENCHMARK_COMMIT
#define AUDIOAPP_BENCHMARK_COMMIT "unknown"
#endif

using Clock = std::chrono::steady_clock;

struct Options {
    int warmup = 20;
    int iterations = 80;
    std::vector<int> sampleRates{44100, 48000, 96000};
    std::vector<int> blockSizes{512, 1024, 2048, 4096};
    std::string scenarioFilter;
};

struct Scenario {
    std::string name;
    std::unique_ptr<audioapp::ProjectEngine> engine;
    std::unique_ptr<audioapp::SampleBank> sampleBank;
    std::unique_ptr<audioapp::WavetableBank> wavetableBank;
    std::string controlledDevice;
    bool alternatesManualGain = false;
};

struct Result {
    std::string scenario;
    int sampleRate = 0;
    int blockSize = 0;
    double medianUs = 0.0;
    double p95Us = 0.0;
    double maxUs = 0.0;
    double realtimeFactor = 0.0;
    double checksum = 0.0;
};

bool parsePositive(const char* value, int& output) {
    if (value == nullptr) return false;
    char* end = nullptr;
    const long parsed = std::strtol(value, &end, 10);
    if (end == value || *end != '\0' || parsed <= 0 || parsed > 1000000) return false;
    output = static_cast<int>(parsed);
    return true;
}

Options parseOptions(int argc, char** argv) {
    Options options;
    for (int index = 1; index < argc; ++index) {
        const std::string_view arg(argv[index]);
        if (arg == "--quick") {
            options.warmup = 2;
            options.iterations = 8;
            options.sampleRates = {48000};
            options.blockSizes = {512};
        } else if (arg == "--warmup" && index + 1 < argc) {
            if (!parsePositive(argv[++index], options.warmup)) std::exit(2);
        } else if (arg == "--iterations" && index + 1 < argc) {
            if (!parsePositive(argv[++index], options.iterations)) std::exit(2);
        } else if (arg == "--sample-rate" && index + 1 < argc) {
            int value = 0;
            if (!parsePositive(argv[++index], value)) std::exit(2);
            options.sampleRates = {value};
        } else if (arg == "--block-size" && index + 1 < argc) {
            int value = 0;
            if (!parsePositive(argv[++index], value) || value > 4096) std::exit(2);
            options.blockSizes = {value};
        } else if (arg == "--scenario" && index + 1 < argc) {
            options.scenarioFilter = argv[++index];
        } else {
            std::cerr << "Unknown benchmark option: " << arg << '\n';
            std::exit(2);
        }
    }
    return options;
}

std::string architecture() {
#if defined(__aarch64__) || defined(_M_ARM64)
    return "arm64";
#elif defined(__arm__) || defined(_M_ARM)
    return "arm";
#elif defined(__x86_64__) || defined(_M_X64)
    return "x64";
#elif defined(__i386__) || defined(_M_IX86)
    return "x86";
#else
    return "unknown";
#endif
}

std::string compiler() {
#if defined(__clang__)
    return std::string("clang-") + __clang_version__;
#elif defined(_MSC_VER)
    return std::string("msvc-") + std::to_string(_MSC_VER);
#elif defined(__GNUC__)
    return std::string("gcc-") + __VERSION__;
#else
    return "unknown";
#endif
}

std::string buildType() {
#if defined(NDEBUG)
    return "release";
#else
    return "debug";
#endif
}

std::string addOscillatorTrack(audioapp::ProjectEngine& engine,
                               const std::string& name,
                               std::string* createdTrack = nullptr) {
    const auto track = engine.addTrack(name);
    if (createdTrack != nullptr) *createdTrack = track;
    const auto oscillator = engine.addDeviceToTrack(
        track, audioapp::device_types::kOscillator);
    const auto clip = engine.createMidiClip(track, 0.0, 256.0);
    engine.setMidiClipNotes(clip, {{60, 0.0, 256.0, 100.0f}});
    return oscillator;
}

Scenario makeScenario(std::string_view name) {
    Scenario scenario;
    scenario.name = std::string(name);
    scenario.engine = std::make_unique<audioapp::ProjectEngine>();
    scenario.engine->createProject();

    if (name == "parallel_branches") {
        for (int track = 0; track < 4; ++track)
            addOscillatorTrack(*scenario.engine, "Branch " + std::to_string(track + 1));
    } else {
        std::string trackId;
        scenario.controlledDevice = addOscillatorTrack(
            *scenario.engine, "Benchmark", &trackId);
        if (name == "manual_ramp") {
            scenario.alternatesManualGain = true;
        } else if (name == "automation") {
            const auto clip = scenario.engine->createAutomationClip(trackId, 0.0, 256.0);
            scenario.engine->assignAutomationTarget(clip, scenario.controlledDevice, "gain");
            scenario.engine->setAutomationPoints(clip, {{0.0, 0.2f}, {256.0, 0.8f}});
        } else if (name == "modulation") {
            const int lfo = scenario.engine->createLfo(0);
            scenario.engine->updateLfoParam(lfo, "waveform", 0.0f);
            scenario.engine->updateLfoParam(lfo, "rate", 4.0f);
            scenario.engine->updateLfoParam(lfo, "retrigger", 1.0f);
            scenario.engine->assignModulation(lfo, scenario.controlledDevice, "gain", 0.5f);
        } else if (name == "serial_chain") {
            scenario.engine->addDeviceToTrack(trackId, audioapp::device_types::kDistortion);
            scenario.engine->addDeviceToTrack(trackId, audioapp::device_types::kFilter);
            scenario.engine->addDeviceToTrack(trackId, audioapp::device_types::kReverb);
        } else if (name == "graph_taps") {
            for (int tap = 0; tap < 16; ++tap)
                scenario.engine->createGraphTap(
                    scenario.controlledDevice, audioapp::GraphTapKind::Meter, 64);
        } else if (name == "analyzer") {
            const auto analyzer = scenario.engine->addDeviceToTrack(
                trackId, audioapp::device_types::kSpectrumAnalyzer);
            scenario.engine->setMeterSubscriptions({analyzer});
        } else if (name == "subtractive_synth") {
            scenario.controlledDevice = scenario.engine->addDeviceToTrack(
                trackId, audioapp::device_types::kSubtractiveSynth);
            scenario.engine->setDeviceParameter(scenario.controlledDevice, "filterCutoff", 0.35f);
            scenario.engine->setDeviceParameter(scenario.controlledDevice, "unisonVoices", 0.75f);
            const int lfo = scenario.engine->createLfo(0);
            scenario.engine->updateLfoParam(lfo, "waveform", 0.0f);
            scenario.engine->updateLfoParam(lfo, "rate", 4.0f);
            scenario.engine->assignModulation(lfo, scenario.controlledDevice, "filterCutoff", 0.6f);
        } else if (name == "wavetable_synth") {
            scenario.wavetableBank = std::make_unique<audioapp::WavetableBank>();
            constexpr int kFrames = 4;
            constexpr int kLen = 256;
            std::vector<float> pcm(static_cast<size_t>(kFrames * kLen), 0.0f);
            for (int frame = 0; frame < kFrames; ++frame) {
                for (int i = 0; i < kLen; ++i) {
                    const float phase = 6.28318530718f * static_cast<float>(i) /
                                        static_cast<float>(kLen);
                    pcm[static_cast<size_t>(frame * kLen + i)] =
                        std::sin(phase) * (0.4f + 0.15f * static_cast<float>(frame));
                }
            }
            scenario.wavetableBank->addPcmTable("bench_sine", std::move(pcm), kFrames, kLen);
            scenario.engine->setWavetableBank(scenario.wavetableBank.get());
            scenario.controlledDevice = scenario.engine->addDeviceToTrack(
                trackId, audioapp::device_types::kWavetableSynth);
            scenario.engine->setDeviceStringParameter(scenario.controlledDevice, "wavetableId",
                                                      "bench_sine");
            scenario.engine->setDeviceParameter(scenario.controlledDevice, "filterCutoff", 0.35f);
            scenario.engine->setDeviceParameter(scenario.controlledDevice, "wtUnison", 0.75f);
            scenario.engine->setDeviceParameter(scenario.controlledDevice, "wtDetune", 0.5f);
            const int lfo = scenario.engine->createLfo(0);
            scenario.engine->updateLfoParam(lfo, "waveform", 0.0f);
            scenario.engine->updateLfoParam(lfo, "rate", 4.0f);
            scenario.engine->assignModulation(lfo, scenario.controlledDevice, "filterCutoff", 0.6f);
        } else if (name == "phasemod_synth") {
            scenario.controlledDevice = scenario.engine->addDeviceToTrack(
                trackId, audioapp::device_types::kPhaseModSynth);
            scenario.engine->setDeviceParameter(scenario.controlledDevice, "filterCutoff", 0.35f);
            scenario.engine->setDeviceParameter(scenario.controlledDevice, "unisonVoices", 0.75f);
            scenario.engine->setDeviceParameter(scenario.controlledDevice, "unisonDetune", 0.5f);
            const int lfo = scenario.engine->createLfo(0);
            scenario.engine->updateLfoParam(lfo, "waveform", 0.0f);
            scenario.engine->updateLfoParam(lfo, "rate", 4.0f);
            scenario.engine->assignModulation(lfo, scenario.controlledDevice, "filterCutoff", 0.6f);
        } else if (name == "granular_synth") {
            scenario.sampleBank = std::make_unique<audioapp::SampleBank>();
            scenario.sampleBank->registerBundledDefaults();
            scenario.engine->setSampleBank(scenario.sampleBank.get());
            scenario.controlledDevice = scenario.engine->addDeviceToTrack(
                trackId, audioapp::device_types::kGranular);
            // Bind bundled formant source sample used by granular.
            scenario.engine->setDeviceStringParameter(scenario.controlledDevice, "sampleId",
                                                      "sample_form_source");
            scenario.engine->setDeviceParameter(scenario.controlledDevice, "density", 0.55f);
            scenario.engine->setDeviceParameter(scenario.controlledDevice, "size", 0.4f);
            const int lfo = scenario.engine->createLfo(0);
            scenario.engine->updateLfoParam(lfo, "waveform", 0.0f);
            scenario.engine->updateLfoParam(lfo, "rate", 4.0f);
            scenario.engine->assignModulation(lfo, scenario.controlledDevice, "density", 0.5f);
        }
    }
    scenario.engine->setPlaying(true);
    return scenario;
}

double percentile(const std::vector<double>& sorted, double fraction) {
    if (sorted.empty()) return 0.0;
    const size_t index = std::min(
        sorted.size() - 1,
        static_cast<size_t>(std::ceil(fraction * static_cast<double>(sorted.size()))) - 1);
    return sorted[index];
}

Result runScenario(const Options& options, std::string_view scenarioName,
                   int sampleRate, int blockSize) {
    auto scenario = makeScenario(scenarioName);
    std::vector<float> left(static_cast<size_t>(blockSize));
    std::vector<float> right(static_cast<size_t>(blockSize));
    const double beatsPerFrame = 120.0 / (60.0 * static_cast<double>(sampleRate));
    double playheadBeat = 0.0;
    double checksum = 0.0;

    const auto render = [&](int iteration) {
        if (scenario.alternatesManualGain) {
            scenario.engine->setDeviceParameter(
                scenario.controlledDevice, "gain", iteration % 2 == 0 ? 0.2f : 0.8f);
        }
        scenario.engine->readMasterMixStereo(
            left.data(), right.data(), blockSize, sampleRate, playheadBeat);
        playheadBeat += beatsPerFrame * static_cast<double>(blockSize);
        checksum += left[static_cast<size_t>(iteration % blockSize)];
    };

    for (int iteration = 0; iteration < options.warmup; ++iteration) render(iteration);
    std::vector<double> samples;
    samples.reserve(static_cast<size_t>(options.iterations));
    for (int iteration = 0; iteration < options.iterations; ++iteration) {
        const auto start = Clock::now();
        render(iteration + options.warmup);
        const auto end = Clock::now();
        samples.push_back(std::chrono::duration<double, std::micro>(end - start).count());
    }
    std::sort(samples.begin(), samples.end());
    const double callbackBudgetUs = 1000000.0 * static_cast<double>(blockSize) /
        static_cast<double>(sampleRate);
    Result result;
    result.scenario = std::string(scenarioName);
    result.sampleRate = sampleRate;
    result.blockSize = blockSize;
    result.medianUs = percentile(samples, 0.5);
    result.p95Us = percentile(samples, 0.95);
    result.maxUs = samples.empty() ? 0.0 : samples.back();
    result.realtimeFactor = result.medianUs > 0.0
        ? callbackBudgetUs / result.medianUs : 0.0;
    result.checksum = checksum;
    return result;
}

} // namespace

int main(int argc, char** argv) {
    const auto options = parseOptions(argc, argv);
    const std::vector<std::string> scenarios{
        "static", "manual_ramp", "automation", "modulation", "serial_chain",
        "parallel_branches", "graph_taps", "analyzer", "subtractive_synth",
        "wavetable_synth", "phasemod_synth", "granular_synth"};
    std::vector<Result> results;
    for (const auto& scenario : scenarios) {
        if (!options.scenarioFilter.empty() && scenario != options.scenarioFilter) continue;
        for (const int sampleRate : options.sampleRates)
            for (const int blockSize : options.blockSizes)
                results.push_back(runScenario(options, scenario, sampleRate, blockSize));
    }
    if (results.empty()) {
        std::cerr << "No benchmark scenario matched the filter\n";
        return 2;
    }

    std::cout << std::fixed << std::setprecision(3);
    std::cout << "{\"schemaVersion\":1,\"metadata\":{\"architecture\":\""
              << architecture() << "\",\"compiler\":\"" << compiler()
              << "\",\"buildType\":\"" << buildType()
              << "\",\"commit\":\"" << AUDIOAPP_BENCHMARK_COMMIT
              << "\",\"processorGraphSnapshotBytes\":"
              << sizeof(audioapp::ProcessorGraphSnapshot)
              << ",\"warmup\":" << options.warmup
              << ",\"iterations\":" << options.iterations << "},\"results\":[";
    for (size_t index = 0; index < results.size(); ++index) {
        if (index != 0) std::cout << ',';
        const auto& result = results[index];
        std::cout << "{\"scenario\":\"" << result.scenario
                  << "\",\"sampleRate\":" << result.sampleRate
                  << ",\"blockSize\":" << result.blockSize
                  << ",\"medianUs\":" << result.medianUs
                  << ",\"p95Us\":" << result.p95Us
                  << ",\"maxUs\":" << result.maxUs
                  << ",\"realtimeFactor\":" << result.realtimeFactor
                  << ",\"checksum\":" << result.checksum << '}';
    }
    std::cout << "]}\n";
    return 0;
}
