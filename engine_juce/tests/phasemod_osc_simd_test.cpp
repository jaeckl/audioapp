#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/PhaseModOscSimd.hpp"
#include "audioapp/PhaseModSynthAlgorithm.hpp"

#include <cmath>
#include <cstring>
#include <vector>

using namespace audioapp;

namespace {

constexpr float kTwoPi = 6.28318530718f;

float morphWaveScalar(float shape, float phase) noexcept {
    const float scaled = std::clamp(shape, 0.0f, 1.0f) * 4.0f;
    const int i0 = std::min(4, static_cast<int>(scaled));
    const int i1 = std::min(4, i0 + 1);
    const float t = scaled - static_cast<float>(i0);
    auto wave = [](int w, float p) {
        const float wrapped = std::fmod(p, kTwoPi);
        switch (w) {
        case 0: return std::sin(wrapped);
        case 1: {
            const float tt = wrapped / 3.14159265358979323846f;
            return tt <= 1.0f ? (2.0f * tt - 1.0f) : (3.0f - 2.0f * tt);
        }
        case 2: return (1.0f / 3.14159265358979323846f) * (wrapped - 3.14159265358979323846f);
        case 3: return wrapped < 3.14159265358979323846f ? 1.0f : -1.0f;
        default: return wrapped < 3.14159265358979323846f ? 1.0f : -0.2f;
        }
    };
    const float a = wave(i0, phase);
    if (i0 == i1 || t <= 0.0f) return a;
    return a * (1.0f - t) + wave(i1, phase) * t;
}

} // namespace

class PhaseModOscSimdTest : public juce::UnitTest {
public:
    PhaseModOscSimdTest() : juce::UnitTest("PhaseModOscSimd", "Audio") {}

    void runTest() override {
        beginTest("SIMD unison op matches scalar reference");
        {
            const float shapes[] = {0.0f, 0.25f, 0.5f, 0.75f, 1.0f};
            for (float shape : shapes) {
                for (int unisonCount : {1, 2, 3, 4}) {
                    float phases[kPhaseModMaxUnison]{};
                    float scalarPhases[kPhaseModMaxUnison]{};
                    float incs[kPhaseModMaxUnison]{};
                    float mods[kPhaseModMaxUnison]{};
                    float simdOut[kPhaseModMaxUnison]{};
                    float scalarOut[kPhaseModMaxUnison]{};
                    for (int u = 0; u < unisonCount; ++u) {
                        phases[u] = 0.3f * static_cast<float>(u + 1);
                        scalarPhases[u] = phases[u];
                        incs[u] = 0.00015f * (1.0f + 0.02f * static_cast<float>(u));
                        mods[u] = 0.05f * static_cast<float>(u);
                    }

                    const float opHz = 220.0f;
                    const float level = 0.8f;
                    const bool ok = renderPhaseModUnisonOpSimd(
                        shape, level, opHz, incs, phases, mods, unisonCount, simdOut);
                    expect(ok, "SIMD path available");
                    if (!ok) continue;

                    for (int u = 0; u < unisonCount; ++u) {
                        scalarPhases[u] += opHz * incs[u];
                        if (scalarPhases[u] >= kTwoPi) {
                            scalarPhases[u] -= kTwoPi;
                        }
                        scalarOut[u] =
                            morphWaveScalar(shape, scalarPhases[u] + mods[u]) * level;
                        expectWithinAbsoluteError(
                            phases[u], scalarPhases[u], 1.0e-5f,
                            juce::String("phase u=") + juce::String(u));
                        expectWithinAbsoluteError(
                            simdOut[u], scalarOut[u], 1.0e-4f,
                            juce::String("sample u=") + juce::String(u));
                    }
                }
            }
        }

        beginTest("max-unison voice render audible");
        {
            PhaseModSynthParams params;
            params.unisonVoices = 1.0f;
            params.unisonDetune = 0.6f;
            params.operators[0].level = 1.0f;
            params.operators[0].ratio = 1.0f;
            params.filterCutoff = 0.7f;
            PhaseModSynthMidiNoteRegion notes[] = {
                {60, 0, 0.0, 4.0, 0.0, 4.0, 100.0f, false, 4.0},
            };
            PhaseModSynthRuntime runtime{};
            constexpr int kFrames = 1024;
            std::vector<float> out(static_cast<size_t>(kFrames), 0.0f);
            mixPhaseModMidiNotesBlock(out.data(), kFrames, 48000.0, 120, 0.0, notes, 1, params,
                                      runtime);
            expect(audioapp::test::peakAbs(out.data(), kFrames) > 1.0e-4f);
        }
    }
};

static PhaseModOscSimdTest phaseModOscSimdTest;
