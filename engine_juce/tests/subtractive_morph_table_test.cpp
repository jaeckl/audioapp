#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/SubtractiveMorphTable.hpp"

#include <cmath>

class SubtractiveMorphTableTest : public juce::UnitTest {
public:
    SubtractiveMorphTableTest() : juce::UnitTest("SubtractiveMorphTable", "Audio") {}

    void runTest() override {
        using audioapp::SubtractiveMorphTable;

        beginTest("mips shrink with rising Hz");
        {
            const auto& table = SubtractiveMorphTable::instance();
            const int low = table.pickMip(55.0f, 48000.0f);
            const int mid = table.pickMip(220.0f, 48000.0f);
            const int high = table.pickMip(2000.0f, 48000.0f);
            expect(low <= mid, "low Hz uses same or longer table than mid");
            expect(mid <= high, "mid Hz uses same or longer table than high");
            expect(table.lengthForMip(low) >= table.lengthForMip(high),
                   "higher mip is shorter");
        }

        beginTest("lookup audible across morph axis");
        {
            const auto& table = SubtractiveMorphTable::instance();
            float peak = 0.0f;
            for (int i = 0; i < 64; ++i) {
                const float shape = static_cast<float>(i) / 63.0f;
                const float phase = 6.28318530718f * static_cast<float>(i) / 64.0f;
                peak = std::max(peak, std::abs(table.lookup(shape, phase, 220.0f, 48000.0f)));
            }
            expect(peak > 0.1f, "morph table produces signal");
        }

        beginTest("frame endpoints stable");
        {
            const auto& table = SubtractiveMorphTable::instance();
            const float a = table.lookup(0.0f, 0.0f, 110.0f, 48000.0f);
            const float b = table.lookup(0.0f, 0.0f, 110.0f, 48000.0f);
            expectWithinAbsoluteError(a, b, 1.0e-6f, "deterministic lookup");
        }
    }
};

static SubtractiveMorphTableTest subtractiveMorphTableTest;
