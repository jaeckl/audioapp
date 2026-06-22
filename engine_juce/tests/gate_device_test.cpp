#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "TestChainHelper.hpp"
#include "audioapp/DeviceChain.hpp"

class GateDeviceTest : public juce::UnitTest {
public:
    GateDeviceTest() : juce::UnitTest("GateDevice", "Dynamics") {}
    void runTest() override {
        constexpr int kFrames = 2048;
        constexpr double kSampleRate = 48000.0;

        beginTest("oscillator alone produces audio");
        {
            audioapp::DeviceNodePlayback osc{};
            osc.kind = audioapp::DeviceNodeKind::Oscillator;
            osc.gain = 1.0f;
            osc.pan = 0.5f;
            osc.params = audioapp::OscillatorParams{440.0f};

            float left[kFrames] = {};
            float right[kFrames] = {};

            audioapp::test::processTestChain(left, right, kFrames, kSampleRate, 120, 0.0, nullptr, 0, &osc, 1,
                                         false);

            const float peakOscOnly = audioapp::test::peakAbsStereo(left, right, kFrames);
            expect(peakOscOnly > 0.001f, "oscillator produces audio");
        }
        beginTest("closed gate attenuates signal");
        {
            audioapp::DeviceNodePlayback osc{};
            osc.kind = audioapp::DeviceNodeKind::Oscillator;
            osc.gain = 1.0f;
            osc.pan = 0.5f;
            osc.params = audioapp::OscillatorParams{440.0f};

            float left[kFrames] = {};
            float right[kFrames] = {};

            audioapp::test::processTestChain(left, right, kFrames, kSampleRate, 120, 0.0, nullptr, 0, &osc, 1,
                                         false);
            const float peakOscOnly = audioapp::test::peakAbsStereo(left, right, kFrames);

            audioapp::DeviceNodePlayback gate{};
            gate.kind = audioapp::DeviceNodeKind::Gate;
            gate.gain = 1.0f;
            gate.pan = 0.5f;
            audioapp::GateParams closedGate;
            closedGate.gateThreshold = 0.95f;
            closedGate.gateRange = 0.0f;
            gate.params = closedGate;

            audioapp::DeviceNodePlayback chain[2] = {osc, gate};
            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));

            audioapp::test::processTestChain(left, right, kFrames, kSampleRate, 120, 0.0, nullptr, 0, chain, 2,
                                         false);

            expect(audioapp::test::peakAbsStereo(left, right, kFrames) < peakOscOnly * 0.25f,
                   "closed gate attenuates");
        }
        beginTest("open gate passes signal");
        {
            audioapp::DeviceNodePlayback osc{};
            osc.kind = audioapp::DeviceNodeKind::Oscillator;
            osc.gain = 1.0f;
            osc.pan = 0.5f;
            osc.params = audioapp::OscillatorParams{440.0f};

            float left[kFrames] = {};
            float right[kFrames] = {};

            audioapp::test::processTestChain(left, right, kFrames, kSampleRate, 120, 0.0, nullptr, 0, &osc, 1,
                                         false);
            const float peakOscOnly = audioapp::test::peakAbsStereo(left, right, kFrames);

            audioapp::DeviceNodePlayback gate{};
            gate.kind = audioapp::DeviceNodeKind::Gate;
            gate.gain = 1.0f;
            gate.pan = 0.5f;
            audioapp::GateParams openGate;
            openGate.gateThreshold = 0.0f;
            openGate.gateRange = 1.0f;
            gate.params = openGate;

            audioapp::DeviceNodePlayback chain[2] = {osc, gate};
            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));
            audioapp::test::processTestChain(left, right, kFrames, kSampleRate, 120, 0.0, nullptr, 0, chain, 2,
                                         false);

            expect(audioapp::test::peakAbsStereo(left, right, kFrames) >= peakOscOnly * 0.5f,
                   "open gate passes signal");
        }
    }
};
static GateDeviceTest gateDeviceTest;