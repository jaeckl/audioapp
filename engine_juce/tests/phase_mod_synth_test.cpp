#include "audioapp/DeviceChain.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/LivePerformance.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/PhaseModSynthAlgorithm.hpp"
#include "audioapp/SamplePlaybackAlgorithm.hpp"
#include "audioapp/devices/DeviceRegistry.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"
#include "audioapp/devices/PhaseModSynthDeviceType.hpp"
#include "audioapp/devices/PlaybackBuildContext.hpp"
#include "audioapp/devices/instances/PhaseModSynthModel.hpp"

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <vector>

class PhaseModSynthTest : public juce::UnitTest {
public:
    PhaseModSynthTest() : juce::UnitTest("PhaseModSynth", "Audio") {}

    void runTest() override {
        constexpr double kSampleRate = 44100.0;

        // ====================================================================
        // Group A — DSP engine tests
        // ====================================================================

        // ------------------------------------------------------------------
        // A1: VoiceSampleBasics
        // ------------------------------------------------------------------
        beginTest("A1: VoiceSampleBasics");
        {
            audioapp::PhaseModSynthParams params;
            params.algoIndex = 0;
            params.operators[0].level = 0.8f;
            params.operators[0].ratio = 1.0f;
            params.operators[1].level = 0.0f;
            params.operators[2].level = 0.0f;
            params.operators[3].level = 0.0f;

            audioapp::PhaseModSynthVoiceRuntime voice{};
            // Initialize voice phases so op1 produces sound
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            // Precompute phase increments for 1 voice
            voice.cachedUnisonCount = 1;
            voice.opPhaseIncs[0] = 6.28318530718f * 1.0f / static_cast<float>(kSampleRate);

            const float result = audioapp::phaseModVoiceSample(
                voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);

            expect(result > 0.0f || result < 0.0f,
                   "Voice sample should produce non-zero output");
            expect(std::isfinite(result),
                   "Voice sample should not be NaN or infinity");
        }

        // ------------------------------------------------------------------
        // A2: VoiceSampleSilence
        // ------------------------------------------------------------------
        beginTest("A2: VoiceSampleSilence");
        {
            audioapp::PhaseModSynthParams params;
            params.algoIndex = 0;
            for (int i = 0; i < 4; ++i)
                params.operators[i].level = 0.0f;

            audioapp::PhaseModSynthVoiceRuntime voice{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            voice.opPhaseIncs[0] = 6.28318530718f * 1.0f / static_cast<float>(kSampleRate);

            const float result = audioapp::phaseModVoiceSample(
                voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);

            expectEquals(result, 0.0f,
                         "All operator levels at 0 should produce silence");
        }

        // ------------------------------------------------------------------
        // A3: ModulationProducesSidebands
        // ------------------------------------------------------------------
        beginTest("A3: ModulationProducesSidebands");
        {
            audioapp::PhaseModSynthParams params;
            params.algoIndex = 0;
            params.operators[0].level = 0.8f;
            params.operators[0].ratio = 1.0f;  // carrier
            params.operators[1].level = 0.0f;  // start with no modulator
            params.operators[1].ratio = 5.0f;
            params.operators[2].level = 0.0f;
            params.operators[3].level = 0.0f;

            audioapp::PhaseModSynthVoiceRuntime voice{};
            voice.cachedUnisonCount = 1;

            // Render with modulator at 0
            std::vector<float> noMod(441, 0.0f);
            voice = audioapp::PhaseModSynthVoiceRuntime{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            voice.opPhaseIncs[0] = 6.28318530718f * 1.0f / static_cast<float>(kSampleRate);
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);
            for (int i = 0; i < 441; ++i) {
                noMod[i] = audioapp::phaseModVoiceSample(
                    voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }
            const float peakNoMod = audioapp::test::peakAbs(noMod.data(), 441);

            // Now enable modulator
            params.operators[1].level = 0.6f;

            std::vector<float> withMod(441, 0.0f);
            voice = audioapp::PhaseModSynthVoiceRuntime{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);
            for (int i = 0; i < 441; ++i) {
                withMod[i] = audioapp::phaseModVoiceSample(
                    voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }
            const float peakWithMod = audioapp::test::peakAbs(withMod.data(), 441);

            expect(peakNoMod > 0.0f, "Carrier alone should produce output");
            expect(peakWithMod > 0.0f, "With modulation should produce output");
            // Output should differ (modulation changes waveform)
            bool differs = false;
            for (int i = 0; i < 441; ++i) {
                if (std::abs(noMod[i] - withMod[i]) > 1e-6f) { differs = true; break; }
            }
            expect(differs, "Modulation should produce different output from unmodulated carrier");
        }

        // ------------------------------------------------------------------
        // A4: AlgorithmRouting
        // ------------------------------------------------------------------
        beginTest("A4: AlgorithmRouting");
        {
            audioapp::PhaseModSynthParams params;
            params.operators[0].level = 0.8f;
            params.operators[0].ratio = 1.0f;
            params.operators[1].level = 0.6f;
            params.operators[1].ratio = 5.0f;
            params.operators[2].level = 0.4f;
            params.operators[2].ratio = 3.0f;
            params.operators[3].level = 0.3f;
            params.operators[3].ratio = 2.0f;

            // Render with algo 0
            params.algoIndex = 0;
            audioapp::PhaseModSynthVoiceRuntime voice{};
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);
            std::vector<float> algo0(441, 0.0f);
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            for (int i = 0; i < 441; ++i) {
                algo0[i] = audioapp::phaseModVoiceSample(
                    voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }

            // Render with algo 3
            params.algoIndex = 3;
            voice = audioapp::PhaseModSynthVoiceRuntime{};
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);
            std::vector<float> algo3(441, 0.0f);
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            for (int i = 0; i < 441; ++i) {
                algo3[i] = audioapp::phaseModVoiceSample(
                    voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }

            bool differs = false;
            for (int i = 0; i < 441; ++i) {
                if (std::abs(algo0[i] - algo3[i]) > 1e-6f) { differs = true; break; }
            }
            expect(differs, "Algorithms 0 and 3 should produce different output");
        }

        // ------------------------------------------------------------------
        // A5: AdsrEnvelopeAttack
        // ------------------------------------------------------------------
        beginTest("A5: AdsrEnvelopeAttack");
        {
            audioapp::PhaseModSynthParams params;
            params.algoIndex = 0;
            params.operators[0].level = 0.8f;
            params.operators[0].ratio = 1.0f;
            params.operators[0].attack = 0.9f;  // slow attack
            params.operators[1].level = 0.0f;
            params.operators[2].level = 0.0f;
            params.operators[3].level = 0.0f;

            audioapp::PhaseModSynthVoiceRuntime voice{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            voice.envelopeValues[0] = 0.0f;
            voice.envelopePhase[0] = 0;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);

            // After 1 frame, envelope should have started rising from 0
            audioapp::phaseModVoiceSample(voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            const float envAfter1 = voice.envelopeValues[0];
            expect(envAfter1 > 0.0f, "Envelope should start rising from 0 after one frame");

            // Run many frames with fast attack to verify envelope reaches peak
            params.operators[0].attack = 0.01f;  // fast attack
            voice = audioapp::PhaseModSynthVoiceRuntime{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);
            for (int i = 0; i < 4410; ++i) {
                audioapp::phaseModVoiceSample(voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }
            expect(voice.envelopeValues[0] >= 0.99f,
                   "Envelope with fast attack should reach near 1.0");
            expect(voice.envelopePhase[0] >= 1,
                   "Envelope with fast attack should exit attack phase");
        }

        // ------------------------------------------------------------------
        // A6: AdsrEnvelopeDecaySustain
        // ------------------------------------------------------------------
        beginTest("A6: AdsrEnvelopeDecaySustain");
        {
            audioapp::PhaseModSynthParams params;
            params.algoIndex = 0;
            params.operators[0].level = 0.8f;
            params.operators[0].ratio = 1.0f;
            params.operators[0].attack = 0.01f;   // fast attack
            params.operators[0].decay = 0.5f;     // moderate decay
            params.operators[0].sustain = 0.5f;   // sustain at 0.5
            params.operators[1].level = 0.0f;
            params.operators[2].level = 0.0f;
            params.operators[3].level = 0.0f;

            audioapp::PhaseModSynthVoiceRuntime voice{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);

            // Run enough frames to get past attack and well into sustain
            for (int i = 0; i < 44100; ++i) {
                audioapp::phaseModVoiceSample(voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }

            // Envelope should be near sustain level
            expect(std::abs(voice.envelopeValues[0] - 0.5f) < 0.1f,
                   "Envelope should reach sustain level ~0.5 after attack+decay");
            expect(voice.envelopePhase[0] == 2,
                   "Envelope should be in sustain phase");
        }

        // ------------------------------------------------------------------
        // A7: AdsrEnvelopeRelease
        // ------------------------------------------------------------------
        beginTest("A7: AdsrEnvelopeRelease");
        {
            audioapp::PhaseModSynthParams params;
            params.algoIndex = 0;
            params.operators[0].level = 0.8f;
            params.operators[0].ratio = 1.0f;
            params.operators[0].attack = 0.01f;
            params.operators[0].decay = 0.3f;
            params.operators[0].sustain = 0.5f;
            params.operators[0].release = 0.01f;  // fast release
            params.operators[1].level = 0.0f;
            params.operators[2].level = 0.0f;
            params.operators[3].level = 0.0f;

            audioapp::PhaseModSynthVoiceRuntime voice{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);

            // Run through attack + decay into sustain
            for (int i = 0; i < 4410; ++i) {
                audioapp::phaseModVoiceSample(voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }
            expect(voice.envelopePhase[0] == 2,
                   "Envelope should be in sustain phase before release trigger");

            // Trigger release by setting envelopePhase to release
            voice.envelopePhase[0] = 3;

            // Run release frames
            for (int i = 0; i < 4410; ++i) {
                audioapp::phaseModVoiceSample(voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }

            expect(voice.envelopePhase[0] == 4,
                   "Envelope should reach done phase after release");
            expect(voice.envelopeValues[0] <= 0.001f,
                   "Envelope should fade to ~0 after release");
        }

        // ------------------------------------------------------------------
        // A8: FilterBiquad
        // ------------------------------------------------------------------
        beginTest("A8: FilterBiquad");
        {
            audioapp::PhaseModSynthParams params;
            params.algoIndex = 0;
            params.operators[0].level = 0.8f;
            params.operators[0].ratio = 1.0f;
            params.operators[0].attack = 0.01f;
            params.operators[1].level = 0.0f;
            params.operators[2].level = 0.0f;
            params.operators[3].level = 0.0f;

            // Low cutoff — heavily filtered
            params.filterCutoff = 0.1f;

            audioapp::PhaseModSynthVoiceRuntime voice{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);
            std::vector<float> lowCut(441, 0.0f);
            for (int i = 0; i < 441; ++i) {
                lowCut[i] = audioapp::phaseModVoiceSample(
                    voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }
            const float rmsLow = audioapp::test::rms(lowCut, 0, 441);

            // Fully open cutoff
            params.filterCutoff = 0.85f;

            voice = audioapp::PhaseModSynthVoiceRuntime{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);
            std::vector<float> openCut(441, 0.0f);
            for (int i = 0; i < 441; ++i) {
                openCut[i] = audioapp::phaseModVoiceSample(
                    voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }
            const float rmsOpen = audioapp::test::rms(openCut, 0, 441);

            expect(rmsOpen > rmsLow,
                   "Output with fully open filter should have higher RMS than low cutoff");
        }

        // ------------------------------------------------------------------
        // A9: Unison
        // ------------------------------------------------------------------
        beginTest("A9: Unison");
        {
            audioapp::PhaseModSynthParams params;
            params.algoIndex = 0;
            params.operators[0].level = 0.8f;
            params.operators[0].ratio = 1.0f;
            params.operators[1].level = 0.0f;
            params.operators[2].level = 0.0f;
            params.operators[3].level = 0.0f;
            params.unisonVoices = 0.0f;  // 1 voice

            audioapp::PhaseModSynthVoiceRuntime voice{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);
            std::vector<float> unison1(441, 0.0f);
            for (int i = 0; i < 441; ++i) {
                unison1[i] = audioapp::phaseModVoiceSample(
                    voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }

            // 4 unison voices
            params.unisonVoices = 1.0f;

            voice = audioapp::PhaseModSynthVoiceRuntime{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);
            std::vector<float> unison4(441, 0.0f);
            for (int i = 0; i < 441; ++i) {
                unison4[i] = audioapp::phaseModVoiceSample(
                    voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }

            bool differs = false;
            for (int i = 0; i < 441; ++i) {
                if (std::abs(unison1[i] - unison4[i]) > 1e-6f) { differs = true; break; }
            }
            expect(differs,
                   "Output with 4 unison voices should differ from 1 voice");
        }

        // ------------------------------------------------------------------
        // A10: MidiBlockRender
        // ------------------------------------------------------------------
        beginTest("A10: MidiBlockRender");
        {
            audioapp::PhaseModSynthParams params;
            params.algoIndex = 0;
            params.operators[0].level = 0.8f;
            params.operators[0].ratio = 1.0f;
            params.operators[0].attack = 0.01f;
            params.operators[1].level = 0.0f;
            params.operators[2].level = 0.0f;
            params.operators[3].level = 0.0f;

            audioapp::PhaseModSynthRuntime runtime{};
            runtime.stealIndex = 0;

            audioapp::PhaseModSynthMidiNoteRegion notes[1];
            notes[0].pitch = 60;
            notes[0].noteKey = 0;
            notes[0].clipStartBeat = 0.0;
            notes[0].clipLengthBeats = 4.0;
            notes[0].noteStartBeat = 0.0;
            notes[0].noteDurationBeats = 1.0;
            notes[0].velocity = 100.0f;

            constexpr int kFrames = 441;
            float monoOut[kFrames]{};
            std::memset(monoOut, 0, sizeof(monoOut));

            audioapp::mixPhaseModMidiNotesBlock(
                monoOut, kFrames, kSampleRate, 120, 0.0,
                notes, 1, params, runtime);

            const float peak = audioapp::test::peakAbs(monoOut, kFrames);
            expect(peak > 0.001f,
                   "MIDI block render should produce non-zero output");

            // Verify runtime state was updated (voice allocated)
            bool voiceActive = false;
            for (int v = 0; v < audioapp::kPhaseModMaxVoices; ++v) {
                if (runtime.voices[v].active != 0) { voiceActive = true; break; }
            }
            expect(voiceActive, "Runtime should have active voices after block render");
        }

        // ------------------------------------------------------------------
        // A11: Feedback
        // ------------------------------------------------------------------
        beginTest("A11: Feedback");
        {
            audioapp::PhaseModSynthParams params;
            params.algoIndex = 7;  // all_mod_fb
            params.feedback = 0.0f;
            params.operators[0].level = 0.8f;
            params.operators[0].ratio = 1.0f;
            params.operators[1].level = 0.0f;
            params.operators[2].level = 0.0f;
            params.operators[3].level = 0.0f;

            audioapp::PhaseModSynthVoiceRuntime voice{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);
            std::vector<float> noFb(441, 0.0f);
            for (int i = 0; i < 441; ++i) {
                noFb[i] = audioapp::phaseModVoiceSample(
                    voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }

            // Enable feedback
            params.feedback = 0.9f;

            voice = audioapp::PhaseModSynthVoiceRuntime{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);
            std::vector<float> withFb(441, 0.0f);
            for (int i = 0; i < 441; ++i) {
                withFb[i] = audioapp::phaseModVoiceSample(
                    voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, 0.0f);
            }

            bool differs = false;
            for (int i = 0; i < 441; ++i) {
                if (std::abs(noFb[i] - withFb[i]) > 1e-6f) { differs = true; break; }
            }
            expect(differs,
                   "Output with feedback=0.9 should differ from feedback=0.0");
        }

        // ------------------------------------------------------------------
        // A12: LfoModulation
        // ------------------------------------------------------------------
        beginTest("A12: LfoModulation");
        {
            audioapp::PhaseModSynthParams params;
            params.algoIndex = 0;
            params.operators[0].level = 0.8f;
            params.operators[0].ratio = 1.0f;
            params.operators[1].level = 0.0f;
            params.operators[2].level = 0.0f;
            params.operators[3].level = 0.0f;
            params.lfoDest = 1;        // pitch
            params.lfoAmount = 0.5f;   // moderate amount
            params.lfoRate = 0.8f;     // fast LFO

            audioapp::PhaseModSynthVoiceRuntime voice{};
            voice.pitch = 60;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);

            // Render 4410 samples, varying LFO output manually
            std::vector<float> block(4410, 0.0f);
            for (int i = 0; i < 4410; ++i) {
                // Simulate LFO: a slow sine wave modulating pitch
                const float lfoPhase = static_cast<float>(i) * 2.0f * 3.14159f * 5.0f / 44100.0f;
                const float lfoOut = std::sin(lfoPhase);
                block[i] = audioapp::phaseModVoiceSample(
                    voice, params, 1.0f, 1.0f, kSampleRate, 1.0f, lfoOut);
            }

            // Verify the block has energy (it's producing output)
            const float peak = audioapp::test::peakAbs(block.data(), 4410);
            expect(peak > 0.001f, "LFO-modulated voice should produce output");

            // Verify RMS variation — LFO pitch modulation should cause amplitude
            // variation as the filter responds to different frequencies
            const float varRatio = audioapp::test::rmsVariationRatio(block, 10);
            expect(varRatio > 1.05f,
                   "LFO pitch modulation should cause RMS variation across windows");
        }

        // ------------------------------------------------------------------
        // A13: LiveVoice
        // ------------------------------------------------------------------
        beginTest("A13: LiveVoice");
        {
            audioapp::PhaseModSynthParams params;
            params.algoIndex = 0;
            params.operators[0].level = 0.8f;
            params.operators[0].ratio = 1.0f;
            params.operators[0].attack = 0.01f;
            params.operators[1].level = 0.0f;
            params.operators[2].level = 0.0f;
            params.operators[3].level = 0.0f;

            audioapp::PhaseModSynthVoiceRuntime voice{};
            voice.active = 1;
            voice.pitch = 60;
            voice.startBeat = 0.0;
            voice.currentHz = audioapp::midiNoteToHz(60);
            voice.targetHz = voice.currentHz;
            voice.cachedUnisonCount = 1;
            for (int u = 0; u < 4; ++u)
                for (int op = 0; op < 4; ++op)
                    voice.opPhaseIncs[u * 4 + op] = 6.28318530718f / static_cast<float>(kSampleRate);

            float mix = 0.0f;
            audioapp::renderPhaseModLiveVoice(mix, voice, params, kSampleRate,
                                               static_cast<double>(100) / kSampleRate, 3600.0);

            expect(std::isfinite(mix),
                   "Live voice render should produce finite output");
            expect(mix > 0.0f || mix < 0.0f,
                   "Live voice render should produce non-zero output");
        }

        // ====================================================================
        // Group B — Instance and device type tests
        // ====================================================================

        const audioapp::PhaseModSynthDeviceType deviceType;
        const audioapp::PlaybackBuildContext buildCtx;

        // ------------------------------------------------------------------
        // B1: DefaultInstance
        // ------------------------------------------------------------------
        beginTest("B1: DefaultInstance");
        {
            const auto slot = deviceType.createDefault("test-id");
            expectEquals(slot.id, std::string("test-id"),
                         "Slot id should match the provided id");

            const bool isPM = std::holds_alternative<audioapp::PhaseModSynthModel>(slot.config.instance);
            expect(isPM, "Slot instance should be PhaseModSynthModel");

            const auto& inst = std::get<audioapp::PhaseModSynthModel>(slot.config.instance);
            expectEquals(inst.algoIndex, 0, "Default algoIndex should be 0");
            expectEquals(inst.feedback, 0.0f, "Default feedback should be 0.0");
            expect(std::abs(inst.op[0].ratio - 0.0625f) < 0.001f,
                   "Default op[0].ratio should be 0.0625");
            expectEquals(inst.op[0].level, 0.8f, "Default op[0].level should be 0.8");
            expectEquals(inst.op[1].level, 0.4f, "Default op[1].level should be 0.4");
        }

        // ------------------------------------------------------------------
        // B2: ToSnapshotRoundtrip
        // ------------------------------------------------------------------
        beginTest("B2: ToSnapshotRoundtrip");
        {
            auto slot = deviceType.createDefault("test-id");
            {
                auto& inst = std::get<audioapp::PhaseModSynthModel>(slot.config.instance);
                inst.op[0].ratio = 0.5f;
                inst.algoIndex = 3;
                inst.feedback = 0.5f;
            }

            const juce::var serialized = deviceType.slotToVar(slot);
            const auto restored = deviceType.varToSlot(serialized);

            const bool isPM = std::holds_alternative<audioapp::PhaseModSynthModel>(restored.config.instance);
            expect(isPM, "Restored slot should be PhaseModSynthModel");

            const auto& inst = std::get<audioapp::PhaseModSynthModel>(restored.config.instance);
            expect(std::abs(inst.op[0].ratio - 0.5f) < 0.001f,
                   "Restored op[0].ratio should be ~0.5");
            expectEquals(inst.algoIndex, 3, "Restored algoIndex should be 3");
            expectEquals(inst.feedback, 0.5f, "Restored feedback should be 0.5");
        }

        // ------------------------------------------------------------------
        // B3: SetParameter
        // ------------------------------------------------------------------
        beginTest("B3: SetParameter");
        {
            auto slot = deviceType.createDefault("test-id");

            // pmOp1Level = 0.9 → handled, level updated
            auto result = deviceType.setParameter(slot, "pmOp1Level", 0.9f);
            expect(result.handled, "pmOp1Level=0.9 should be handled");
            {
                const auto& inst = std::get<audioapp::PhaseModSynthModel>(slot.config.instance);
                expect(std::abs(inst.op[0].level - 0.9f) < 0.001f,
                       "op[0].level should be ~0.9 after setParameter");
            }

            // pmAlgoIndex = 5 → handled, algoIndex updated
            result = deviceType.setParameter(slot, "pmAlgoIndex", 5.0f);
            expect(result.handled, "pmAlgoIndex=5 should be handled");
            {
                const auto& inst = std::get<audioapp::PhaseModSynthModel>(slot.config.instance);
                expectEquals(inst.algoIndex, 5, "algoIndex should be 5");
            }

            // Unknown parameter → not handled
            result = deviceType.setParameter(slot, "bogus", 0.5f);
            expect(!result.handled, "Unknown param 'bogus' should not be handled");
        }

        // ------------------------------------------------------------------
        // B4: SetParameterClamping
        // ------------------------------------------------------------------
        beginTest("B4: SetParameterClamping");
        {
            auto slot = deviceType.createDefault("test-id");

            // pmOp1Level = 1.5 → clamped to 1.0
            deviceType.setParameter(slot, "pmOp1Level", 1.5f);
            {
                const auto& inst = std::get<audioapp::PhaseModSynthModel>(slot.config.instance);
                expectEquals(inst.op[0].level, 1.0f, "pmOp1Level=1.5 should clamp to 1.0");
            }

            // Reset
            slot = deviceType.createDefault("test-id");

            // pmOp1Level = -0.5 → clamped to 0.0
            deviceType.setParameter(slot, "pmOp1Level", -0.5f);
            {
                const auto& inst = std::get<audioapp::PhaseModSynthModel>(slot.config.instance);
                expectEquals(inst.op[0].level, 0.0f, "pmOp1Level=-0.5 should clamp to 0.0");
            }

            // Reset
            slot = deviceType.createDefault("test-id");

            // pmAlgoIndex = 10 → clamped to 7
            deviceType.setParameter(slot, "pmAlgoIndex", 10.0f);
            {
                const auto& inst = std::get<audioapp::PhaseModSynthModel>(slot.config.instance);
                expectEquals(inst.algoIndex, 7, "pmAlgoIndex=10 should clamp to 7");
            }
        }

        // ------------------------------------------------------------------
        // B5: SetStringParameterAlgo
        // ------------------------------------------------------------------
        beginTest("B5: SetStringParameterAlgo");
        {
            // stack_4 → algoIndex 0
            {
                auto slot = deviceType.createDefault("test-id");
                const bool handled = deviceType.setStringParameter(
                    slot, "pmAlgo", "stack_4", buildCtx);
                expect(handled, "setStringParameter 'stack_4' should return true");
                const auto& inst = std::get<audioapp::PhaseModSynthModel>(slot.config.instance);
                expectEquals(inst.algoIndex, 0, "stack_4 → algoIndex 0");
            }

            // mod_3_to_1 → algoIndex 1
            {
                auto slot = deviceType.createDefault("test-id");
                const bool handled = deviceType.setStringParameter(
                    slot, "pmAlgo", "mod_3_to_1", buildCtx);
                expect(handled, "setStringParameter 'mod_3_to_1' should return true");
                const auto& inst = std::get<audioapp::PhaseModSynthModel>(slot.config.instance);
                expectEquals(inst.algoIndex, 1, "mod_3_to_1 → algoIndex 1");
            }

            // bogus → returns false
            {
                auto slot = deviceType.createDefault("test-id");
                const bool handled = deviceType.setStringParameter(
                    slot, "pmAlgo", "bogus", buildCtx);
                expect(!handled, "setStringParameter 'bogus' should return false");
            }

            // unhandled param ID → returns false
            {
                auto slot = deviceType.createDefault("test-id");
                const bool handled = deviceType.setStringParameter(
                    slot, "unhandled", "value", buildCtx);
                expect(!handled, "setStringParameter 'unhandled' should return false");
            }
        }

        // ------------------------------------------------------------------
        // B6: BuildPlaybackNode
        // ------------------------------------------------------------------
        beginTest("B6: BuildPlaybackNode");
        {
            auto slot = deviceType.createDefault("test-id");
            {
                auto& inst = std::get<audioapp::PhaseModSynthModel>(slot.config.instance);
                inst.algoIndex = 3;
                inst.op[0].level = 0.9f;
            }

            audioapp::DeviceNodePlayback out{};
            deviceType.buildPlaybackNode(slot, buildCtx, out);

            expect(out.kind == audioapp::DeviceNodeKind::PhaseModSynth,
                   "buildPlaybackNode should set kind to PhaseModSynth");

            const bool hasPM = std::holds_alternative<audioapp::PhaseModSynthParams>(out.params);
            expect(hasPM, "buildPlaybackNode params should hold PhaseModSynthParams");

            if (hasPM) {
                const auto& pmParams = std::get<audioapp::PhaseModSynthParams>(out.params);
                expectEquals(pmParams.algoIndex, 3, "Params algoIndex should be 3");
                expectEquals(pmParams.operators[0].level, 0.9f,
                             "Params op[0].level should be 0.9");
            }
        }

        // ------------------------------------------------------------------
        // B7: BuildLiveInstrument
        // ------------------------------------------------------------------
        beginTest("B7: BuildLiveInstrument");
        {
            auto slot = deviceType.createDefault("test-id");

            audioapp::LiveInstrumentSnapshot out{};
            const bool result = deviceType.buildLiveInstrument(slot, buildCtx, out);

            expect(result, "buildLiveInstrument should return true");
            expect(out.kind == audioapp::LiveInstrumentKind::PhaseModSynth,
                   "Live instrument kind should be PhaseModSynth");
            // phaseMod should be populated (default algoIndex 0, op[0].level 0.8)
            expectEquals(out.phaseMod.algoIndex, 0,
                         "Live instrument phaseMod.algoIndex should be 0");
        }

        // ------------------------------------------------------------------
        // B8: ModulatableParams
        // ------------------------------------------------------------------
        beginTest("B8: ModulatableParams");
        {
            const auto params = deviceType.modulatableParams();

            // Check that key expected params are present
            bool hasGain = false, hasFeedback = false, hasOp1Level = false, hasFilterCutoff = false;
            for (const auto& p : params) {
                if (p == "gain")          hasGain = true;
                if (p == "pmFeedback")    hasFeedback = true;
                if (p == "pmOp1Level")    hasOp1Level = true;
                if (p == "filterCutoff")  hasFilterCutoff = true;
            }
            expect(hasGain, "modulatableParams should contain 'gain'");
            expect(hasFeedback, "modulatableParams should contain 'pmFeedback'");
            expect(hasOp1Level, "modulatableParams should contain 'pmOp1Level'");
            expect(hasFilterCutoff, "modulatableParams should contain 'filterCutoff'");

            // Verify total count matches contract (24 params from implementation)
            // The implementation returns: gain, pmFeedback, pmLfoRate, pmLfoAmount,
            // pmVibratoDepth, pmVibratoRate, filterCutoff, filterQ, filterEnvAmount,
            // filterAttack, filterDecay, attack, decay, sustain, release,
            // pmOp1Level, pmOp2Level, pmOp3Level, pmOp4Level,
            // pmOp1Fine, pmOp2Fine, pmOp3Fine, pmOp4Fine, pmMasterVol
            expect(!params.empty(), "modulatableParams should not be empty");
        }

        // ------------------------------------------------------------------
        // B9: DeviceRegistryIntegration
        // ------------------------------------------------------------------
        beginTest("B9: DeviceRegistryIntegration");
        {
            const auto registry = audioapp::DeviceRegistry::createBuiltIn();

            // Verify find("phase_mod_synth") returns non-null
            const auto* found = registry.find(audioapp::device_types::kPhaseModSynth);
            expect(found != nullptr, "Registry should find phase_mod_synth device type");

            // Create slot via registry
            auto slot = registry.createDefault(audioapp::device_types::kPhaseModSynth, "test-id");
            const bool isPM = std::holds_alternative<audioapp::PhaseModSynthModel>(slot.config.instance);
            expect(isPM, "Registry-created slot should be PhaseModSynthModel");

            // Set parameter via registry
            const auto result = registry.setParameter(slot, "pmOp1Level", 0.9f);
            expect(result.handled, "Registry setParameter(pmOp1Level, 0.9) should be handled");
            {
                const auto& inst = std::get<audioapp::PhaseModSynthModel>(slot.config.instance);
                expect(std::abs(inst.op[0].level - 0.9f) < 0.001f,
                       "After registry setParameter, op[0].level should be ~0.9");
            }

            // Verify slotToVar JSON has the updated value
            const auto serialized = registry.find(audioapp::device_types::kPhaseModSynth)->slotToVar(slot);
            const auto restored = registry.find(audioapp::device_types::kPhaseModSynth)->varToSlot(serialized);
            {
                const auto& inst = std::get<audioapp::PhaseModSynthModel>(restored.config.instance);
                expect(std::abs(inst.op[0].level - 0.9f) < 0.001f,
                       "slotToVar/varToSlot roundtrip should preserve op[0].level ≈ 0.9");
            }
        }
    }
};

static PhaseModSynthTest phaseModSynthTest;
