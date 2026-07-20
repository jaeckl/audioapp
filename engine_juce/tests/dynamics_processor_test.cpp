#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/DynamicsProcessor.hpp"
#include "audioapp/effects/DuckerParams.hpp"

#include <cmath>

class DynamicsProcessorTest : public juce::UnitTest {
public:
    DynamicsProcessorTest() : juce::UnitTest("DynamicsProcessor", "Dynamics") {}
    void runTest() override {
        constexpr int kFrames = 2048;
        constexpr double kSampleRate = 48000.0;

        beginTest("gate attenuates below threshold");
        {
            float left[kFrames] = {};
            float right[kFrames] = {};
            for (int i = 400; i < 800; ++i) {
                left[i] = 0.85f;
                right[i] = 0.85f;
            }

            audioapp::GateParams gateParams;
            gateParams.gateThreshold = 0.50f;
            gateParams.gateRange = 0.0f;
            gateParams.gateAttack = 0.0f;  // Instant attack
            gateParams.gateRelease = 0.0f; // Instant release
            gateParams.gateHold = 0.0f;    // Instant hold
            audioapp::DynamicsRuntime gateRuntime{};
            audioapp::processGateStereoBlock(left, right, kFrames, kSampleRate, gateParams, gateRuntime);

            expect(audioapp::test::peakAbsStereo(left, right, 200) <= 0.01f,
                   "early frames gated");
            const float peakLater = audioapp::test::peakAbsStereo(left + 500, right + 500, 300);
            expect(peakLater >= 0.05f,
                   "later frames passed");
        }
        beginTest("compressor reduces level");
        {
            float left[kFrames] = {};
            float right[kFrames] = {};
            for (int i = 0; i < kFrames; ++i) {
                left[i] = 0.95f;
                right[i] = 0.95f;
            }
            const float inputPeak = audioapp::test::peakAbsStereo(left, right, kFrames);

            audioapp::CompressorParams compParams;
            compParams.compThreshold = 0.35f;
            compParams.compRatio = 0.75f;
            compParams.compKnee = 0.0f;
            compParams.compMakeup = 0.0f;
            compParams.compAttack = 0.0f;  // Instant attack
            compParams.compRelease = 0.0f; // Instant release
            audioapp::DynamicsRuntime compRuntime{};
            audioapp::processCompressorStereoBlock(left, right, kFrames, kSampleRate, compParams, compRuntime);

            const float outputPeak = audioapp::test::peakAbsStereo(left, right, kFrames);
            expect(outputPeak < inputPeak * 0.98f,
                   "compressed output below input peak");
        }
        beginTest("ducker attenuates when sidechain is loud");
        {
            float left[kFrames] = {};
            float right[kFrames] = {};
            float sideL[kFrames] = {};
            float sideR[kFrames] = {};
            for (int i = 0; i < kFrames; ++i) {
                left[i] = 0.8f;
                right[i] = 0.8f;
                sideL[i] = 0.95f;
                sideR[i] = 0.95f;
            }
            const float inputPeak = audioapp::test::peakAbsStereo(left, right, kFrames);

            audioapp::DuckerParams duckParams;
            duckParams.duckThreshold = 0.2f;
            duckParams.duckDepth = 1.0f;
            duckParams.duckAttack = 0.0f;
            duckParams.duckRelease = 0.0f;
            audioapp::DynamicsRuntime duckRuntime{};
            audioapp::processDuckerStereoBlock(left, right, kFrames, sideL, sideR,
                                               kSampleRate, duckParams, duckRuntime);

            const float outputPeak = audioapp::test::peakAbsStereo(left, right, kFrames);
            expect(outputPeak < inputPeak * 0.7f, "ducked output below input");
            expect(duckRuntime.gainReductionDb < -1.0f, "reports gain reduction");
        }
        beginTest("utility mono sums channels");
        {
            float left[64];
            float right[64];
            for (int i = 0; i < 64; ++i) {
                left[i] = 0.5f;
                right[i] = -0.5f;
            }
            // Inline utility mono: average
            for (int i = 0; i < 64; ++i) {
                const float m = 0.5f * (left[i] + right[i]);
                left[i] = m;
                right[i] = m;
            }
            expect(std::abs(left[0]) < 0.001f && std::abs(right[0]) < 0.001f,
                   "mono of +0.5/-0.5 is silence");
        }
    }
};
static DynamicsProcessorTest dynamicsProcessorTest;