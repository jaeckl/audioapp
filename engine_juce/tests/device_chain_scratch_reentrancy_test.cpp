#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "TestChainHelper.hpp"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"
#include "audioapp/DeviceSubgraph.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"

#include <cmath>
#include <cstring>
#include <memory>
#include <vector>

namespace {

float windowRms(const float* left, const float* right, int start, int count) noexcept {
    double sum = 0.0;
    for (int i = 0; i < count; ++i) {
        const double l = static_cast<double>(left[start + i]);
        const double r = static_cast<double>(right[start + i]);
        sum += l * l + r * r;
    }
    return static_cast<float>(std::sqrt(sum / static_cast<double>(std::max(1, count * 2))));
}

} // namespace

class DeviceChainScratchReentrancyTest : public juce::UnitTest {
public:
    DeviceChainScratchReentrancyTest()
        : juce::UnitTest("DeviceChainScratchReentrancy", "Devices") {}

    void runTest() override {
        using namespace audioapp;
        using namespace audioapp::test;

        beginTest("nested chain preserves outer per-frame gain automation");
        {
            constexpr int kFrames = 4096;
            constexpr double kSampleRate = 48000.0;
            constexpr const char* kNestedChainId = "nested-chain";

            auto innerPlayback = std::make_shared<ChainPlayback>();
            innerPlayback->deviceCount = 1;
            innerPlayback->devices[0].kind = DeviceNodeKind::Oscillator;
            innerPlayback->devices[0].deviceId = "inner-osc";
            innerPlayback->devices[0].gain = 1.0f;
            innerPlayback->devices[0].pan = 0.5f;
            innerPlayback->devices[0].params = OscillatorParams{880.0f};

            DeviceNodePlayback devices[2] = {};
            devices[0].kind = DeviceNodeKind::Oscillator;
            devices[0].deviceId = "source-osc";
            devices[0].gain = 1.0f;
            devices[0].pan = 0.5f;
            devices[0].params = OscillatorParams{440.0f};

            devices[1].kind = DeviceNodeKind::Chain;
            devices[1].deviceId = kNestedChainId;
            devices[1].gain = 1.0f;
            devices[1].pan = 0.5f;
            devices[1].params = ChainParams{innerPlayback, 1.0f, 1.0f};

            AutomationClipPlayback gainAuto{};
            gainAuto.targetNodeId = stableDeviceSubgraphNodeId(
                kNestedChainId, DeviceSubgraphNodeRole::DeviceProcessor);
            gainAuto.deviceIndex = 1;
            gainAuto.localParamId = kEncodedCommonGain;
            gainAuto.clipStartBeat = 0.0f;
            gainAuto.clipLengthBeats = 4.0f;
            gainAuto.pointCount = 2;
            gainAuto.points[0] = {0.0f, 0.0f};
            gainAuto.points[1] = {4.0f, 1.0f};

            float left[kFrames];
            float right[kFrames];
            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));

            thread_local ProcessorArena arena;
            thread_local DeviceChainScratch scratch;
            buildProcessorChain(devices, 2, arena);
            if (auto* chainProc = arena.get(1))
                chainProc->bindCompiledParameterSpans(&gainAuto, 1, nullptr, 0);

            DeviceChainOrchestrator::Context ctx(arena, scratch);
            ctx.trackLeft = left;
            ctx.trackRight = right;
            ctx.numFrames = kFrames;
            ctx.sampleRate = kSampleRate;
            ctx.bpm = 120;
            ctx.playheadStartBeat = 0.0;
            ctx.automationClips = &gainAuto;
            ctx.automationClipCount = 1;
            DeviceChainOrchestrator::processChain(ctx);

            const float earlyRms = windowRms(left, right, 0, 256);
            const float lateRms = windowRms(left, right, kFrames - 256, 256);
            expect(earlyRms < lateRms * 0.5f,
                   "outer chain gain automation should ramp up across the block");
            expect(lateRms > earlyRms && lateRms > 1.0e-4f,
                   "nested chain should still produce audible output");
        }

        beginTest("renderOffline nested chain gain automation survives inner processing");
        {
            EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("NestedScratch");
            host.selectTrack(trackId);
            expect(!host.addDeviceToTrack(trackId, "simple_oscillator").empty(),
                   "source oscillator added");
            const std::string chainId = host.addDeviceToTrack(trackId, "device_chain");
            expect(!chainId.empty(), "nested chain container added");
            expect(!host.addDeviceToChain(chainId, "simple_oscillator").empty(),
                   "inner chain oscillator added");

            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
            expect(!midiClipId.empty(), "midi clip created");
            std::vector<MidiNoteState> notes;
            notes.push_back({60, 0.0, 4.0, 100.0f});
            expect(host.setMidiClipNotes(midiClipId, notes), "midi notes set");

            const std::string autoClipId = host.createAutomationClip(trackId, 0.0, 4.0);
            expect(!autoClipId.empty(), "automation clip created");
            expect(host.assignAutomationTarget(autoClipId, chainId, "gain"),
                   "automation targets nested chain gain");
            std::vector<AutomationPointState> points;
            points.push_back({0.0, 0.0f});
            points.push_back({4.0, 1.0f});
            expect(host.setAutomationPoints(autoClipId, points), "automation points set");

            host.setPlaying(true);
            const std::vector<float> rendered = host.renderOffline(4.0, 48000.0);
            expect(static_cast<int>(rendered.size()) >= 48000, "enough audio rendered");

            constexpr int kWindows = 8;
            const std::vector<float> rmsPerWindow = windowRMS(rendered, kWindows);
            expect(rmsPerWindow[0] < rmsPerWindow[kWindows - 1],
                   "early window quieter than late window with nested chain");
            int risingPairs = 0;
            for (int w = 1; w < kWindows; ++w) {
                if (rmsPerWindow[static_cast<size_t>(w)] >
                    rmsPerWindow[static_cast<size_t>(w - 1)])
                    ++risingPairs;
            }
            expect(risingPairs >= kWindows - 2,
                   "nested chain preserves upward gain automation trend");
        }

        beginTest("renderOffline inner chain child gain automation affects playback");
        {
            EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("InnerChildAuto");
            host.selectTrack(trackId);
            expect(!host.addDeviceToTrack(trackId, "simple_oscillator").empty(),
                   "source oscillator added");
            const std::string chainId = host.addDeviceToTrack(trackId, "device_chain");
            expect(!chainId.empty(), "nested chain container added");
            expect(!host.addDeviceToChain(chainId, "track_gain").empty(),
                   "inner chain child 0 added");
            const std::string innerGainId =
                host.addDeviceToChain(chainId, "track_gain");
            expect(!innerGainId.empty(), "inner chain child 1 added");

            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
            expect(!midiClipId.empty(), "midi clip created");
            std::vector<MidiNoteState> notes;
            notes.push_back({60, 0.0, 4.0, 100.0f});
            expect(host.setMidiClipNotes(midiClipId, notes), "midi notes set");

            const std::string autoClipId = host.createAutomationClip(trackId, 0.0, 4.0);
            expect(!autoClipId.empty(), "automation clip created");
            expect(host.assignAutomationTarget(autoClipId, innerGainId, "gain"),
                   "automation targets second inner chain device");
            std::vector<AutomationPointState> points;
            points.push_back({0.0, 0.0f});
            points.push_back({4.0, 1.0f});
            expect(host.setAutomationPoints(autoClipId, points), "automation points set");

            host.setPlaying(true);
            const std::vector<float> rendered = host.renderOffline(4.0, 48000.0);
            expect(static_cast<int>(rendered.size()) >= 48000, "enough audio rendered");

            constexpr int kWindows = 8;
            const std::vector<float> rmsPerWindow = windowRMS(rendered, kWindows);
            expect(rmsPerWindow[0] < rmsPerWindow[kWindows - 1],
                   "second inner chain child gain automation should ramp output");
        }
    }
};

static DeviceChainScratchReentrancyTest deviceChainScratchReentrancyTest;
