#include "audioapp/TestOscillator.hpp"

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include <cmath>
#include <vector>

class OscillatorOutputTest : public juce::UnitTest {
public:
    OscillatorOutputTest() : juce::UnitTest("OscillatorOutput", "Audio") {}

    void runTest() override {
        audioapp::TestOscillator osc;

        constexpr int numSamples = 512;
        constexpr double sampleRate = 48000.0;
        std::vector<float> buffer(numSamples);

        beginTest("disabled oscillator should produce silence");
        {
            osc.setEnabled(false);
            osc.processBlock(buffer.data(), numSamples, sampleRate);
            const float peak = audioapp::test::peakAbs(buffer.data(), numSamples);
            expect(peak <= 1.0e-6f, "Disabled oscillator should produce near-zero output");
        }

        beginTest("enabled oscillator should produce audible signal");
        {
            osc.setFrequency(440.0f);
            osc.setEnabled(true);
            osc.processBlock(buffer.data(), numSamples, sampleRate);

            float sumSquares = 0.0f;
            for (float s : buffer)
                sumSquares += s * s;
            const float rms = std::sqrt(sumSquares / static_cast<float>(numSamples));
            expect(rms >= 0.01f, "Enabled oscillator should produce audible RMS level");
        }
    }
};

static OscillatorOutputTest oscillatorOutputTest;
