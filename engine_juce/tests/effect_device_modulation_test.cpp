/// Effect device modulation E2E test suite.
///
/// Tests LFO modulation of dynamics processor parameters:
///   1. LFO -> Compressor threshold -> audible gain reduction variation
///   2. LFO -> Gate threshold -> periodic opening/closing
///   3. LFO -> Gate range -> partial gating variation
///   4. LFO -> Expander threshold -> amplitude variation
///   5. LFO -> Limiter ceiling -> peak limiting variation
///
/// All tests use EngineHost::renderOffline with a simple oscillator as
/// signal source followed by an effect device, exercising the complete
/// control-thread -> audio-thread modulation path.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/SubtractiveSynth.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <limits>
#include <vector>

namespace {

/// Create a project with oscillator -> effect chain and a sustained MIDI note.
struct EffectTestSetup {
    audioapp::EngineHost host;
    std::string trackId;
    std::string oscId;
    std::string effectId;
    std::string midiClipId;

    EffectTestSetup(const std::string& effectType) {
        host.createProject();
        trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        oscId = host.addDeviceToTrack(trackId, "simple_oscillator");
        effectId = host.addDeviceToTrack(trackId, effectType);

        midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({72, 0.0, 4.0, 100.0f});
        host.setMidiClipNotes(midiClipId, notes);
    }

    int createLfo(float rate = 4.0f) {
        const int lfoId = host.createLfo(0); // 0 = LFO
        host.updateLfoParam(lfoId, "waveform", 0.0f);   // sine
        host.updateLfoParam(lfoId, "rate", rate);
        host.updateLfoParam(lfoId, "syncDivision", 0.0f); // free
        // Start at quarter-cycle so the per-block LFO sample (frame 0) is
        // at a non-zero value. The orchestrator samples the LFO at the
        // block start; a phase-0 sine would read 0 for every block and
        // the modulation amount would be zero.
        host.updateLfoParam(lfoId, "phase", 0.25f);
        return lfoId;
    }
};

} // namespace

class EffectDeviceModulationTest : public juce::UnitTest {
public:
    EffectDeviceModulationTest()
        : juce::UnitTest("Effect Device Modulation", "Effects") {}

    void runTest() override {
        using namespace audioapp;

        constexpr double kLengthBeats = 4.0;
        constexpr double kSampleRate = 48000.0;
        constexpr int kNumWindows = 20; // 5 per beat -> avoids LFO cycle alignment

        beginTest("LFO -> Compressor threshold -> audible gain reduction variation");
        {
            // Unmodulated baseline
            EffectTestSetup base("compressor");
            base.host.setDeviceParameter(base.effectId, "compThreshold", 0.05f);
            base.host.setPlaying(true);
            const std::vector<float> unmod = base.host.renderOffline(kLengthBeats, kSampleRate);
            expect(unmod.size() >= 48000);
            const float unmodRatio = audioapp::test::rmsVariationRatio(unmod, kNumWindows);

            // With modulation
            EffectTestSetup mod("compressor");
            mod.host.setDeviceParameter(mod.effectId, "compThreshold", 0.05f);
            const int lfoId = mod.createLfo(4.0f);
            expect(mod.host.assignModulation(lfoId, mod.effectId, "compThreshold", 0.8f));
            mod.host.setPlaying(true);
            const std::vector<float> modAudio = mod.host.renderOffline(kLengthBeats, kSampleRate);
            expect(modAudio.size() >= 48000);
            const float modRatio = audioapp::test::rmsVariationRatio(modAudio, kNumWindows);

            // Modulated must show more window-to-window RMS variation
            std::fprintf(stderr, "DBG Comp unmodRatio=%.4f modRatio=%.4f unmodMean=%.6f modMean=%.6f\n",
                unmodRatio, modRatio, audioapp::test::fullRms(unmod), audioapp::test::fullRms(modAudio));
            expect(modRatio >= 1.5f, "Modulated compressor should have >= 1.5x RMS variation");
            expect(modRatio >= unmodRatio * 1.5f, "Modulated should have > unmodulated RMS variation");
        }

        beginTest("LFO -> Gate threshold -> periodic opening/closing");
        {
            EffectTestSetup base("gate");
            base.host.setDeviceParameter(base.effectId, "gateThreshold", 0.15f);
            base.host.setPlaying(true);
            const std::vector<float> unmod = base.host.renderOffline(kLengthBeats, kSampleRate);
            expect(unmod.size() >= 48000);
            const float unmodRatio = audioapp::test::rmsVariationRatio(unmod, kNumWindows);

            EffectTestSetup mod("gate");
            mod.host.setDeviceParameter(mod.effectId, "gateThreshold", 0.15f);
            const int lfoId = mod.createLfo(4.0f);
            expect(mod.host.assignModulation(lfoId, mod.effectId, "gateThreshold", 0.5f));
            mod.host.setPlaying(true);
            const std::vector<float> modAudio = mod.host.renderOffline(kLengthBeats, kSampleRate);
            expect(modAudio.size() >= 48000);
            const float modRatio = audioapp::test::rmsVariationRatio(modAudio, kNumWindows);

            expect(modRatio >= 1.5f, "Modulated gate should have >= 1.5x RMS variation");
            expect(modRatio >= unmodRatio * 1.5f, "Modulated should have > unmodulated RMS variation");
        }

        beginTest("LFO -> Gate range -> partial gating");
        {
            EffectTestSetup base("gate");
            base.host.setDeviceParameter(base.effectId, "gateThreshold", 0.99f);
            base.host.setDeviceParameter(base.effectId, "gateRange", 0.0f);
            base.host.setPlaying(true);
            const std::vector<float> unmod = base.host.renderOffline(kLengthBeats, kSampleRate);
            expect(unmod.size() >= 48000);
            const float unmodRatio = audioapp::test::rmsVariationRatio(unmod, kNumWindows);

            EffectTestSetup mod("gate");
            mod.host.setDeviceParameter(mod.effectId, "gateThreshold", 0.99f);
            mod.host.setDeviceParameter(mod.effectId, "gateRange", 0.0f);
            const int lfoId = mod.createLfo(4.0f);
            expect(mod.host.assignModulation(lfoId, mod.effectId, "gateRange", 0.9f));
            mod.host.setPlaying(true);
            const std::vector<float> modAudio = mod.host.renderOffline(kLengthBeats, kSampleRate);
            expect(modAudio.size() >= 48000);
            const float modRatio = audioapp::test::rmsVariationRatio(modAudio, kNumWindows);

            expect(modRatio >= 1.5f, "Modulated gate range should have >= 1.5x RMS variation");
            expect(modRatio >= unmodRatio * 1.5f, "Modulated should have > unmodulated RMS variation");
        }

        beginTest("LFO -> Expander threshold -> amplitude variation");
        {
            EffectTestSetup base("expander");
            base.host.setDeviceParameter(base.effectId, "expandThreshold", 0.05f);
            base.host.setPlaying(true);
            const std::vector<float> unmod = base.host.renderOffline(kLengthBeats, kSampleRate);
            expect(unmod.size() >= 48000);
            const float unmodRatio = audioapp::test::rmsVariationRatio(unmod, kNumWindows);

            EffectTestSetup mod("expander");
            mod.host.setDeviceParameter(mod.effectId, "expandThreshold", 0.05f);
            const int lfoId = mod.createLfo(4.0f);
            expect(mod.host.assignModulation(lfoId, mod.effectId, "expandThreshold", 0.8f));
            mod.host.setPlaying(true);
            const std::vector<float> modAudio = mod.host.renderOffline(kLengthBeats, kSampleRate);
            expect(modAudio.size() >= 48000);
            const float modRatio = audioapp::test::rmsVariationRatio(modAudio, kNumWindows);

            expect(modRatio >= 1.5f, "Modulated expander should have >= 1.5x RMS variation");
            expect(modRatio >= unmodRatio * 1.5f, "Modulated should have > unmodulated RMS variation");
        }

        beginTest("LFO -> Limiter ceiling -> peak limiting variation");
        {
            EffectTestSetup base("limiter");
            base.host.setDeviceParameter(base.effectId, "limitCeiling", 0.1f);
            base.host.setPlaying(true);
            const std::vector<float> unmod = base.host.renderOffline(kLengthBeats, kSampleRate);
            expect(unmod.size() >= 48000);
            const float unmodRatio = audioapp::test::rmsVariationRatio(unmod, kNumWindows);

            EffectTestSetup mod("limiter");
            mod.host.setDeviceParameter(mod.effectId, "limitCeiling", 0.1f);
            const int lfoId = mod.createLfo(4.0f);
            expect(mod.host.assignModulation(lfoId, mod.effectId, "limitCeiling", 0.6f));
            mod.host.setPlaying(true);
            const std::vector<float> modAudio = mod.host.renderOffline(kLengthBeats, kSampleRate);
            expect(modAudio.size() >= 48000);
            const float modRatio = audioapp::test::rmsVariationRatio(modAudio, kNumWindows);

            expect(modRatio >= 1.5f, "Modulated limiter should have >= 1.5x RMS variation");
            expect(modRatio >= unmodRatio * 1.5f, "Modulated should have > unmodulated RMS variation");
        }
    }
};

static EffectDeviceModulationTest effectDeviceModulationTest;
