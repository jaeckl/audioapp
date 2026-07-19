#include "audioapp/DeviceChain.hpp"
#include "audioapp/LivePerformance.hpp"

#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "TestChainHelper.hpp"

#include <cmath>
#include <cstring>
#include <fstream>
#include <vector>

class ClapGeneratorTest : public juce::UnitTest {
public:
    ClapGeneratorTest() : juce::UnitTest("ClapGenerator", "Audio") {}

    void runTest() override {
        constexpr int kFrames = 2048;
        constexpr double kSampleRate = 48000.0;

        audioapp::MidiPlaybackNote notes[1] = {
            {39, 0.0, 4.0, 0.0, 1.0, 100.0f},
        };

        audioapp::DeviceNodePlayback devices[1] = {};
        devices[0].kind = audioapp::DeviceNodeKind::ClapGenerator;
        devices[0].gain = 1.0f;
        devices[0].pan = 0.5f;
        devices[0].params = audioapp::ClapGeneratorParams{};

        beginTest("device chain produces output");
        {
            float left[kFrames];
            float right[kFrames];
            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));
            audioapp::test::processTestChain(left, right, kFrames, kSampleRate, 120, 0.0, notes, 1, devices, 1, false);
            expect(audioapp::test::peakAbs(left, kFrames) > 0.001f,
                   "Clap device chain should produce audible output");
        }

        beginTest("live performance mixer");
        {
            audioapp::LiveInstrumentSnapshot instrument{};
            instrument.kind = audioapp::LiveInstrumentKind::ClapGenerator;
            instrument.gain = 1.0f;
            instrument.clap.gain = 1.0f;
            audioapp::LivePerformanceMixer mixer;
            mixer.noteOn(instrument, 39, 100.0f);
            float live[kFrames];
            std::memset(live, 0, sizeof(live));
            mixer.readMix(live, kFrames, kSampleRate);
            expect(audioapp::test::peakAbs(live, kFrames) > 0.001f,
                   "Clap live performance mixer should produce audible output");
        }

        beginTest("pitch moves crack BP center inside clap band");
        {
            audioapp::ClapGeneratorParams lowParams;
            auto highParams = lowParams;
            lowParams.clapPitch = 0.25f;
            highParams.clapPitch = 0.75f;
            audioapp::ClapVoiceRuntime low;
            audioapp::ClapVoiceRuntime high;
            audioapp::triggerClapVoice(low, 39, 100.0f, lowParams);
            audioapp::triggerClapVoice(high, 39, 100.0f, highParams);
            low.elapsedSec = high.elapsedSec = 0.0;
            audioapp::clapGeneratorSample(low, lowParams, kSampleRate, 1.0f);
            audioapp::clapGeneratorSample(high, highParams, kSampleRate, 1.0f);
            expect(high.bodyHz > low.bodyHz * 1.15f,
                   "pitch must raise crack BP center");
            expect(low.bodyHz >= 700.0f && high.bodyHz <= 1700.0f,
                   "BP stays in clap band (not drill)");
        }

        beginTest("key track moves crack BP with MIDI");
        {
            audioapp::ClapGeneratorParams params;
            params.clapKeyTrack = 1.0f;
            params.clapPitch = 0.5f;
            audioapp::ClapVoiceRuntime low;
            audioapp::ClapVoiceRuntime high;
            audioapp::triggerClapVoice(low, 39, 100.0f, params);
            audioapp::triggerClapVoice(high, 51, 100.0f, params);
            low.elapsedSec = high.elapsedSec = 0.0;
            audioapp::clapGeneratorSample(low, params, kSampleRate, 1.0f);
            audioapp::clapGeneratorSample(high, params, kSampleRate, 1.0f);
            expect(high.bodyHz > low.bodyHz,
                   "key track must raise crack BP");
            expect(high.bodyHz <= 1700.0f, "high MIDI must not escape clap band");
        }

        beginTest("dump 808 clap for python identity check");
        {
            std::ofstream meta("clap_808_meta.txt");
            const auto dump = [&](const char* name, float pitch, float keyTrack, int midi) {
                audioapp::ClapGeneratorParams params;
                params.clapPitch = pitch;
                params.clapKeyTrack = keyTrack;
                params.clapBursts = 0.55f;
                params.clapSpread = 0.45f;
                params.clapRoom = 0.45f;
                params.clapDecay = 0.45f;
                params.clapTone = 0.55f;
                audioapp::ClapVoiceRuntime voice;
                audioapp::triggerClapVoice(voice, midi, 100.0f, params);
                constexpr int n = 16000;
                std::vector<float> buf(static_cast<size_t>(n));
                for (int i = 0; i < n; ++i) {
                    voice.elapsedSec = i / kSampleRate;
                    buf[static_cast<size_t>(i)] =
                        audioapp::clapGeneratorSample(voice, params, kSampleRate, 1.0f);
                }
                meta << name << " bodyHz=" << voice.bodyHz << "\n";
                std::ofstream out(name, std::ios::binary);
                expect(out.good(), "dump open");
                out.write(reinterpret_cast<const char*>(buf.data()),
                          static_cast<std::streamsize>(buf.size() * sizeof(float)));
            };
            dump("clap_808_p025.f32", 0.25f, 0.0f, 39);
            dump("clap_808_p050.f32", 0.50f, 0.0f, 39);
            dump("clap_808_p075.f32", 0.75f, 0.0f, 39);
            dump("clap_808_m39.f32", 0.50f, 1.0f, 39);
            dump("clap_808_m51.f32", 0.50f, 1.0f, 51);
        }
    }
};

static ClapGeneratorTest clapGeneratorTest;
