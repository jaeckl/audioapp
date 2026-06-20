/// E2E tests for ADSR/ADR envelope modulation of filter cutoff.
///
/// Tests cover:
///   1. ADSR envelope produces attack peak then sustain decay
///   2. ADR (no sustain) decays faster than ADSR
///   3. Zero-attack ADSR shows immediate peak in first window

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/SubtractiveSynth.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <limits>
#include <vector>

namespace {

// ---------- audio analysis helpers ----------

float rms(const std::vector<float>& samples, int start, int count) {
    double acc = 0.0;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i) {
        acc += static_cast<double>(samples[static_cast<size_t>(i)]) *
               static_cast<double>(samples[static_cast<size_t>(i)]);
    }
    return end > start ? static_cast<float>(std::sqrt(acc / (end - start))) : 0.0f;
}

float highFrequencyEnergy(const std::vector<float>& samples, int start, int count) {
    float energy = 0.0f;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start + 1; i < end; ++i) {
        const float diff = samples[static_cast<size_t>(i)] - samples[static_cast<size_t>(i - 1)];
        energy += diff * diff;
    }
    return energy;
}

struct AdsrSetup {
    audioapp::EngineHost host;
    std::string trackId;
    std::string synthId;
    std::string midiClipId;

    AdsrSetup() {
        host.createProject();
        trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        host.setMidiClipNotes(midiClipId, notes);
    }
};

} // namespace

int main() {
    using namespace audioapp;

    // =====================================================================
    // Test 1: ADSR envelope on filterCutoff — HF peak at attack, sustain decay
    //
    // An ADSR modulator (modulatorType=1) modulating filter cutoff should
    // produce high HF energy during the attack phase, then decay to the
    // sustain level. Windows 0-1 (attack) should have higher HF energy than
    // windows 3-4 (sustain).
    // =====================================================================
    {
        AdsrSetup setup;
        const int adsrId = setup.host.createLfo(1); // 1 = ADSR
        setup.host.updateLfoParam(adsrId, "attack", 0.01f);
        setup.host.updateLfoParam(adsrId, "decay", 0.15f);
        setup.host.updateLfoParam(adsrId, "sustain", 0.3f);
        setup.host.updateLfoParam(adsrId, "release", 0.2f);
        if (!setup.host.assignModulation(adsrId, setup.synthId, "filterCutoff", 0.8f)) {
            return EXIT_FAILURE;
        }

        setup.host.setPlaying(true);
        const std::vector<float> audio = setup.host.renderOffline(4.0, 48000.0);
        if (audio.size() < 48000) return EXIT_FAILURE;
        if (rms(audio, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        constexpr int kWindows = 8;
        const int windowSize = static_cast<int>(audio.size()) / kWindows;

        // Windows 0-1 (attack phase) should have higher HF energy than windows 3-4 (sustain)
        const float hfAttack = highFrequencyEnergy(audio, 0, windowSize * 2);
        const float hfSustain = highFrequencyEnergy(audio, 3 * windowSize, windowSize * 2);

        if (hfAttack <= 0.0f || hfSustain <= 0.0f) return EXIT_FAILURE;
        // Attack HF must be at least 1.3x sustain HF
        if (hfAttack < hfSustain * 1.3f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 2: ADR (modulatorType=2, no sustain) decays faster than ADSR
    //
    // ADR with sustain=0 should produce a faster decay, meaning HF energy
    // in the sustain windows (3-4) should be lower than the ADSR counterpart.
    // =====================================================================
    {
        // ADSR render
        AdsrSetup setup1;
        const int adsrId = setup1.host.createLfo(1);
        setup1.host.updateLfoParam(adsrId, "attack", 0.01f);
        setup1.host.updateLfoParam(adsrId, "decay", 0.15f);
        setup1.host.updateLfoParam(adsrId, "sustain", 0.3f);
        setup1.host.updateLfoParam(adsrId, "release", 0.2f);
        setup1.host.assignModulation(adsrId, setup1.synthId, "filterCutoff", 0.8f);
        setup1.host.setPlaying(true);
        const std::vector<float> adsrAudio = setup1.host.renderOffline(4.0, 48000.0);
        if (adsrAudio.size() < 48000) return EXIT_FAILURE;
        if (rms(adsrAudio, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        // ADR render (modulatorType=2, no sustain)
        AdsrSetup setup2;
        const int adrId = setup2.host.createLfo(2); // 2 = ADR
        setup2.host.updateLfoParam(adrId, "attack", 0.01f);
        setup2.host.updateLfoParam(adrId, "decay", 0.15f);
        setup2.host.updateLfoParam(adrId, "sustain", 0.0f);
        setup2.host.updateLfoParam(adrId, "release", 0.2f);
        setup2.host.assignModulation(adrId, setup2.synthId, "filterCutoff", 0.8f);
        setup2.host.setPlaying(true);
        const std::vector<float> adrAudio = setup2.host.renderOffline(4.0, 48000.0);
        if (adrAudio.size() < 48000) return EXIT_FAILURE;
        if (rms(adrAudio, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        constexpr int kWindows = 8;
        const int windowSize = static_cast<int>(adsrAudio.size()) / kWindows;

        // Mid windows (3-4, sustain region): ADR should have less HF than ADSR
        const float adsrMidHF = highFrequencyEnergy(adsrAudio, 3 * windowSize, windowSize);
        const float adrMidHF = highFrequencyEnergy(adrAudio, 3 * windowSize, windowSize);
        if (adsrMidHF <= 0.0f || adrMidHF <= 0.0f) return EXIT_FAILURE;
        // ADR with no sustain should have notably lower HF than ADSR in the mid region
        if (adrMidHF >= adsrMidHF * 0.85f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 3: ADSR with zero attack produces immediate peak in first window
    //
    // With attack=0, the envelope jumps to peak value immediately. The first
    // window should therefore have the highest HF energy.
    // =====================================================================
    {
        AdsrSetup setup;
        const int adsrId = setup.host.createLfo(1);
        setup.host.updateLfoParam(adsrId, "attack", 0.0f);
        setup.host.updateLfoParam(adsrId, "decay", 0.15f);
        setup.host.updateLfoParam(adsrId, "sustain", 0.3f);
        setup.host.updateLfoParam(adsrId, "release", 0.2f);
        setup.host.assignModulation(adsrId, setup.synthId, "filterCutoff", 0.8f);

        setup.host.setPlaying(true);
        const std::vector<float> audio = setup.host.renderOffline(4.0, 48000.0);
        if (audio.size() < 48000) return EXIT_FAILURE;
        if (rms(audio, 1000, 4000) < 1.0e-4f) return EXIT_FAILURE;

        constexpr int kWindows = 8;
        const int windowSize = static_cast<int>(audio.size()) / kWindows;

        // First window should have peak HF — higher than any later window
        const float hfFirst = highFrequencyEnergy(audio, 0, windowSize);
        if (hfFirst <= 0.0f) return EXIT_FAILURE;

        float maxLaterHF = 0.0f;
        for (int w = 1; w < kWindows; ++w) {
            const float hf = highFrequencyEnergy(audio, w * windowSize, windowSize);
            maxLaterHF = std::max(maxLaterHF, hf);
        }
        // First window must be higher than any later window
        if (maxLaterHF <= 0.0f) return EXIT_FAILURE;
        if (hfFirst <= maxLaterHF) return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}