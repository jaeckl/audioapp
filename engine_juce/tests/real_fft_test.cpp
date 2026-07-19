#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/dsp/RealFft.hpp"

#include <cmath>
#include <vector>

namespace {

float maxAbsDiff(const float* a, const float* b, int n) {
    float m = 0.0f;
    for (int i = 0; i < n; ++i)
        m = std::max(m, std::abs(a[i] - b[i]));
    return m;
}

} // namespace

class RealFftTest : public juce::UnitTest {
public:
    RealFftTest() : juce::UnitTest("RealFft", "DSP") {}

    void runTest() override {
        beginTest("round-trip impulse ≈ identity (order 9)");
        {
            constexpr int kOrder = 9;
            constexpr int kSize = 1 << kOrder;
            audioapp::RealFft fft(kOrder);
            expect(fft.getSize() == kSize);

            std::vector<float> buf(static_cast<size_t>(kSize * 2), 0.0f);
            std::vector<float> original(static_cast<size_t>(kSize), 0.0f);
            buf[0] = 1.0f;
            original[0] = 1.0f;

            fft.forwardRealOnly(buf.data());
            fft.inverseRealOnly(buf.data());

            const float err = maxAbsDiff(buf.data(), original.data(), kSize);
            expect(err < 1.0e-4f, "impulse round-trip error too high");
        }

        beginTest("round-trip sine recovers time signal");
        {
            constexpr int kOrder = 9;
            constexpr int kSize = 1 << kOrder;
            audioapp::RealFft fft(kOrder);
            std::vector<float> buf(static_cast<size_t>(kSize * 2), 0.0f);
            std::vector<float> original(static_cast<size_t>(kSize), 0.0f);
            for (int i = 0; i < kSize; ++i) {
                const float s =
                    0.5f * std::sin(2.0f * 3.14159265f * 8.0f * static_cast<float>(i) /
                                    static_cast<float>(kSize));
                buf[static_cast<size_t>(i)] = s;
                original[static_cast<size_t>(i)] = s;
            }
            fft.forwardRealOnly(buf.data());
            fft.inverseRealOnly(buf.data());
            const float err = maxAbsDiff(buf.data(), original.data(), kSize);
            expect(err < 1.0e-3f, "sine round-trip error too high");
        }

        beginTest("DC packs into bin 0");
        {
            constexpr int kOrder = 8;
            constexpr int kSize = 1 << kOrder;
            audioapp::RealFft fft(kOrder);
            std::vector<float> buf(static_cast<size_t>(kSize * 2), 0.0f);
            for (int i = 0; i < kSize; ++i)
                buf[static_cast<size_t>(i)] = 0.25f;
            fft.forwardRealOnly(buf.data());
            expect(std::abs(buf[0]) > 1.0f, "DC real should be large");
            float maxBin = 0.0f;
            for (int k = 1; k < kSize / 2; ++k) {
                maxBin = std::max(maxBin, std::abs(buf[2 * k]));
                maxBin = std::max(maxBin, std::abs(buf[2 * k + 1]));
            }
            expect(maxBin < 1.0e-2f, "pure DC should not leak into mid bins");
        }
    }
};

static RealFftTest realFftTest;
