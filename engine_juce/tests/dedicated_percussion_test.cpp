#include "audioapp/DeviceChain.hpp"
#include "audioapp/LivePerformance.hpp"

#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "TestChainHelper.hpp"

#include <cstring>

class DedicatedPercussionTest : public juce::UnitTest {
public:
    DedicatedPercussionTest() : juce::UnitTest("DedicatedPercussion", "Audio") {}

    template <typename Params>
    void expectChainOutput(audioapp::DeviceNodeKind kind, int pitch, Params params,
                           const char* message) {
        constexpr int frames = 4096;
        float left[frames]{}, right[frames]{};
        audioapp::MidiPlaybackNote note{pitch, 0.0, 4.0, 0.0, 1.0, 100.0f};
        audioapp::DeviceNodePlayback device{};
        device.kind = kind; device.gain = 1.0f; device.pan = 0.5f; device.params = params;
        audioapp::test::processTestChain(left, right, frames, 48000.0, 120, 0.0,
                                         &note, 1, &device, 1, false);
        expect(audioapp::test::peakAbs(left, frames) > 0.001f, message);
    }

    void runTest() override {
        beginTest("all dedicated generators render through the graph");
        expectChainOutput(audioapp::DeviceNodeKind::HihatGenerator, 42,
                          audioapp::HihatGeneratorParams{}, "hi-hat should render");
        expectChainOutput(audioapp::DeviceNodeKind::RideGenerator, 51,
                          audioapp::RideGeneratorParams{}, "ride should render");
        expectChainOutput(audioapp::DeviceNodeKind::TomGenerator, 45,
                          audioapp::TomGeneratorParams{}, "tom should render");
        expectChainOutput(audioapp::DeviceNodeKind::RimshotGenerator, 37,
                          audioapp::RimshotGeneratorParams{}, "rimshot should render");

        beginTest("all dedicated generators render live");
        constexpr int frames = 2048;
        for (int index = 0; index < 4; ++index) {
            audioapp::LiveInstrumentSnapshot instrument{};
            const int pitch[] = {42, 51, 45, 37};
            instrument.kind = static_cast<audioapp::LiveInstrumentKind>(
                static_cast<int>(audioapp::LiveInstrumentKind::HihatGenerator) + index);
            // Live enum keeps Crash between Hi-Hat and the other dedicated devices.
            if (index > 0) instrument.kind = static_cast<audioapp::LiveInstrumentKind>(
                static_cast<int>(audioapp::LiveInstrumentKind::RideGenerator) + index - 1);
            instrument.gain = 1.0f;
            audioapp::LivePerformanceMixer mixer;
            mixer.noteOn(instrument, pitch[index], 100.0f);
            float output[frames]{};
            mixer.readMix(output, frames, 48000.0);
            expect(audioapp::test::peakAbs(output, frames) > 0.001f,
                   "dedicated percussion live voice should render");
        }
    }
};

static DedicatedPercussionTest dedicatedPercussionTest;
