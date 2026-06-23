/// E2E tests for ADSR/ADR envelope modulation of filter cutoff.
///
/// Tests cover:
///   1. ADSR envelope produces attack peak then sustain decay
///   2. ADR (no sustain) decays faster than ADSR
///   3. Zero-attack ADSR shows immediate peak in first window

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

struct AdsrSetup {
    std::unique_ptr<audioapp::EngineHost> host;
    std::string trackId;
    std::string synthId;
    std::string midiClipId;

    AdsrSetup() {
        host = std::make_unique<audioapp::EngineHost>();
        host->createProject();
        trackId = host->addTrack("Test");
        host->selectTrack(trackId);
        synthId = host->addDeviceToTrack(trackId, "subtractive_synth");

        midiClipId = host->createMidiClip(trackId, 0.0, 4.0);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        host->setMidiClipNotes(midiClipId, notes);
    }
};

} // namespace

class AdsrModulatorTest : public juce::UnitTest {
public:
    AdsrModulatorTest() : juce::UnitTest("AdsrModulator", "Modulation") {}
    void runTest() override {
        using namespace audioapp;
        using namespace audioapp::test;

        beginTest("ADSR envelope on filterCutoff — HF peak at attack, sustain decay");
        {
            AdsrSetup setup;
            const int adsrId = setup.host->createLfo(1); // 1 = ADSR
            setup.host->updateLfoParam(adsrId, "attack", 0.01f);
            setup.host->updateLfoParam(adsrId, "decay", 0.15f);
            setup.host->updateLfoParam(adsrId, "sustain", 0.3f);
            setup.host->updateLfoParam(adsrId, "release", 0.2f);
            expect(setup.host->assignModulation(adsrId, setup.synthId, "filterCutoff", 0.8f),
                   "assign ADSR modulation");

            setup.host->setPlaying(true);
            const std::vector<float> audio = setup.host->renderOffline(4.0, 48000.0);
            expect(audio.size() >= 48000, "enough audio frames");
            expect(rms(audio, 1000, 4000) >= 1.0e-4f, "audible output");

            constexpr int kWindows = 8;
            const int windowSize = static_cast<int>(audio.size()) / kWindows;

            const float hfAttack = highFrequencyEnergy(audio, 0, windowSize * 2);
            const float hfSustain = highFrequencyEnergy(audio, 3 * windowSize, windowSize * 2);

            expect(hfAttack > 0.0f, "attack HF > 0");
            expect(hfSustain > 0.0f, "sustain HF > 0");
            expect(hfAttack >= hfSustain * 1.3f,
                   "attack HF at least 1.3x sustain HF");
        }

        beginTest("ADR (no sustain) decays faster than ADSR");
        {
            // ADSR render
            AdsrSetup setup1;
            const int adsrId = setup1.host->createLfo(1);
            setup1.host->updateLfoParam(adsrId, "attack", 0.01f);
            setup1.host->updateLfoParam(adsrId, "decay", 0.15f);
            setup1.host->updateLfoParam(adsrId, "sustain", 0.3f);
            setup1.host->updateLfoParam(adsrId, "release", 0.2f);
            setup1.host->assignModulation(adsrId, setup1.synthId, "filterCutoff", 0.8f);
            setup1.host->setPlaying(true);
            const std::vector<float> adsrAudio = setup1.host->renderOffline(4.0, 48000.0);
            expect(adsrAudio.size() >= 48000, "enough ADSR audio frames");
            expect(rms(adsrAudio, 1000, 4000) >= 1.0e-4f, "ADSR audible");

            // ADR render (modulatorType=2, no sustain)
            AdsrSetup setup2;
            const int adrId = setup2.host->createLfo(2); // 2 = ADR
            setup2.host->updateLfoParam(adrId, "attack", 0.01f);
            setup2.host->updateLfoParam(adrId, "decay", 0.15f);
            setup2.host->updateLfoParam(adrId, "sustain", 0.0f);
            setup2.host->updateLfoParam(adrId, "release", 0.2f);
            setup2.host->assignModulation(adrId, setup2.synthId, "filterCutoff", 0.8f);
            setup2.host->setPlaying(true);
            const std::vector<float> adrAudio = setup2.host->renderOffline(4.0, 48000.0);
            expect(adrAudio.size() >= 48000, "enough ADR audio frames");
            expect(rms(adrAudio, 1000, 4000) >= 1.0e-4f, "ADR audible");

            constexpr int kWindows = 8;
            const int windowSize = static_cast<int>(adsrAudio.size()) / kWindows;

            const float adsrMidHF = highFrequencyEnergy(adsrAudio, 3 * windowSize, windowSize);
            const float adrMidHF = highFrequencyEnergy(adrAudio, 3 * windowSize, windowSize);
            expect(adsrMidHF > 0.0f, "ADSR mid HF > 0");
            expect(adrMidHF > 0.0f, "ADR mid HF > 0");
            expect(adrMidHF < adsrMidHF * 0.85f,
                   "ADR mid HF less than ADSR mid HF");
        }

        beginTest("ADSR with zero attack produces immediate peak in first window");
        {
            AdsrSetup setup;
            const int adsrId = setup.host->createLfo(1);
            setup.host->updateLfoParam(adsrId, "attack", 0.0f);
            setup.host->updateLfoParam(adsrId, "decay", 0.15f);
            setup.host->updateLfoParam(adsrId, "sustain", 0.3f);
            setup.host->updateLfoParam(adsrId, "release", 0.2f);
            setup.host->assignModulation(adsrId, setup.synthId, "filterCutoff", 0.8f);

            setup.host->setPlaying(true);
            const std::vector<float> audio = setup.host->renderOffline(4.0, 48000.0);
            expect(audio.size() >= 48000, "enough audio frames");
            expect(rms(audio, 1000, 4000) >= 1.0e-4f, "audible output");

            constexpr int kWindows = 8;
            const int windowSize = static_cast<int>(audio.size()) / kWindows;

            const float hfFirst = highFrequencyEnergy(audio, 0, windowSize);
            expect(hfFirst > 0.0f, "first window HF > 0");

            float maxLaterHF = 0.0f;
            for (int w = 1; w < kWindows; ++w) {
                const float hf = highFrequencyEnergy(audio, w * windowSize, windowSize);
                maxLaterHF = std::max(maxLaterHF, hf);
            }
            expect(maxLaterHF > 0.0f, "later windows have HF > 0");
            expect(hfFirst > maxLaterHF,
                   "first window HF higher than any later window");
        }
    }
};
static AdsrModulatorTest adsrModulatorTest;