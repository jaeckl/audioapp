#include <juce_core/juce_core.h>

#include "TestChainHelper.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/dsp/ProcessorArena.hpp"

#include <cmath>
#include <cstring>

namespace {

void assignNestedPlaybackMeterSlotsForTest(audioapp::DeviceNodePlayback& node,
                                           int& slotCount,
                                           std::string* meterIds) {
    auto publishes = [](const audioapp::DeviceNodePlayback& n) {
        return audioapp::isDynamicsDeviceNodeKind(n.kind) ||
               audioapp::isAnalysisDeviceNodeKind(n.kind) ||
               n.kind == audioapp::DeviceNodeKind::Split ||
               n.kind == audioapp::DeviceNodeKind::MultibandSplit ||
               n.kind == audioapp::DeviceNodeKind::SpectralLoudSplit;
    };
    auto tryAssign = [&](audioapp::DeviceNodePlayback& n) {
        n.meterSlot = -1;
        if (publishes(n) && slotCount < audioapp::kMaxDeviceMeters) {
            n.meterSlot = static_cast<int8_t>(slotCount);
            meterIds[slotCount] = n.deviceId;
            ++slotCount;
        }
    };
    auto walkChild = [&](audioapp::DeviceNodePlayback& child) {
        tryAssign(child);
        assignNestedPlaybackMeterSlotsForTest(child, slotCount, meterIds);
    };

    if (node.kind == audioapp::DeviceNodeKind::Chain) {
        auto playback = std::get<audioapp::ChainParams>(node.params).playback;
        if (playback == nullptr) return;
        auto mutablePlayback =
            std::const_pointer_cast<audioapp::ChainPlayback>(playback);
        for (int child = 0; child < mutablePlayback->deviceCount; ++child)
            walkChild(mutablePlayback->devices[child]);
    }
}

void tryAssignPlaybackMeterSlotForTest(audioapp::DeviceNodePlayback& node,
                                       int& slotCount,
                                       std::string* meterIds) {
    node.meterSlot = -1;
    if ((audioapp::isDynamicsDeviceNodeKind(node.kind) ||
         audioapp::isAnalysisDeviceNodeKind(node.kind) ||
         node.kind == audioapp::DeviceNodeKind::Split ||
         node.kind == audioapp::DeviceNodeKind::MultibandSplit ||
         node.kind == audioapp::DeviceNodeKind::SpectralLoudSplit) &&
        slotCount < audioapp::kMaxDeviceMeters) {
        node.meterSlot = static_cast<int8_t>(slotCount);
        meterIds[slotCount] = node.deviceId;
        ++slotCount;
    }
}

} // namespace

class NestedChainMeterTest : public juce::UnitTest {
public:
    NestedChainMeterTest() : juce::UnitTest("NestedChainMeter", "Devices") {}

    void runTest() override {
        using namespace audioapp;

        beginTest("nested chain compressor writes subscribed meter atomics");
        {
            constexpr int kFrames = 512;

            auto innerPlayback = std::make_shared<ChainPlayback>();
            innerPlayback->deviceCount = 1;
            innerPlayback->devices[0].kind = DeviceNodeKind::Compressor;
            innerPlayback->devices[0].deviceId = "nested-comp";
            innerPlayback->devices[0].gain = 1.0f;
            innerPlayback->devices[0].pan = 0.5f;
            innerPlayback->devices[0].params = CompressorParams{};

            DeviceNodePlayback devices[2] = {};
            devices[0].kind = DeviceNodeKind::Oscillator;
            devices[0].deviceId = "source-osc";
            devices[0].gain = 1.0f;
            devices[0].pan = 0.5f;
            devices[0].params = OscillatorParams{440.0f};

            devices[1].kind = DeviceNodeKind::Chain;
            devices[1].deviceId = "outer-chain";
            devices[1].gain = 1.0f;
            devices[1].pan = 0.5f;
            devices[1].params = ChainParams{innerPlayback, 1.0f, 1.0f};

            int slotCount = 0;
            std::string meterIds[kMaxDeviceMeters];
            tryAssignPlaybackMeterSlotForTest(devices[1], slotCount, meterIds);
            assignNestedPlaybackMeterSlotsForTest(devices[1], slotCount, meterIds);
            expect(innerPlayback->devices[0].meterSlot == 0,
                   "nested compressor should receive meter slot 0");
            expect(meterIds[0] == "nested-comp",
                   "meter id map should include nested device");

            float left[kFrames];
            float right[kFrames];
            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));

            thread_local ProcessorArena arena;
            thread_local DeviceChainScratch scratch;
            buildProcessorChain(devices, 2, arena);

            DeviceMeterAtomic meters[kMaxDeviceMeters]{};
            bool subscribed[kMaxDeviceMeters]{};
            subscribed[0] = true;

            DeviceChainOrchestrator::Context ctx(arena, scratch);
            ctx.trackLeft = left;
            ctx.trackRight = right;
            ctx.numFrames = kFrames;
            ctx.sampleRate = 48000.0;
            ctx.bpm = 120;
            ctx.playheadStartBeat = 0.0;
            ctx.deviceMeters = meters;
            ctx.maxDeviceMeters = kMaxDeviceMeters;
            ctx.meterSlotSubscribed = subscribed;

            DeviceChainOrchestrator::processChain(ctx);

            const float nestedInputPeak =
                meters[0].inputPeak.load(std::memory_order_relaxed);
            expect(nestedInputPeak > 0.01f,
                   "nested compressor should publish input peak when meters forwarded");
        }
    }
};

static NestedChainMeterTest nestedChainMeterTest;
