#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/LivePerformance.hpp"
#include "audioapp/SubtractiveSynth.hpp"
#include "audioapp/devices/BassSynthDeviceType.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/devices/instances/BassSynthModel.hpp"

#include <cmath>

namespace {

bool near(float a, float b) {
    return std::abs(a - b) < 0.001f;
}

} // namespace

class BassSynthTest : public juce::UnitTest {
public:
    BassSynthTest() : juce::UnitTest("BassSynth", "Synth") {}
    void runTest() override {
        beginTest("DefaultInstance");
        {
            audioapp::BassSynthDeviceType type;
            auto slot = type.createDefault("test-id");

            expect(slot.id == "test-id", "slot.id == test-id");
            expect(std::holds_alternative<audioapp::BassSynthModel>(slot.config.instance),
                   "slot holds BassSynthModel");

            const auto& inst = std::get<audioapp::BassSynthModel>(slot.config.instance);
            expectWithinAbsoluteError(inst.gain, 1.0f, 0.001f);
            expectWithinAbsoluteError(inst.oscShape, 0.3f, 0.001f);
            expectWithinAbsoluteError(inst.subMix, 0.5f, 0.001f);
            expect(inst.subOctave == 0, "subOctave == 0");
            expectWithinAbsoluteError(inst.noise, 0.0f, 0.001f);
            expectWithinAbsoluteError(inst.ampAttack, 0.02f, 0.001f);
            expectWithinAbsoluteError(inst.ampSustain, 0.8f, 0.001f);
            expectWithinAbsoluteError(inst.ampRelease, 0.35f, 0.001f);
            expect(inst.octave == 2, "octave == 2");
            expectWithinAbsoluteError(inst.filterCutoff, 0.85f, 0.001f);
            expectWithinAbsoluteError(inst.filterResonance, 0.25f, 0.001f);
            expectWithinAbsoluteError(inst.filterEnvAmount, 0.6f, 0.001f);
            expectWithinAbsoluteError(inst.filterDecay, 0.4f, 0.001f);
            expectWithinAbsoluteError(inst.drive, 0.0f, 0.001f);
            expectWithinAbsoluteError(inst.squash, 0.0f, 0.001f);
            expectWithinAbsoluteError(inst.glideMs, 0.0f, 0.001f);
            expectWithinAbsoluteError(inst.velocitySense, 1.0f, 0.001f);
        }

        beginTest("SetParameter");
        {
            audioapp::BassSynthDeviceType type;
            auto slot = type.createDefault("set-id");

            {
                auto r = type.setParameter(slot, "gain", 0.7f);
                expect(r.handled, "setParameter gain handled");
                expectWithinAbsoluteError(std::get<audioapp::StereoOutputPanel>(slot.config.outputPanel).gain, 0.7f, 0.001f);
            }
            {
                auto r = type.setParameter(slot, "pan", 0.3f);
                expect(r.handled, "setParameter pan handled");
                expectWithinAbsoluteError(std::get<audioapp::StereoOutputPanel>(slot.config.outputPanel).pan, 0.3f, 0.001f);
            }
            {
                auto r = type.setParameter(slot, "bypass", 1.0f);
                expect(r.handled, "setParameter bypass handled");
                expect(slot.config.bypassed, "bypassed == true");
            }

            auto& inst = std::get<audioapp::BassSynthModel>(slot.config.instance);

            auto r1 = type.setParameter(slot, "bassOscShape", 0.7f);
            expect(r1.handled, "bassOscShape handled");
            expectWithinAbsoluteError(inst.oscShape, 0.7f, 0.001f);

            auto r2 = type.setParameter(slot, "bassSubMix", 0.2f);
            expect(r2.handled, "bassSubMix handled");
            expectWithinAbsoluteError(inst.subMix, 0.2f, 0.001f);

            auto r3 = type.setParameter(slot, "bassSubOctave", 1.0f);
            expect(r3.handled, "bassSubOctave handled");
            expect(inst.subOctave == 1, "subOctave == 1");

            auto r4 = type.setParameter(slot, "bassNoise", 0.3f);
            expect(r4.handled, "bassNoise handled");
            expectWithinAbsoluteError(inst.noise, 0.3f, 0.001f);

            auto r5 = type.setParameter(slot, "attack", 0.1f);
            expect(r5.handled, "attack handled");
            expectWithinAbsoluteError(inst.ampAttack, 0.1f, 0.001f);

            auto r6 = type.setParameter(slot, "sustain", 0.5f);
            expect(r6.handled, "sustain handled");
            expectWithinAbsoluteError(inst.ampSustain, 0.5f, 0.001f);

            auto r7 = type.setParameter(slot, "release", 0.6f);
            expect(r7.handled, "release handled");
            expectWithinAbsoluteError(inst.ampRelease, 0.6f, 0.001f);

            auto r8 = type.setParameter(slot, "bassOctave", 3.0f);
            expect(r8.handled, "bassOctave handled");
            expect(inst.octave == 3, "octave == 3");

            auto r9 = type.setParameter(slot, "filterCutoff", 0.4f);
            expect(r9.handled, "filterCutoff handled");
            expectWithinAbsoluteError(inst.filterCutoff, 0.4f, 0.001f);

            auto r10 = type.setParameter(slot, "bassFilterResonance", 0.8f);
            expect(r10.handled, "bassFilterResonance handled");
            expectWithinAbsoluteError(inst.filterResonance, 0.8f, 0.001f);

            auto r11 = type.setParameter(slot, "filterEnvAmount", 0.3f);
            expect(r11.handled, "filterEnvAmount handled");
            expectWithinAbsoluteError(inst.filterEnvAmount, 0.3f, 0.001f);

            auto r12 = type.setParameter(slot, "filterDecay", 0.7f);
            expect(r12.handled, "filterDecay handled");
            expectWithinAbsoluteError(inst.filterDecay, 0.7f, 0.001f);

            auto r13 = type.setParameter(slot, "bassDrive", 0.6f);
            expect(r13.handled, "bassDrive handled");
            expectWithinAbsoluteError(inst.drive, 0.6f, 0.001f);

            auto r14 = type.setParameter(slot, "bassSquash", 0.9f);
            expect(r14.handled, "bassSquash handled");
            expectWithinAbsoluteError(inst.squash, 0.9f, 0.001f);

            auto r15 = type.setParameter(slot, "glideMs", 0.4f);
            expect(r15.handled, "glideMs handled");
            expectWithinAbsoluteError(inst.glideMs, 0.4f, 0.001f);

            auto r16 = type.setParameter(slot, "bassVelocitySense", 0.5f);
            expect(r16.handled, "bassVelocitySense handled");
            expectWithinAbsoluteError(inst.velocitySense, 0.5f, 0.001f);

            auto rUnknown = type.setParameter(slot, "nonexistent", 1.0f);
            expect(!rUnknown.handled, "unknown param not handled");
        }

        beginTest("SetParameterClamping");
        {
            audioapp::BassSynthDeviceType type;
            auto slot = type.createDefault("clamp-id");
            auto& inst = std::get<audioapp::BassSynthModel>(slot.config.instance);

            type.setParameter(slot, "bassOscShape", 1.5f);
            expectWithinAbsoluteError(inst.oscShape, 1.0f, 0.001f,
                                      "bassOscShape 1.5 clamped to 1.0");
            type.setParameter(slot, "bassOscShape", -0.5f);
            expectWithinAbsoluteError(inst.oscShape, 0.0f, 0.001f,
                                      "bassOscShape -0.5 clamped to 0.0");

            type.setParameter(slot, "bassSubOctave", 5.0f);
            expect(inst.subOctave == 2, "bassSubOctave 5 clamped to 2");
            type.setParameter(slot, "bassSubOctave", -1.0f);
            expect(inst.subOctave == 0, "bassSubOctave -1 clamped to 0");

            type.setParameter(slot, "bassOctave", 10.0f);
            expect(inst.octave == 4, "bassOctave 10 clamped to 4");
            type.setParameter(slot, "bassOctave", -5.0f);
            expect(inst.octave == 0, "bassOctave -5 clamped to 0");

            type.setParameter(slot, "bassVelocitySense", 2.0f);
            expectWithinAbsoluteError(inst.velocitySense, 1.0f, 0.001f,
                                      "bassVelocitySense 2.0 clamped to 1.0");
            type.setParameter(slot, "bassVelocitySense", -0.2f);
            expectWithinAbsoluteError(inst.velocitySense, 0.0f, 0.001f,
                                      "bassVelocitySense -0.2 clamped to 0.0");
        }

        beginTest("BuildPlaybackNode");
        {
            audioapp::BassSynthDeviceType type;
            auto slot = type.createDefault("pb-id");

            type.setParameter(slot, "bassOscShape", 0.7f);
            type.setParameter(slot, "bassSubMix", 0.25f);
            type.setParameter(slot, "bassDrive", 0.5f);
            type.setParameter(slot, "filterCutoff", 0.4f);

            audioapp::DeviceNodePlayback out{};
            audioapp::PlaybackBuildContext ctx{};
            type.buildPlaybackNode(slot, ctx, out);

            expect(out.kind == audioapp::DeviceNodeKind::BassSynth,
                   "out.kind == BassSynth");
            expect(std::holds_alternative<audioapp::SubtractiveSynthParams>(out.params),
                   "out.params holds SubtractiveSynthParams");

            const auto& sp = std::get<audioapp::SubtractiveSynthParams>(out.params);
            expect(sp.filterMode == 0, "filterMode == 0 (LP12)");
            expectWithinAbsoluteError(sp.synthMono, 1.0f, 0.001f);
            expectWithinAbsoluteError(sp.synthLegato, 1.0f, 0.001f);
            expect(sp.oscMixMode == 0, "oscMixMode == 0");
            expectWithinAbsoluteError(sp.filterSustain, 0.0f, 0.001f,
                                      "filterSustain == 0.0 (ADR)");

            expectWithinAbsoluteError(sp.osc1Shape, 0.7f, 0.001f,
                                      "osc1Shape == 0.7 (from oscShape)");
            expectWithinAbsoluteError(sp.oscMix, 0.25f, 0.001f,
                                      "oscMix == 0.25 (from subMix)");
            expectWithinAbsoluteError(sp.filterCutoff, 0.4f, 0.001f);
            expectWithinAbsoluteError(sp.filterDrive, 0.5f, 0.001f,
                                      "filterDrive == 0.5 (from drive)");
            expectWithinAbsoluteError(sp.preDrive, 0.25f, 0.001f,
                                      "preDrive == 0.25 (drive*0.5)");
            expectWithinAbsoluteError(sp.osc2Shape, 0.0f, 0.001f,
                                      "osc2Shape == 0.0 (force sine)");
            expectWithinAbsoluteError(sp.ampAttack, 0.02f, 0.001f,
                                      "ampAttack == 0.02 (default)");
            expectWithinAbsoluteError(sp.glideMs, 0.0f, 0.001f,
                                      "glideMs == 0.0 (default)");
        }

        beginTest("BuildPlaybackNodeMapping");
        {
            audioapp::BassSynthDeviceType type;
            audioapp::PlaybackBuildContext ctx{};

            // bassOscShape = 0.0f => osc1Shape = 0.0f
            {
                auto slot = type.createDefault("m1");
                type.setParameter(slot, "bassOscShape", 0.0f);
                audioapp::DeviceNodePlayback out{};
                type.buildPlaybackNode(slot, ctx, out);
                const auto& sp = std::get<audioapp::SubtractiveSynthParams>(out.params);
                expectWithinAbsoluteError(sp.osc1Shape, 0.0f, 0.001f,
                                          "bassOscShape 0 -> osc1Shape 0");
            }
            // bassOscShape = 1.0f => osc1Shape = 1.0f
            {
                auto slot = type.createDefault("m2");
                type.setParameter(slot, "bassOscShape", 1.0f);
                audioapp::DeviceNodePlayback out{};
                type.buildPlaybackNode(slot, ctx, out);
                const auto& sp = std::get<audioapp::SubtractiveSynthParams>(out.params);
                expectWithinAbsoluteError(sp.osc1Shape, 1.0f, 0.001f,
                                          "bassOscShape 1 -> osc1Shape 1");
            }
            // bassSubMix = 0.25f => oscMix = 0.25f
            {
                auto slot = type.createDefault("m3");
                type.setParameter(slot, "bassSubMix", 0.25f);
                audioapp::DeviceNodePlayback out{};
                type.buildPlaybackNode(slot, ctx, out);
                const auto& sp = std::get<audioapp::SubtractiveSynthParams>(out.params);
                expectWithinAbsoluteError(sp.oscMix, 0.25f, 0.001f,
                                          "bassSubMix 0.25 -> oscMix 0.25");
            }
            // bassDrive = 0.5f => filterDrive = 0.5f, preDrive = 0.25f
            {
                auto slot = type.createDefault("m4");
                type.setParameter(slot, "bassDrive", 0.5f);
                audioapp::DeviceNodePlayback out{};
                type.buildPlaybackNode(slot, ctx, out);
                const auto& sp = std::get<audioapp::SubtractiveSynthParams>(out.params);
                expectWithinAbsoluteError(sp.filterDrive, 0.5f, 0.001f,
                                          "bassDrive 0.5 -> filterDrive 0.5");
                expectWithinAbsoluteError(sp.preDrive, 0.25f, 0.001f,
                                          "bassDrive 0.5 -> preDrive 0.25");
            }
            // bassSquash = 0.7f => mixFeedback = 0.7f
            {
                auto slot = type.createDefault("m5");
                type.setParameter(slot, "bassSquash", 0.7f);
                audioapp::DeviceNodePlayback out{};
                type.buildPlaybackNode(slot, ctx, out);
                const auto& sp = std::get<audioapp::SubtractiveSynthParams>(out.params);
                expectWithinAbsoluteError(sp.mixFeedback, 0.7f, 0.001f,
                                          "bassSquash 0.7 -> mixFeedback 0.7");
            }
            // octave = 0 => globalPitch = 0.0f
            {
                auto slot = type.createDefault("m6");
                type.setParameter(slot, "bassOctave", 0.0f);
                audioapp::DeviceNodePlayback out{};
                type.buildPlaybackNode(slot, ctx, out);
                const auto& sp = std::get<audioapp::SubtractiveSynthParams>(out.params);
                expectWithinAbsoluteError(sp.globalPitch, 0.0f, 0.001f,
                                          "octave 0 -> globalPitch 0.0");
            }
            // octave = 4 => globalPitch = 0.5f
            {
                auto slot = type.createDefault("m7");
                type.setParameter(slot, "bassOctave", 4.0f);
                audioapp::DeviceNodePlayback out{};
                type.buildPlaybackNode(slot, ctx, out);
                const auto& sp = std::get<audioapp::SubtractiveSynthParams>(out.params);
                expectWithinAbsoluteError(sp.globalPitch, 0.5f, 0.001f,
                                          "octave 4 -> globalPitch 0.5");
            }
            // subOctave = 0 => osc2Shape = 0.0f (always force sine)
            {
                auto slot = type.createDefault("m8");
                type.setParameter(slot, "bassSubOctave", 0.0f);
                audioapp::DeviceNodePlayback out{};
                type.buildPlaybackNode(slot, ctx, out);
                const auto& sp = std::get<audioapp::SubtractiveSynthParams>(out.params);
                expectWithinAbsoluteError(sp.osc2Shape, 0.0f, 0.001f,
                                          "subOctave 0 -> osc2Shape 0.0 (force sine)");
            }
        }

        beginTest("BuildLiveInstrument");
        {
            audioapp::BassSynthDeviceType type;
            auto slot = type.createDefault("live-id");
            type.setParameter(slot, "bassOscShape", 0.6f);
            std::get<audioapp::StereoOutputPanel>(slot.config.outputPanel).gain = 0.8f;

            audioapp::LiveInstrumentSnapshot out{};
            audioapp::PlaybackBuildContext ctx{};
            bool result = type.buildLiveInstrument(slot, ctx, out);

            expect(result, "buildLiveInstrument returned true");
            expect(out.kind == audioapp::LiveInstrumentKind::BassSynth,
                   "out.kind == BassSynth");
            expectWithinAbsoluteError(out.subtractive.osc1Shape, 0.6f, 0.001f);
            expectWithinAbsoluteError(out.subtractive.gain, 0.8f, 0.001f,
                                      "subtractive.gain == 0.8 (output gain)");
            expectWithinAbsoluteError(out.subtractive.ampAttack, 0.02f, 0.001f);
            expectWithinAbsoluteError(out.subtractive.synthMono, 1.0f, 0.001f);
            expectWithinAbsoluteError(out.subtractive.synthLegato, 1.0f, 0.001f);
            expectWithinAbsoluteError(out.subtractive.glideMs, 0.0f, 0.001f);
        }

        beginTest("ModulatableParams");
        {
            audioapp::BassSynthDeviceType type;
            auto params = type.modulatableParams();

            expect(params.size() >= 18, "at least 18 modulatable params");

            auto contains = [&](const std::string_view& name) {
                for (const auto& p : params) {
                    if (p == name) return true;
                }
                return false;
            };

            expect(contains("gain"), "contains gain");
            expect(contains("bassOscShape"), "contains bassOscShape");
            expect(contains("filterCutoff"), "contains filterCutoff");
            expect(contains("bassDrive"), "contains bassDrive");
            expect(contains("bassSubMix"), "contains bassSubMix");
            expect(contains("bassNoise"), "contains bassNoise");
            expect(contains("bassFilterResonance"), "contains bassFilterResonance");
            expect(contains("filterEnvAmount"), "contains filterEnvAmount");
            expect(contains("filterDecay"), "contains filterDecay");
            expect(contains("attack"), "contains attack");
            expect(contains("sustain"), "contains sustain");
            expect(contains("release"), "contains release");
            expect(contains("bassSquash"), "contains bassSquash");
            expect(contains("glideMs"), "contains glideMs");
            expect(contains("bassVelocitySense"), "contains bassVelocitySense");
            expect(contains("bassOctave"), "contains bassOctave");
            expect(contains("bassSubOctave"), "contains bassSubOctave");
            expect(contains("pan"), "contains pan");
        }

        beginTest("SetStringParameter");
        {
            audioapp::BassSynthDeviceType type;
            auto slot = type.createDefault("str-id");
            audioapp::PlaybackBuildContext ctx{};

            bool result = type.setStringParameter(slot, "anything", "value", ctx);
            expect(!result, "setStringParameter returns false");

            result = type.setStringParameter(slot, "", "", ctx);
            expect(!result, "setStringParameter empty strings returns false");
        }

        beginTest("DeviceRegistryIntegration");
        {
            auto registry = audioapp::DeviceRegistry::createBuiltIn();

            const auto* type = registry.find("bass_synth");
            expect(type != nullptr, "registry.find(bass_synth) != nullptr");
            expect(registry.isKnownType("bass_synth"),
                   "registry.isKnownType(bass_synth)");

            auto slot = registry.createDefault("bass_synth", "reg-id");
            expect(std::holds_alternative<audioapp::BassSynthModel>(slot.config.instance),
                   "registry slot holds BassSynthModel");
            expect(slot.id == "reg-id", "registry slot.id == reg-id");

            const auto& inst = std::get<audioapp::BassSynthModel>(slot.config.instance);
            expectWithinAbsoluteError(inst.oscShape, 0.3f, 0.001f,
                                      "registry default oscShape == 0.3");

            registry.setParameter(slot, "bassOscShape", 0.9f);
            expectWithinAbsoluteError(inst.oscShape, 0.9f, 0.001f,
                                      "registry setParameter oscShape == 0.9");

            {
                const auto json = audioapp::deviceSlotToVar(slot, registry);
                const auto restored = audioapp::deviceVarToSlot(json, registry);
                expect(std::holds_alternative<audioapp::BassSynthModel>(restored.config.instance),
                       "restored holds BassSynthModel");
                expect(restored.id == "reg-id", "restored id preserved");
                const auto& ri = std::get<audioapp::BassSynthModel>(restored.config.instance);
                expectWithinAbsoluteError(ri.oscShape, 0.9f, 0.001f,
                                          "restored oscShape == 0.9");
            }

            audioapp::DeviceNodePlayback pbOut{};
            audioapp::PlaybackBuildContext ctx{};
            registry.buildPlaybackNode(slot, ctx, pbOut);
            expect(pbOut.kind == audioapp::DeviceNodeKind::BassSynth,
                   "registry pbOut.kind == BassSynth");

            audioapp::LiveInstrumentSnapshot liOut{};
            bool liResult = registry.buildLiveInstrument(slot, ctx, liOut);
            expect(liResult, "registry buildLiveInstrument returned true");
            expect(liOut.kind == audioapp::LiveInstrumentKind::BassSynth,
                   "registry liOut.kind == BassSynth");

            auto modParams = registry.modulatableParams("bass_synth");
            expect(modParams.size() >= 16,
                   "registry modulatableParams >= 16 entries");
        }
    }
};
static BassSynthTest bassSynthTest;