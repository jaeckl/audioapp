#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceState.hpp"
#include "audioapp/LivePerformance.hpp"
#include "audioapp/SubtractiveSynth.hpp"
#include "audioapp/devices/BassSynthDeviceType.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceSlot.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/devices/instances/BassSynthInstance.hpp"

#include <cassert>
#include <cmath>
#include <cstdlib>
#include <iostream>

namespace {

void check(bool condition, const char* msg) {
    if (!condition) {
        std::cout << "FAIL: " << msg << "\n";
        std::exit(1);
    }
    std::cout << "  PASS: " << msg << "\n";
}

bool near(float a, float b) {
    return std::abs(a - b) < 0.001f;
}

// ── Test 1: DefaultInstance ──
// Verify that createDefault produces a slot with the expected default values.
void testDefaultInstance() {
    std::cout << "\n[Test 1] DefaultInstance\n";

    audioapp::BassSynthDeviceType type;
    auto slot = type.createDefault("test-id");

    check(slot.id == "test-id", "slot.id == test-id");
    check(std::holds_alternative<audioapp::BassSynthInstance>(slot.instance),
          "slot holds BassSynthInstance");

    const auto& inst = std::get<audioapp::BassSynthInstance>(slot.instance);
    check(near(inst.gain, 1.0f), "gain == 1.0");
    check(near(inst.oscShape, 0.3f), "oscShape == 0.3");
    check(near(inst.subMix, 0.5f), "subMix == 0.5");
    check(inst.subOctave == 0, "subOctave == 0");
    check(near(inst.noise, 0.0f), "noise == 0.0");
    check(near(inst.ampAttack, 0.02f), "ampAttack == 0.02");
    check(near(inst.ampSustain, 0.8f), "ampSustain == 0.8");
    check(near(inst.ampRelease, 0.35f), "ampRelease == 0.35");
    check(inst.octave == 2, "octave == 2");
    check(near(inst.filterCutoff, 0.85f), "filterCutoff == 0.85");
    check(near(inst.filterResonance, 0.25f), "filterResonance == 0.25");
    check(near(inst.filterEnvAmount, 0.6f), "filterEnvAmount == 0.6");
    check(near(inst.filterDecay, 0.4f), "filterDecay == 0.4");
    check(near(inst.drive, 0.0f), "drive == 0.0");
    check(near(inst.squash, 0.0f), "squash == 0.0");
    check(near(inst.glideMs, 0.0f), "glideMs == 0.0");
    check(near(inst.velocitySense, 1.0f), "velocitySense == 1.0");
}

// ── Test 2: ToSnapshotRoundtrip ──
// Serialize a default slot to DeviceState and back; verify all fields survive.
void testToSnapshotRoundtrip() {
    std::cout << "\n[Test 2] ToSnapshotRoundtrip\n";

    audioapp::BassSynthDeviceType type;
    auto slot = type.createDefault("roundtrip-id");
    const auto& orig = std::get<audioapp::BassSynthInstance>(slot.instance);

    audioapp::DeviceState state = type.toSnapshotState(slot);
    check(state.type == audioapp::device_types::kBasSynth,
          "state.type == bass_synth");
    check(state.id == "roundtrip-id", "state.id preserved");
    check(near(state.bassOscShape, orig.oscShape), "state.bassOscShape");
    check(near(state.bassSubMix, orig.subMix), "state.bassSubMix");
    check(state.bassSubOctave == orig.subOctave, "state.bassSubOctave");
    check(near(state.bassNoise, orig.noise), "state.bassNoise");
    check(near(state.attack, orig.ampAttack), "state.attack (ampAttack)");
    check(near(state.sustain, orig.ampSustain), "state.sustain (ampSustain)");
    check(near(state.release, orig.ampRelease), "state.release (ampRelease)");
    check(state.bassOctave == orig.octave, "state.bassOctave");
    check(near(state.filterCutoff, orig.filterCutoff), "state.filterCutoff");
    check(near(state.bassFilterResonance, orig.filterResonance),
          "state.bassFilterResonance");
    check(near(state.filterEnvAmount, orig.filterEnvAmount),
          "state.filterEnvAmount");
    check(near(state.filterDecay, orig.filterDecay), "state.filterDecay");
    check(near(state.bassDrive, orig.drive), "state.bassDrive");
    check(near(state.bassSquash, orig.squash), "state.bassSquash");
    check(near(state.glideMs, orig.glideMs), "state.glideMs");
    check(near(state.bassVelocitySense, orig.velocitySense),
          "state.bassVelocitySense");

    // Roundtrip back to slot
    audioapp::DeviceSlot restored = type.slotFromSnapshot(state);
    check(std::holds_alternative<audioapp::BassSynthInstance>(restored.instance),
          "restored holds BassSynthInstance");
    const auto& ri = std::get<audioapp::BassSynthInstance>(restored.instance);
    check(near(ri.oscShape, orig.oscShape), "roundtrip oscShape");
    check(near(ri.subMix, orig.subMix), "roundtrip subMix");
    check(ri.subOctave == orig.subOctave, "roundtrip subOctave");
    check(near(ri.noise, orig.noise), "roundtrip noise");
    check(near(ri.ampAttack, orig.ampAttack), "roundtrip ampAttack");
    check(near(ri.ampSustain, orig.ampSustain), "roundtrip ampSustain");
    check(near(ri.ampRelease, orig.ampRelease), "roundtrip ampRelease");
    check(ri.octave == orig.octave, "roundtrip octave");
    check(near(ri.filterCutoff, orig.filterCutoff), "roundtrip filterCutoff");
    check(near(ri.filterResonance, orig.filterResonance),
          "roundtrip filterResonance");
    check(near(ri.filterEnvAmount, orig.filterEnvAmount),
          "roundtrip filterEnvAmount");
    check(near(ri.filterDecay, orig.filterDecay), "roundtrip filterDecay");
    check(near(ri.drive, orig.drive), "roundtrip drive");
    check(near(ri.squash, orig.squash), "roundtrip squash");
    check(near(ri.glideMs, orig.glideMs), "roundtrip glideMs");
    check(near(ri.velocitySense, orig.velocitySense),
          "roundtrip velocitySense");
    check(restored.id == state.id, "roundtrip id preserved");
}

// ── Test 3: SetParameter ──
// Verify that setParameter updates each bass parameter and returns handled=true.
void testSetParameter() {
    std::cout << "\n[Test 3] SetParameter\n";

    audioapp::BassSynthDeviceType type;
    auto slot = type.createDefault("set-id");

    // gain / pan / bypass (strip params)
    {
        auto r = type.setParameter(slot, "gain", 0.7f);
        check(r.handled, "setParameter gain handled");
        check(near(slot.gain, 0.7f), "gain == 0.7");
    }
    {
        auto r = type.setParameter(slot, "pan", 0.3f);
        check(r.handled, "setParameter pan handled");
        check(near(slot.pan, 0.3f), "pan == 0.3");
    }
    {
        auto r = type.setParameter(slot, "bypass", 1.0f);
        check(r.handled, "setParameter bypass handled");
        check(slot.bypassed, "bypassed == true");
    }

    auto& inst = std::get<audioapp::BassSynthInstance>(slot.instance);

    // Tone params
    auto r1 = type.setParameter(slot, "bassOscShape", 0.7f);
    check(r1.handled, "bassOscShape handled");
    check(near(inst.oscShape, 0.7f), "oscShape == 0.7");

    auto r2 = type.setParameter(slot, "bassSubMix", 0.2f);
    check(r2.handled, "bassSubMix handled");
    check(near(inst.subMix, 0.2f), "subMix == 0.2");

    auto r3 = type.setParameter(slot, "bassSubOctave", 1.0f);
    check(r3.handled, "bassSubOctave handled");
    check(inst.subOctave == 1, "subOctave == 1");

    auto r4 = type.setParameter(slot, "bassNoise", 0.3f);
    check(r4.handled, "bassNoise handled");
    check(near(inst.noise, 0.3f), "noise == 0.3");

    auto r5 = type.setParameter(slot, "attack", 0.1f);
    check(r5.handled, "attack handled");
    check(near(inst.ampAttack, 0.1f), "ampAttack == 0.1");

    auto r6 = type.setParameter(slot, "sustain", 0.5f);
    check(r6.handled, "sustain handled");
    check(near(inst.ampSustain, 0.5f), "ampSustain == 0.5");

    auto r7 = type.setParameter(slot, "release", 0.6f);
    check(r7.handled, "release handled");
    check(near(inst.ampRelease, 0.6f), "ampRelease == 0.6");

    auto r8 = type.setParameter(slot, "bassOctave", 3.0f);
    check(r8.handled, "bassOctave handled");
    check(inst.octave == 3, "octave == 3");

    // Filter params
    auto r9 = type.setParameter(slot, "filterCutoff", 0.4f);
    check(r9.handled, "filterCutoff handled");
    check(near(inst.filterCutoff, 0.4f), "filterCutoff == 0.4");

    auto r10 = type.setParameter(slot, "bassFilterResonance", 0.8f);
    check(r10.handled, "bassFilterResonance handled");
    check(near(inst.filterResonance, 0.8f), "filterResonance == 0.8");

    auto r11 = type.setParameter(slot, "filterEnvAmount", 0.3f);
    check(r11.handled, "filterEnvAmount handled");
    check(near(inst.filterEnvAmount, 0.3f), "filterEnvAmount == 0.3");

    auto r12 = type.setParameter(slot, "filterDecay", 0.7f);
    check(r12.handled, "filterDecay handled");
    check(near(inst.filterDecay, 0.7f), "filterDecay == 0.7");

    // Char params
    auto r13 = type.setParameter(slot, "bassDrive", 0.6f);
    check(r13.handled, "bassDrive handled");
    check(near(inst.drive, 0.6f), "drive == 0.6");

    auto r14 = type.setParameter(slot, "bassSquash", 0.9f);
    check(r14.handled, "bassSquash handled");
    check(near(inst.squash, 0.9f), "squash == 0.9");

    auto r15 = type.setParameter(slot, "glideMs", 0.4f);
    check(r15.handled, "glideMs handled");
    check(near(inst.glideMs, 0.4f), "glideMs == 0.4");

    auto r16 = type.setParameter(slot, "bassVelocitySense", 0.5f);
    check(r16.handled, "bassVelocitySense handled");
    check(near(inst.velocitySense, 0.5f), "velocitySense == 0.5");

    // Unknown parameter
    auto rUnknown = type.setParameter(slot, "nonexistent", 1.0f);
    check(!rUnknown.handled, "unknown param not handled");
}

// ── Test 4: SetParameterClamping ──
// Verify that float params clamp to [0,1] and int params clamp to valid range.
void testSetParameterClamping() {
    std::cout << "\n[Test 4] SetParameterClamping\n";

    audioapp::BassSynthDeviceType type;
    auto slot = type.createDefault("clamp-id");
    auto& inst = std::get<audioapp::BassSynthInstance>(slot.instance);

    // bassOscShape clamped to [0,1]
    type.setParameter(slot, "bassOscShape", 1.5f);
    check(near(inst.oscShape, 1.0f), "bassOscShape 1.5 clamped to 1.0");
    type.setParameter(slot, "bassOscShape", -0.5f);
    check(near(inst.oscShape, 0.0f), "bassOscShape -0.5 clamped to 0.0");

    // bassSubOctave clamped to [0,2]
    type.setParameter(slot, "bassSubOctave", 5.0f);
    check(inst.subOctave == 2, "bassSubOctave 5 clamped to 2");
    type.setParameter(slot, "bassSubOctave", -1.0f);
    check(inst.subOctave == 0, "bassSubOctave -1 clamped to 0");

    // bassOctave clamped to [0,4]
    type.setParameter(slot, "bassOctave", 10.0f);
    check(inst.octave == 4, "bassOctave 10 clamped to 4");
    type.setParameter(slot, "bassOctave", -5.0f);
    check(inst.octave == 0, "bassOctave -5 clamped to 0");

    // bassVelocitySense clamped to [0,1]
    type.setParameter(slot, "bassVelocitySense", 2.0f);
    check(near(inst.velocitySense, 1.0f),
          "bassVelocitySense 2.0 clamped to 1.0");
    type.setParameter(slot, "bassVelocitySense", -0.2f);
    check(near(inst.velocitySense, 0.0f),
          "bassVelocitySense -0.2 clamped to 0.0");
}

// ── Test 5: BuildPlaybackNode ──
// Verify that buildPlaybackNode produces a BassSynth node with correct
// hardcoded and mapped params.
void testBuildPlaybackNode() {
    std::cout << "\n[Test 5] BuildPlaybackNode\n";

    audioapp::BassSynthDeviceType type;
    auto slot = type.createDefault("pb-id");

    // Tweak some params to verify they propagate
    type.setParameter(slot, "bassOscShape", 0.7f);
    type.setParameter(slot, "bassSubMix", 0.25f);
    type.setParameter(slot, "bassDrive", 0.5f);
    type.setParameter(slot, "filterCutoff", 0.4f);

    audioapp::DeviceNodePlayback out{};
    audioapp::PlaybackBuildContext ctx{};
    type.buildPlaybackNode(slot, ctx, out);

    check(out.kind == audioapp::DeviceNodeKind::BassSynth,
          "out.kind == BassSynth");
    check(std::holds_alternative<audioapp::SubtractiveSynthParams>(out.params),
          "out.params holds SubtractiveSynthParams");

    const auto& sp =
        std::get<audioapp::SubtractiveSynthParams>(out.params);

    // Hardcoded bass synth values
    check(sp.filterMode == 0, "filterMode == 0 (LP12)");
    check(near(sp.synthMono, 1.0f), "synthMono == 1.0");
    check(near(sp.synthLegato, 1.0f), "synthLegato == 1.0");
    check(sp.oscMixMode == 0, "oscMixMode == 0");
    check(near(sp.filterSustain, 0.0f), "filterSustain == 0.0 (ADR)");

    // Mapped values
    check(near(sp.osc1Shape, 0.7f), "osc1Shape == 0.7 (from oscShape)");
    check(near(sp.oscMix, 0.25f), "oscMix == 0.25 (from subMix)");
    check(near(sp.filterCutoff, 0.4f), "filterCutoff == 0.4");
    check(near(sp.filterDrive, 0.5f), "filterDrive == 0.5 (from drive)");
    check(near(sp.preDrive, 0.25f), "preDrive == 0.25 (drive*0.5)");
    check(near(sp.osc2Shape, 0.0f), "osc2Shape == 0.0 (force sine)");
    check(near(sp.ampAttack, 0.02f), "ampAttack == 0.02 (default)");
    check(near(sp.glideMs, 0.0f), "glideMs == 0.0 (default)");
}

// ── Test 6: BuildPlaybackNodeMapping ──
// Verify specific value-to-value mappings through buildPlaybackNode.
void testBuildPlaybackNodeMapping() {
    std::cout << "\n[Test 6] BuildPlaybackNodeMapping\n";

    audioapp::BassSynthDeviceType type;
    audioapp::PlaybackBuildContext ctx{};

    // bassOscShape = 0.0f → osc1Shape = 0.0f
    {
        auto slot = type.createDefault("m1");
        type.setParameter(slot, "bassOscShape", 0.0f);
        audioapp::DeviceNodePlayback out{};
        type.buildPlaybackNode(slot, ctx, out);
        const auto& sp =
            std::get<audioapp::SubtractiveSynthParams>(out.params);
        check(near(sp.osc1Shape, 0.0f), "bassOscShape 0 → osc1Shape 0");
    }

    // bassOscShape = 1.0f → osc1Shape = 1.0f
    {
        auto slot = type.createDefault("m2");
        type.setParameter(slot, "bassOscShape", 1.0f);
        audioapp::DeviceNodePlayback out{};
        type.buildPlaybackNode(slot, ctx, out);
        const auto& sp =
            std::get<audioapp::SubtractiveSynthParams>(out.params);
        check(near(sp.osc1Shape, 1.0f), "bassOscShape 1 → osc1Shape 1");
    }

    // bassSubMix = 0.25f → oscMix = 0.25f
    {
        auto slot = type.createDefault("m3");
        type.setParameter(slot, "bassSubMix", 0.25f);
        audioapp::DeviceNodePlayback out{};
        type.buildPlaybackNode(slot, ctx, out);
        const auto& sp =
            std::get<audioapp::SubtractiveSynthParams>(out.params);
        check(near(sp.oscMix, 0.25f), "bassSubMix 0.25 → oscMix 0.25");
    }

    // bassDrive = 0.5f → filterDrive = 0.5f, preDrive = 0.25f
    {
        auto slot = type.createDefault("m4");
        type.setParameter(slot, "bassDrive", 0.5f);
        audioapp::DeviceNodePlayback out{};
        type.buildPlaybackNode(slot, ctx, out);
        const auto& sp =
            std::get<audioapp::SubtractiveSynthParams>(out.params);
        check(near(sp.filterDrive, 0.5f), "bassDrive 0.5 → filterDrive 0.5");
        check(near(sp.preDrive, 0.25f), "bassDrive 0.5 → preDrive 0.25");
    }

    // bassSquash = 0.7f → mixFeedback = 0.7f
    {
        auto slot = type.createDefault("m5");
        type.setParameter(slot, "bassSquash", 0.7f);
        audioapp::DeviceNodePlayback out{};
        type.buildPlaybackNode(slot, ctx, out);
        const auto& sp =
            std::get<audioapp::SubtractiveSynthParams>(out.params);
        check(near(sp.mixFeedback, 0.7f), "bassSquash 0.7 → mixFeedback 0.7");
    }

    // octave = 0 → globalPitch = 0.0f
    {
        auto slot = type.createDefault("m6");
        type.setParameter(slot, "bassOctave", 0.0f);
        audioapp::DeviceNodePlayback out{};
        type.buildPlaybackNode(slot, ctx, out);
        const auto& sp =
            std::get<audioapp::SubtractiveSynthParams>(out.params);
        check(near(sp.globalPitch, 0.0f), "octave 0 → globalPitch 0.0");
    }

    // octave = 4 → globalPitch = 0.5f
    {
        auto slot = type.createDefault("m7");
        type.setParameter(slot, "bassOctave", 4.0f);
        audioapp::DeviceNodePlayback out{};
        type.buildPlaybackNode(slot, ctx, out);
        const auto& sp =
            std::get<audioapp::SubtractiveSynthParams>(out.params);
        check(near(sp.globalPitch, 0.5f), "octave 4 → globalPitch 0.5");
    }

    // subOctave = 0 → osc2Shape = 0.0f (always force sine)
    {
        auto slot = type.createDefault("m8");
        type.setParameter(slot, "bassSubOctave", 0.0f);
        audioapp::DeviceNodePlayback out{};
        type.buildPlaybackNode(slot, ctx, out);
        const auto& sp =
            std::get<audioapp::SubtractiveSynthParams>(out.params);
        check(near(sp.osc2Shape, 0.0f),
              "subOctave 0 → osc2Shape 0.0 (force sine)");
    }
}

// ── Test 7: BuildLiveInstrument ──
// Verify that buildLiveInstrument produces a BassSynth LiveInstrumentSnapshot.
void testBuildLiveInstrument() {
    std::cout << "\n[Test 7] BuildLiveInstrument\n";

    audioapp::BassSynthDeviceType type;
    auto slot = type.createDefault("live-id");
    type.setParameter(slot, "bassOscShape", 0.6f);
    slot.gain = 0.8f;

    audioapp::LiveInstrumentSnapshot out{};
    audioapp::PlaybackBuildContext ctx{};
    bool result = type.buildLiveInstrument(slot, ctx, out);

    check(result, "buildLiveInstrument returned true");
    check(out.kind == audioapp::LiveInstrumentKind::BassSynth,
          "out.kind == BassSynth");
    check(near(out.subtractive.osc1Shape, 0.6f),
          "subtractive.osc1Shape == 0.6");
    check(near(out.subtractive.gain, 0.8f),
          "subtractive.gain == 0.8 (slot.gain)");
    check(near(out.subtractive.ampAttack, 0.02f),
          "subtractive.ampAttack default");
    check(near(out.subtractive.synthMono, 1.0f),
          "subtractive.synthMono == 1.0");
    check(near(out.subtractive.synthLegato, 1.0f),
          "subtractive.synthLegato == 1.0");
    check(near(out.subtractive.glideMs, 0.0f),
          "subtractive.glideMs == 0.0");
}

// ── Test 8: ModulatableParams ──
// Verify the list of modulatable parameters.
void testModulatableParams() {
    std::cout << "\n[Test 8] ModulatableParams\n";

    audioapp::BassSynthDeviceType type;
    auto params = type.modulatableParams();

    check(params.size() >= 18, "at least 18 modulatable params");

    auto contains = [&](const std::string_view& name) {
        for (const auto& p : params) {
            if (p == name)
                return true;
        }
        return false;
    };

    check(contains("gain"), "contains gain");
    check(contains("bassOscShape"), "contains bassOscShape");
    check(contains("filterCutoff"), "contains filterCutoff");
    check(contains("bassDrive"), "contains bassDrive");
    check(contains("bassSubMix"), "contains bassSubMix");
    check(contains("bassNoise"), "contains bassNoise");
    check(contains("bassFilterResonance"), "contains bassFilterResonance");
    check(contains("filterEnvAmount"), "contains filterEnvAmount");
    check(contains("filterDecay"), "contains filterDecay");
    check(contains("attack"), "contains attack");
    check(contains("sustain"), "contains sustain");
    check(contains("release"), "contains release");
    check(contains("bassSquash"), "contains bassSquash");
    check(contains("glideMs"), "contains glideMs");
    check(contains("bassVelocitySense"), "contains bassVelocitySense");
    check(contains("bassOctave"), "contains bassOctave");
    check(contains("bassSubOctave"), "contains bassSubOctave");
    check(contains("pan"), "contains pan");
}

// ── Test 9: SetStringParameter ──
// Verify that setStringParameter always returns false.
void testSetStringParameter() {
    std::cout << "\n[Test 9] SetStringParameter\n";

    audioapp::BassSynthDeviceType type;
    auto slot = type.createDefault("str-id");
    audioapp::PlaybackBuildContext ctx{};

    bool result =
        type.setStringParameter(slot, "anything", "value", ctx);
    check(!result, "setStringParameter returns false");

    // Ensure no crash with empty strings
    result = type.setStringParameter(slot, "", "", ctx);
    check(!result, "setStringParameter empty strings returns false");
}

// ── Test 10: DeviceRegistryIntegration ──
// Verify that BassSynthDeviceType is registered and works through the registry.
void testDeviceRegistryIntegration() {
    std::cout << "\n[Test 10] DeviceRegistryIntegration\n";

    auto registry = audioapp::DeviceRegistry::createBuiltIn();

    const auto* type = registry.find("bass_synth");
    check(type != nullptr, "registry.find(bass_synth) != nullptr");
    check(registry.isKnownType("bass_synth"),
          "registry.isKnownType(bass_synth)");

    // Create default via registry
    auto slot = registry.createDefault("bass_synth", "reg-id");
    check(std::holds_alternative<audioapp::BassSynthInstance>(slot.instance),
          "registry slot holds BassSynthInstance");
    check(slot.id == "reg-id", "registry slot.id == reg-id");

    const auto& inst = std::get<audioapp::BassSynthInstance>(slot.instance);
    check(near(inst.oscShape, 0.3f), "registry default oscShape == 0.3");

    // Set param via registry
    registry.setParameter(slot, "bassOscShape", 0.9f);
    check(near(inst.oscShape, 0.9f),
          "registry setParameter oscShape == 0.9");

    // Snapshot reflects change
    audioapp::DeviceState state = registry.toSnapshotState(slot);
    check(state.type == audioapp::device_types::kBasSynth,
          "registry state.type == bass_synth");
    check(near(state.bassOscShape, 0.9f),
          "registry state.bassOscShape == 0.9");

    // Restore from snapshot
    auto restored = registry.slotFromSnapshot(state);
    check(std::holds_alternative<audioapp::BassSynthInstance>(
              restored.instance),
          "restored holds BassSynthInstance");
    const auto& ri =
        std::get<audioapp::BassSynthInstance>(restored.instance);
    check(near(ri.oscShape, 0.9f), "restored oscShape == 0.9");

    // Build playback node via registry
    audioapp::DeviceNodePlayback pbOut{};
    audioapp::PlaybackBuildContext ctx{};
    registry.buildPlaybackNode(slot, ctx, pbOut);
    check(pbOut.kind == audioapp::DeviceNodeKind::BassSynth,
          "registry pbOut.kind == BassSynth");

    // Build live instrument via registry
    audioapp::LiveInstrumentSnapshot liOut{};
    bool liResult = registry.buildLiveInstrument(slot, ctx, liOut);
    check(liResult, "registry buildLiveInstrument returned true");
    check(liOut.kind == audioapp::LiveInstrumentKind::BassSynth,
          "registry liOut.kind == BassSynth");

    // Modulatable params via registry
    auto modParams = registry.modulatableParams("bass_synth");
    check(modParams.size() >= 16,
          "registry modulatableParams >= 18 entries");
}

} // namespace

int main() {
    std::cout << "=== bass_synth_test ===\n";

    testDefaultInstance();
    testToSnapshotRoundtrip();
    testSetParameter();
    testSetParameterClamping();
    testBuildPlaybackNode();
    testBuildPlaybackNodeMapping();
    testBuildLiveInstrument();
    testModulatableParams();
    testSetStringParameter();
    testDeviceRegistryIntegration();

    std::cout << "\nAll bass_synth tests passed.\n";
    return 0;
}
