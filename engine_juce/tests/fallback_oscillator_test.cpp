#include <juce_core/juce_core.h>
#include "audioapp/FallbackPreviewOscillator.hpp"

#include <cmath>
#include <vector>

class FallbackOscillatorTest : public juce::UnitTest {
public:
    FallbackOscillatorTest() : juce::UnitTest("FallbackOscillator", "Engine") {}

    void runTest() override {
        beginTest("single note produces correct frequency");
        {
            audioapp::FallbackPreviewOscillator osc;
            constexpr int kNumSamples = 4800; // 100ms at 48kHz
            std::vector<float> buffer(kNumSamples, 0.0f);

            osc.noteOn(60, 100.0f, 0.0, 1.0);
            osc.processBlock(buffer.data(), kNumSamples, 48000.0, 0.0);

            // Verify output is not silent
            float peak = 0.0f;
            for (auto s : buffer) peak = std::max(peak, std::abs(s));
            expect(peak > 0.001f, "single note should produce non-zero output");

            // Rough frequency check via zero-crossings: MIDI 60 = 261.63 Hz
            int zeroCrossings = 0;
            for (int i = 1; i < 1000; ++i) {
                if ((buffer[i] >= 0.0f && buffer[i - 1] < 0.0f) ||
                    (buffer[i] < 0.0f && buffer[i - 1] >= 0.0f)) {
                    ++zeroCrossings;
                }
            }
            // ~261.63 Hz => ~5.45 half-cycles per 1000 samples at 48kHz
            // Each zero crossing is a half-cycle boundary, so expect ~10-11 crossings
            expect(zeroCrossings >= 5 && zeroCrossings <= 18,
                   "frequency should be approximately correct for MIDI 60 (=~261.63 Hz)");

            osc.allNotesOff();
        }

        beginTest("polyphonic 8 voices");
        {
            audioapp::FallbackPreviewOscillator osc;
            constexpr int kNumSamples = 4800;
            std::vector<float> buffer(kNumSamples, 0.0f);

            for (int i = 0; i < 8; ++i)
                osc.noteOn(60 + i, 100.0f, 0.0, 1.0);
            osc.processBlock(buffer.data(), kNumSamples, 48000.0, 0.0);

            float peak = 0.0f;
            for (auto s : buffer) peak = std::max(peak, std::abs(s));
            expect(peak > 0.001f, "8 voices should produce non-zero output");

            osc.allNotesOff();
        }

        beginTest("voice stealing");
        {
            audioapp::FallbackPreviewOscillator osc;
            constexpr int kNumSamples = 4800;
            std::vector<float> buffer(kNumSamples, 0.0f);

            // Start 9 notes (should steal oldest)
            for (int i = 0; i < 9; ++i)
                osc.noteOn(60 + i, 100.0f, 0.0, 1.0);
            osc.processBlock(buffer.data(), kNumSamples, 48000.0, 0.0);

            float peak = 0.0f;
            for (auto s : buffer) peak = std::max(peak, std::abs(s));
            expect(peak > 0.001f, "voice stealing should still produce output");

            osc.allNotesOff();
        }

        beginTest("allNotesOff produces silence");
        {
            audioapp::FallbackPreviewOscillator osc;
            constexpr int kNumSamples = 4800;
            std::vector<float> buffer(kNumSamples, 0.0f);

            osc.noteOn(60, 100.0f, 0.0, 1.0);
            osc.allNotesOff();
            osc.processBlock(buffer.data(), kNumSamples, 48000.0, 0.0);

            float peak = 0.0f;
            for (auto s : buffer) peak = std::max(peak, std::abs(s));
            expect(peak < 0.0001f, "allNotesOff should produce silence");
        }

        beginTest("zero voices produces silence");
        {
            audioapp::FallbackPreviewOscillator osc;
            constexpr int kNumSamples = 4800;
            std::vector<float> buffer(kNumSamples, 0.0f);

            osc.processBlock(buffer.data(), kNumSamples, 48000.0, 0.0);

            float peak = 0.0f;
            for (auto s : buffer) peak = std::max(peak, std::abs(s));
            expect(peak < 0.0001f, "no active voices should produce silence");
        }
    }
};

static FallbackOscillatorTest fallbackOscillatorTest;
