#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/transport/TransportController.hpp"

class TransportControllerTest : public juce::UnitTest {
public:
    TransportControllerTest() : juce::UnitTest("TransportController", "Engine") {}
    void runTest() override {
        beginTest("bpm bounds");
        {
            audioapp::TransportController transport;
            expect(!transport.setBpm(30), "bpm 30 out of range");
            expect(transport.setBpm(120), "bpm 120 in range");
            expect(!transport.setBpm(400), "bpm 400 out of range");
            expectEquals(transport.bpm(), 120);
        }
        beginTest("loop wrap with enabled loop");
        {
            audioapp::TransportController transport;
            transport.setBpm(120);
            expect(!transport.setLoopLengthBeats(0.5), "loop 0.5 too short");
            expect(transport.setLoopLengthBeats(4.0), "loop 4.0 ok");

            transport.setLoopEnabled(true);
            transport.setPlaying(true);
            transport.setPlayheadBeats(3.5);
            transport.advancePlayhead(48000, 48000.0);
            expectWithinAbsoluteError(transport.playheadBeats(), 1.5, 0.001);
        }
        beginTest("loop region wrap");
        {
            audioapp::TransportController transport;
            transport.setBpm(120);
            expect(transport.setLoopRegion(4.0, 8.0), "setLoopRegion ok");
            transport.setPlaying(true);
            transport.setPlayheadBeats(7.5);
            transport.advancePlayhead(48000, 48000.0);
            // 7.5 + 2.0 beats = 9.5, wrap to loop start 4.0 → 9.5 - 4.0 = 5.5
            expectWithinAbsoluteError(transport.playheadBeats(), 5.5, 0.001);
        }
        beginTest("reset clears state");
        {
            audioapp::TransportController transport;
            transport.setBpm(120);
            transport.setLoopEnabled(true);
            transport.setPlaying(true);
            transport.setPlayheadBeats(5.0);
            transport.reset();
            expect(!transport.isPlaying(), "not playing after reset");
            expectWithinAbsoluteError(transport.playheadBeats(), 0.0, 0.001);
            expectEquals(transport.bpm(), 120);
        }
        beginTest("no-loop advance");
        {
            audioapp::TransportController transport;
            transport.setBpm(120);
            transport.setPlaying(true);
            transport.setPlayheadBeats(2.0);
            transport.setLoopEnabled(false);
            transport.advancePlayhead(24000, 48000.0);
            expectWithinAbsoluteError(transport.playheadBeats(), 3.0, 0.001);
        }
    }
};
static TransportControllerTest transportControllerTest;