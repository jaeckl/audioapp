// Restore FX integration — automation apply, paramId strings, chain smoke.
#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "TestChainHelper.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

#include <cmath>
#include <cstring>
#include <utility>
#include <vector>

namespace {

bool allFinite(const float* l, const float* r, int n) {
    for (int i = 0; i < n; ++i)
        if (!std::isfinite(l[i]) || !std::isfinite(r[i]))
            return false;
    return true;
}

} // namespace

class RestoreFxIntegrationTest : public juce::UnitTest {
public:
    RestoreFxIntegrationTest()
        : juce::UnitTest("RestoreFxIntegration", "RestoreFx") {}

    void runTest() override {
        using namespace audioapp;

        beginTest("paramIdFromString encodes restore params");
        {
            expectEquals(paramIdFromString("dcMode", DeviceNodeKind::DcOffset),
                         packParamId(ParamKind::DcOffset,
                                     static_cast<uint16_t>(DcOffsetParam::Mode)));
            expectEquals(paramIdFromString("dcAmount", DeviceNodeKind::DcOffset),
                         packParamId(ParamKind::DcOffset,
                                     static_cast<uint16_t>(DcOffsetParam::Amount)));
            expectEquals(paramIdFromString("humMains", DeviceNodeKind::DeHum),
                         packParamId(ParamKind::DeHum,
                                     static_cast<uint16_t>(DeHumParam::MainsFreq)));
            expectEquals(paramIdFromString("crackSense", DeviceNodeKind::DeCrackler),
                         packParamId(ParamKind::DeCrackler,
                                     static_cast<uint16_t>(DeCracklerParam::Sensitivity)));
            expectEquals(paramIdFromString("deAmount", DeviceNodeKind::DeEsser),
                         packParamId(ParamKind::DeEsser,
                                     static_cast<uint16_t>(DeEsserParam::Amount)));
            expectEquals(paramIdFromString("dnReduce", DeviceNodeKind::DeNoise),
                         packParamId(ParamKind::DeNoise,
                                     static_cast<uint16_t>(DeNoiseParam::Reduction)));
        }

        beginTest("paramIdToString roundtrips restore params");
        {
            const auto id = paramIdFromString("dcMode", DeviceNodeKind::DcOffset);
            expect(std::strcmp(paramIdToString(id, DeviceNodeKind::DcOffset), "dcMode") == 0);
            const auto hum = paramIdFromString("humMains", DeviceNodeKind::DeHum);
            expect(std::strcmp(paramIdToString(hum, DeviceNodeKind::DeHum), "humMains") == 0);
        }

        beginTest("applyAutomationValue discrete modes and knobs");
        {
            {
                DeviceVariantParams v = DcOffsetParamsPlayback{};
                auto& p = std::get<DcOffsetParamsPlayback>(v);
                p.mode = 1.0f;
                p.amount = 1.0f;
                applyAutomationValue(v, DeviceNodeKind::DcOffset,
                                     packParamId(ParamKind::DcOffset,
                                                 static_cast<uint16_t>(DcOffsetParam::Mode)),
                                     0.0f);
                applyAutomationValue(v, DeviceNodeKind::DcOffset,
                                     packParamId(ParamKind::DcOffset,
                                                 static_cast<uint16_t>(DcOffsetParam::Amount)),
                                     0.25f);
                expectWithinAbsoluteError(p.mode, 0.0f, 0.001f, "dcMode automatable");
                expectWithinAbsoluteError(p.amount, 0.25f, 0.001f, "dcAmount automatable");
            }
            {
                DeviceVariantParams v = DeHumParamsPlayback{};
                auto& p = std::get<DeHumParamsPlayback>(v);
                p.mainsFreq = 0.0f;
                applyAutomationValue(v, DeviceNodeKind::DeHum,
                                     packParamId(ParamKind::DeHum,
                                                 static_cast<uint16_t>(DeHumParam::MainsFreq)),
                                     1.0f);
                applyAutomationValue(v, DeviceNodeKind::DeHum,
                                     packParamId(ParamKind::DeHum,
                                                 static_cast<uint16_t>(DeHumParam::Depth)),
                                     0.4f);
                expectWithinAbsoluteError(p.mainsFreq, 1.0f, 0.001f, "humMains automatable");
                expectWithinAbsoluteError(p.depth, 0.4f, 0.001f, "humDepth automatable");
            }
            {
                DeviceVariantParams v = DeEsserParamsPlayback{};
                auto& p = std::get<DeEsserParamsPlayback>(v);
                applyAutomationValue(v, DeviceNodeKind::DeEsser,
                                     packParamId(ParamKind::DeEsser,
                                                 static_cast<uint16_t>(DeEsserParam::Listen)),
                                     1.0f);
                expectWithinAbsoluteError(p.listen, 1.0f, 0.001f, "deListen automatable");
            }
        }

        beginTest("processTestChain osc + each restore device is finite");
        {
            constexpr int kFrames = 2048;
            constexpr double kSr = 48000.0;
            const auto registry = DeviceRegistry::createBuiltIn();
            const char* types[] = {
                device_types::kDcOffset, device_types::kDeCrackler,
                device_types::kDeEsser, device_types::kDeHum, device_types::kDeNoise,
            };
            for (const char* typeId : types) {
                float left[kFrames]{}, right[kFrames]{};
                DeviceNodePlayback devices[2]{};
                devices[0].kind = DeviceNodeKind::Oscillator;
                devices[0].gain = 1.0f;
                devices[0].pan = 0.5f;
                devices[0].params = OscillatorParams{440.0f};

                auto slot = registry.createDefault(typeId, std::string("fx-") + typeId);
                expect(!slot.id.empty(), typeId);
                registry.buildPlaybackNode(slot, PlaybackBuildContext{}, devices[1]);
                devices[1].gain = 1.0f;
                devices[1].pan = 0.5f;
                devices[1].bypassed = false;

                test::processTestChain(left, right, kFrames, kSr, 120, 0.0, nullptr, 0,
                                       devices, 2, false);
                expect(allFinite(left, right, kFrames), typeId);
                expect(test::peakAbsStereo(left, right, kFrames) > 0.01f, typeId);
            }
        }

        beginTest("processTestChain bypass vs active dc_offset");
        {
            constexpr int kFrames = 2048;
            constexpr double kSr = 48000.0;
            const auto registry = DeviceRegistry::createBuiltIn();

            auto makeChain = [&](bool bypassed, float gain) {
                DeviceNodePlayback devices[2]{};
                devices[0].kind = DeviceNodeKind::Oscillator;
                devices[0].gain = 1.0f;
                devices[0].pan = 0.5f;
                devices[0].params = OscillatorParams{220.0f};
                auto slot = registry.createDefault(device_types::kDcOffset, "dc");
                registry.buildPlaybackNode(slot, PlaybackBuildContext{}, devices[1]);
                devices[1].bypassed = bypassed;
                devices[1].gain = gain;
                devices[1].pan = 0.5f;
                float left[kFrames]{}, right[kFrames]{};
                test::processTestChain(left, right, kFrames, kSr, 120, 0.0, nullptr, 0,
                                       devices, 2, false);
                return test::peakAbsStereo(left, right, kFrames);
            };

            const float bypassed = makeChain(true, 1.0f);
            const float active = makeChain(false, 1.0f);
            const float muted = makeChain(false, 0.0f);
            expect(bypassed > 0.01f, "bypassed chain audible");
            expect(active > 0.01f, "active chain audible");
            expect(muted < active * 0.05f, "gain=0 silences after FX");
        }

        beginTest("processTestChain gain/pan on de_esser node");
        {
            constexpr int kFrames = 2048;
            constexpr double kSr = 48000.0;
            const auto registry = DeviceRegistry::createBuiltIn();

            auto peakAt = [&](float gain, float pan) {
                DeviceNodePlayback devices[2]{};
                devices[0].kind = DeviceNodeKind::Oscillator;
                devices[0].gain = 1.0f;
                devices[0].pan = 0.5f;
                devices[0].params = OscillatorParams{880.0f};
                auto slot = registry.createDefault(device_types::kDeEsser, "de");
                registry.buildPlaybackNode(slot, PlaybackBuildContext{}, devices[1]);
                devices[1].gain = gain;
                devices[1].pan = pan;
                float left[kFrames]{}, right[kFrames]{};
                test::processTestChain(left, right, kFrames, kSr, 120, 0.0, nullptr, 0,
                                       devices, 2, false);
                return std::pair{test::peakAbs(left, kFrames), test::peakAbs(right, kFrames)};
            };

            const auto center = peakAt(1.0f, 0.5f);
            const auto leftBias = peakAt(1.0f, 0.0f);
            expect(center.first > 0.01f && center.second > 0.01f, "center stereo");
            expect(leftBias.first > leftBias.second * 1.5f, "pan left biases L");
        }
    }
};

static RestoreFxIntegrationTest restoreFxIntegrationTest;
