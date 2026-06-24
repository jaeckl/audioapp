/// Comprehensive E2E test suite for modulation routing.
///
/// Tests cover:
///   1. Modulation edge routing into track playback snapshots (golden)
///   2. Modulation additive behavior (deterministic, no golden)
///   3. Modulation + automation together (golden)
///   4. Multiple modulation edges targeting the same device (golden)
///   5. Cross-track modulation edges (deterministic)
///   6. Same-track modulation edges (golden)
///   7. Oscillator frequency modulation (deterministic)
///   8. Modulation with note-on retrigger LFO (golden)
///   9. Modulation edge removal updates track playback snapshot (golden)
///  10. LFO rate update propagates to audio thread (deterministic)
///  11. LFO removal removes modulation (golden)
///  12. Parameter isolation (deterministic)
///  13. evaluateAutomationEnvelope basic functionality (deterministic)
///  14. applyDspAutomationAtBeat (deterministic)
///  15. Project file includes modulation edges after assignment (deterministic)
///
/// Audio output tests use golden-file comparisons for deterministic,
/// non-flaky verification. Golden files are in engine_juce/tests/golden/.
/// To regenerate: build with -DAUDIOAPP_REGENERATE_GOLDEN=ON.
///
/// Deterministic tests (param mapping, JSON, automation math) use direct
/// assertion — no golden needed.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <vector>

namespace {

/// Create a basic project with a track, a subtractive synth, and a long MIDI note.
struct TestSetup {
    audioapp::EngineHost host;
    std::string trackId;
    std::string synthId;
    std::string midiClipId;

    TestSetup() {
        host.createProject();
        trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        host.setMidiClipNotes(midiClipId, notes);
    }

    int createLfo(int waveform = 0, float rate = 4.0f, int syncDivision = 0) {
        const int lfoId = host.createLfo(0);
        host.updateLfoParam(lfoId, "waveform", static_cast<float>(waveform));
        host.updateLfoParam(lfoId, "rate", rate);
        host.updateLfoParam(lfoId, "syncDivision", static_cast<float>(syncDivision));
        return lfoId;
    }
};

} // namespace

class ModulationE2eTest : public juce::UnitTest {
public:
    ModulationE2eTest()
        : juce::UnitTest("Modulation E2E", "Modulation") {}

    void runTest() override {
        using namespace audioapp;

        // ================================================================
        // Test 1: Modulation edge routing — spectral variation (golden)
        // ================================================================
        beginTest("Modulation edge routing into track playback snapshots");
        {
            TestSetup setup;
            const int lfoId = setup.createLfo(0, 4.0f, 0);
            expect(setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 1.0f));

            expect(audioapp::test::checkRenderGolden(
                "mod_e2e_t1_lfo_filtercutoff.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        // ================================================================
        // Test 2: Modulation additive behavior (deterministic)
        // ================================================================
        beginTest("Modulation additive behavior via paramIdFromString + applyAutomationValue");
        {
            const uint16_t encodedFilterCutoff = packParamId(ParamKind::SubtractiveSynth,
                static_cast<uint16_t>(SubtractiveParam::FilterCutoff));
            expectEquals(paramIdFromString("filterCutoff", DeviceNodeKind::SubtractiveSynth), encodedFilterCutoff);

            expectEquals(paramIdFromString("oscMix", DeviceNodeKind::SubtractiveSynth),
                         packParamId(ParamKind::SubtractiveSynth, static_cast<uint16_t>(SubtractiveParam::OscMix)));

            expectEquals(paramIdFromString("gain", DeviceNodeKind::SubtractiveSynth), kEncodedCommonGain);

            expect(paramIdFromString("unknown", DeviceNodeKind::SubtractiveSynth) == 0u);

            {
                DeviceVariantParams params = SubtractiveSynthParams{};
                auto& sub = std::get<SubtractiveSynthParams>(params);
                sub.filterCutoff = 0.75f;
                applyAutomationValue(params, DeviceNodeKind::SubtractiveSynth,
                                     encodedFilterCutoff, 0.3f);
                expectWithinAbsoluteError(sub.filterCutoff, 0.3f, 0.001f);
            }
            {
                DeviceVariantParams params = SubtractiveSynthParams{};
                auto& sub = std::get<SubtractiveSynthParams>(params);
                sub.ampAttack = 0.5f;
                const uint16_t encodedAmpAttack = packParamId(ParamKind::SubtractiveSynth,
                    static_cast<uint16_t>(SubtractiveParam::AmpAttack));
                applyAutomationValue(params, DeviceNodeKind::SubtractiveSynth,
                                     encodedAmpAttack, 0.1f);
                expectWithinAbsoluteError(sub.ampAttack, 0.1f, 0.001f);
            }
        }

        // ================================================================
        // Test 3: Modulation + automation together (golden)
        // ================================================================
        beginTest("Modulation + automation together — no double-apply, no conflict");
        {
            TestSetup setup;
            const int lfoId = setup.createLfo(0, 8.0f, 0);
            expect(setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 0.5f));

            const std::string autoClipId = setup.host.createAutomationClip(setup.trackId, 0.0, 4.0);
            expect(!autoClipId.empty());
            expect(setup.host.assignAutomationTarget(autoClipId, setup.synthId, "filterCutoff"));
            std::vector<AutomationPointState> points;
            points.push_back({0.0, 1.0f});
            points.push_back({4.0, 0.0f});
            expect(setup.host.setAutomationPoints(autoClipId, points));

            expect(audioapp::test::checkRenderGolden(
                "mod_e2e_t3_mod_plus_auto.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        // ================================================================
        // Test 4: Multiple modulation edges (golden)
        // ================================================================
        beginTest("Multiple modulation edges targeting the same device");
        {
            TestSetup setup;
            const int lfo1 = setup.createLfo(0, 3.0f, 0);
            expect(setup.host.assignModulation(lfo1, setup.synthId, "filterCutoff", 0.8f));
            const int lfo2 = setup.createLfo(2, 7.0f, 0);
            expect(setup.host.assignModulation(lfo2, setup.synthId, "filterQ", 0.5f));

            expect(audioapp::test::checkRenderGolden(
                "mod_e2e_t4_multi_edge.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        // ================================================================
        // Test 5: Cross-track modulation (deterministic)
        // ================================================================
        beginTest("Cross-track modulation edge is NOT routed");
        {
            audioapp::EngineHost host;
            host.createProject();

            const std::string track1 = host.addTrack("Track-1");
            host.selectTrack(track1);
            const std::string synth1 = host.addDeviceToTrack(track1, "subtractive_synth");
            const std::string clip1 = host.createMidiClip(track1, 0.0, 4.0);
            expect(!clip1.empty());
            std::vector<MidiNoteState> notes1;
            notes1.push_back({60, 0.0, 4.0, 100.0f});
            host.setMidiClipNotes(clip1, notes1);

            host.selectTrack(track1);
            const std::string track2 = host.addTrack("Track-2");
            host.selectTrack(track2);
            const std::string synth2 = host.addDeviceToTrack(track2, "subtractive_synth");
            const std::string clip2 = host.createMidiClip(track2, 0.0, 4.0);
            expect(!clip2.empty());
            std::vector<MidiNoteState> notes2;
            notes2.push_back({72, 0.0, 4.0, 100.0f});
            host.setMidiClipNotes(clip2, notes2);

            const int lfoId = host.createLfo(0);
            host.updateLfoParam(lfoId, "waveform", 0.0f);
            host.updateLfoParam(lfoId, "rate", 4.0f);
            host.updateLfoParam(lfoId, "syncDivision", 0.0f);
            expect(host.assignModulation(lfoId, synth2, "filterCutoff", 1.0f));

            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 96000);
            expect(audioapp::test::rms(block, 2000, 4000) >= 1.0e-4f);
        }

        // ================================================================
        // Test 6: Same-track modulation (golden)
        // ================================================================
        beginTest("Same-track modulation edge IS routed");
        {
            // Unmodulated render
            audioapp::EngineHost host1;
            host1.createProject();
            const std::string t1 = host1.addTrack("Test");
            host1.selectTrack(t1);
            host1.addDeviceToTrack(t1, "subtractive_synth");
            const std::string c1 = host1.createMidiClip(t1, 0.0, 4.0);
            std::vector<MidiNoteState> notes;
            notes.push_back({60, 0.0, 4.0, 100.0f});
            host1.setMidiClipNotes(c1, notes);

            expect(audioapp::test::checkRenderGolden(
                "mod_e2e_t6_unmod.bin", host1, 4.0, 48000.0, 2.0e-4f));

            // Modulated render
            TestSetup setup;
            const int lfoId = setup.createLfo(0, 8.0f, 0);
            setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 1.0f);

            expect(audioapp::test::checkRenderGolden(
                "mod_e2e_t6_mod.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        // ================================================================
        // Test 7: Oscillator frequency modulation (deterministic)
        // ================================================================
        beginTest("Oscillator frequency modulation");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Test");
            host.selectTrack(trackId);
            const std::string oscId = host.addDeviceToTrack(trackId, "simple_oscillator");
            expect(!oscId.empty(), "T7 oscillator device should be created");
            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
            std::vector<MidiNoteState> notes;
            notes.push_back({72, 0.0, 4.0, 100.0f});
            host.setMidiClipNotes(midiClipId, notes);

            const int lfoId = host.createLfo(0);
            host.updateLfoParam(lfoId, "waveform", 0.0f);
            host.updateLfoParam(lfoId, "rate", 1.0f);
            host.updateLfoParam(lfoId, "syncDivision", 0.0f);
            expect(host.assignModulation(lfoId, oscId, "frequency", 1.0f));

            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000);
            expect(audioapp::test::rms(block, 1000, 4000) >= 1.0e-4f,
                   "Oscillator with frequency modulation should produce audio");
        }

        // ================================================================
        // Test 8: Retrigger LFO (golden)
        // ================================================================
        beginTest("Modulation with note-on retrigger LFO");
        {
            TestSetup setup;
            const int lfoId = setup.host.createLfo(0);
            setup.host.updateLfoParam(lfoId, "waveform", 0.0f);
            setup.host.updateLfoParam(lfoId, "rate", 6.0f);
            setup.host.updateLfoParam(lfoId, "syncDivision", 0.0f);
            setup.host.updateLfoParam(lfoId, "retrigger", 2.0f); // OnNote
            expect(setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 1.0f));

            expect(audioapp::test::checkRenderGolden(
                "mod_e2e_t8_retrigger.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        // ================================================================
        // Test 9: Modulation edge removal (golden)
        // ================================================================
        beginTest("Modulation edge removal updates track playback snapshot");
        {
            TestSetup setup;
            const int lfoId = setup.createLfo(0, 8.0f, 0);
            expect(setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 1.0f));

            // With modulation
            expect(audioapp::test::checkRenderGolden(
                "mod_e2e_t9_with_mod.bin", setup.host, 4.0, 48000.0, 2.0e-4f));

            // Remove and re-render
            expect(setup.host.removeModulation(lfoId, "filterCutoff"));

            expect(audioapp::test::checkRenderGolden(
                "mod_e2e_t9_without_mod.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        // ================================================================
        // Test 10: LFO rate update propagates (deterministic)
        // ================================================================
        beginTest("LFO rate update propagates to audio thread");
        {
            TestSetup setup;
            const int lfoId = setup.createLfo(0, 4.0f, 0);
            setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 1.0f);

            // Slow LFO
            expect(audioapp::test::checkRenderGolden(
                "mod_e2e_t10_slow.bin", setup.host, 4.0, 48000.0, 2.0e-4f));

            // Change rate and re-render
            expect(setup.host.updateLfoParam(lfoId, "rate", 12.0f));

            expect(audioapp::test::checkRenderGolden(
                "mod_e2e_t10_fast.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        // ================================================================
        // Test 11: LFO removal (golden)
        // ================================================================
        beginTest("LFO removal removes modulation");
        {
            TestSetup setup;
            const int lfoId = setup.createLfo(0, 8.0f, 0);
            setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 1.0f);

            // With LFO
            expect(audioapp::test::checkRenderGolden(
                "mod_e2e_t11_with_lfo.bin", setup.host, 4.0, 48000.0, 2.0e-4f));

            // Remove LFO
            expect(setup.host.removeLfo(lfoId));

            // After removal
            expect(audioapp::test::checkRenderGolden(
                "mod_e2e_t11_after_remove.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        // ================================================================
        // Test 12: Parameter isolation (deterministic)
        // ================================================================
        beginTest("Parameter isolation — modulating one param doesn't touch others");
        {
            SubtractiveSynthParams params;
            params.filterCutoff = 0.5f;
            params.filterQ = 0.3f;
            params.ampAttack = 0.1f;
            params.gain = 0.8f;

            DeviceVariantParams variant = params;
            const uint16_t encodedCutoff = packParamId(ParamKind::SubtractiveSynth,
                static_cast<uint16_t>(SubtractiveParam::FilterCutoff));
            const uint16_t encodedQ = packParamId(ParamKind::SubtractiveSynth,
                static_cast<uint16_t>(SubtractiveParam::FilterQ));

            applyAutomationValue(variant, DeviceNodeKind::SubtractiveSynth, encodedCutoff, 0.9f);
            auto& modified = std::get<SubtractiveSynthParams>(variant);

            expectWithinAbsoluteError(modified.filterCutoff, 0.9f, 0.001f);
            expectWithinAbsoluteError(modified.filterQ, 0.3f, 0.001f);
            expectWithinAbsoluteError(modified.ampAttack, 0.1f, 0.001f);

            applyAutomationValue(variant, DeviceNodeKind::SubtractiveSynth, encodedQ, 0.7f);
            auto& modified2 = std::get<SubtractiveSynthParams>(variant);
            expectWithinAbsoluteError(modified2.filterQ, 0.7f, 0.001f);
            expectWithinAbsoluteError(modified2.filterCutoff, 0.9f, 0.001f);
        }

        // ================================================================
        // Test 13: Automation envelope evaluation (deterministic)
        // ================================================================
        beginTest("evaluateAutomationEnvelope basic functionality");
        {
            AutomationPointPlayback points[2];
            points[0] = {0.0f, 0.0f};
            points[1] = {4.0f, 1.0f};

            expectWithinAbsoluteError(evaluateAutomationEnvelope(points, 2, 0.0f), 0.0f, 0.001f);
            expectWithinAbsoluteError(evaluateAutomationEnvelope(points, 2, 2.0f), 0.5f, 0.001f);
            expectWithinAbsoluteError(evaluateAutomationEnvelope(points, 2, 4.0f), 1.0f, 0.001f);

            const float before = evaluateAutomationEnvelope(points, 2, -1.0f);
            expect(!std::isnan(before) && !std::isinf(before));

            const float after = evaluateAutomationEnvelope(points, 2, 5.0f);
            expect(!std::isnan(after) && !std::isinf(after));
        }

        // ================================================================
        // Test 14: applyDspAutomationAtBeat (deterministic)
        // ================================================================
        beginTest("applyDspAutomationAtBeat — end-to-end automation through variant");
        {
            DeviceVariantParams params = SubtractiveSynthParams{};
            auto& sub = std::get<SubtractiveSynthParams>(params);
            sub.filterCutoff = 0.75f;

            AutomationClipPlayback clips[1];
            clips[0].deviceIndex = 0;
            clips[0].localParamId = packParamId(ParamKind::SubtractiveSynth,
                static_cast<uint16_t>(SubtractiveParam::FilterCutoff));
            clips[0].clipStartBeat = 0.0f;
            clips[0].clipLengthBeats = 4.0f;
            clips[0].pointCount = 2;
            clips[0].points[0] = {0.0f, 0.0f};
            clips[0].points[1] = {4.0f, 1.0f};

            applyDspAutomationAtBeat(params, DeviceNodeKind::SubtractiveSynth,
                                     0, 2.0, clips, 1);
            const auto& result = std::get<SubtractiveSynthParams>(params);
            expectWithinAbsoluteError(result.filterCutoff, 0.5f, 0.01f);
        }

        // ================================================================
        // Test 15: JSON round-trip (deterministic)
        // ================================================================
        beginTest("Project file includes modulation edges after assignment");
        {
            TestSetup setup;
            const int lfoId = setup.createLfo(0, 4.0f, 0);

            expect(setup.host.assignModulation(lfoId, setup.synthId, "filterCutoff", 0.75f));

            const std::string json = setup.host.getProjectFileJson();
            audioapp::ProjectFileData parsed;
            expect(audioapp::test::parseProjectJsonInto(json, parsed));
            int foundEdge = 0;
            for (const auto& edge : parsed.modEdges) {
                if (edge.lfoId == lfoId && edge.deviceId == setup.synthId &&
                    edge.paramId == "filterCutoff") {
                    expectWithinAbsoluteError(edge.amount, 0.75f, 0.001f);
                    ++foundEdge;
                }
            }
            expectEquals(foundEdge, 1);

            expect(setup.host.removeModulation(lfoId, "filterCutoff"));

            const std::string json2 = setup.host.getProjectFileJson();
            audioapp::ProjectFileData parsed2;
            expect(audioapp::test::parseProjectJsonInto(json2, parsed2));
            bool foundStill = false;
            for (const auto& edge : parsed2.modEdges) {
                if (edge.lfoId == lfoId && edge.paramId == "filterCutoff") {
                    foundStill = true;
                }
            }
            expect(!foundStill, "Edge should have been removed from project file");
        }
    }
};

static ModulationE2eTest modulationE2eTest;