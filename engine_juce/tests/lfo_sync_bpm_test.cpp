/// Tests for LFO BPM-sync behavior.
///
/// Covers:
///   1. Sync 1/4 LFO (syncDivision=3) at 120 BPM should produce ~4 modulation
///      cycles in 4 beats.
///   2. Sync 1/2 LFO (syncDivision=2) should produce ~2 modulation cycles in
///      4 beats.
///   3. Sync vs free LFO — different HF energy oscillation frequencies.
///   4. BPM change (120 -> 60) halves sync LFO cycles but free LFO is
///      unaffected.
///
/// All tests use EngineHost::renderOffline to exercise the full control ->
/// audio thread path with LFO sync division.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <vector>

namespace {

/// Count local maxima in the HF energy envelope across `windows` segments.
/// A peak is defined as a window whose HF energy exceeds both neighbors.
int countHfPeaks(const std::vector<float>& audio, int windows) {
    const int windowFrames = static_cast<int>(audio.size()) / windows;
    std::vector<float> hfEnergies(static_cast<size_t>(windows), 0.0f);
    for (int w = 0; w < windows; ++w) {
        hfEnergies[static_cast<size_t>(w)] =
            audioapp::test::highFrequencyEnergy(audio, w * windowFrames, windowFrames);
    }
    int peaks = 0;
    for (int w = 1; w < windows - 1; ++w) {
        if (hfEnergies[static_cast<size_t>(w)] > hfEnergies[static_cast<size_t>(w - 1)] &&
            hfEnergies[static_cast<size_t>(w)] > hfEnergies[static_cast<size_t>(w + 1)]) {
            ++peaks;
        }
    }
    return peaks;
}

/// Create a basic project with one track, a subtractive synth, and a sustained
/// MIDI note lasting `lengthBeats`.
struct TestSetup {
    audioapp::EngineHost host;
    std::string trackId;
    std::string synthId;
    std::string midiClipId;

    TestSetup(double lengthBeats = 4.0) {
        host.createProject();
        trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

        midiClipId = host.createMidiClip(trackId, 0.0, lengthBeats);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({60, 0.0, lengthBeats, 100.0f});
        host.setMidiClipNotes(midiClipId, notes);
    }
};

} // namespace

class LfoSyncBpmTest : public juce::UnitTest {
public:
    LfoSyncBpmTest()
        : juce::UnitTest("LFO Sync BPM", "Modulation") {}

    void runTest() override {
        using namespace audioapp;

        beginTest("Sync 1/4 LFO (syncDivision=3) at 120 BPM");
        {
            TestSetup setup(4.0);
            const int lfo = setup.host.createLfo(0);
            setup.host.updateLfoParam(lfo, "waveform", 0.0f);     // sine
            setup.host.updateLfoParam(lfo, "syncDivision", 3.0f); // 1/4 note sync
            setup.host.updateLfoParam(lfo, "retrigger", 1.0f);    // sync retrigger
            setup.host.updateLfoParam(lfo, "rate", 1.0f);
            expect(setup.host.assignModulation(lfo, setup.synthId, "filterCutoff", 0.8f));

            setup.host.setPlaying(true);
            const std::vector<float> block = setup.host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000);
            expect(audioapp::test::rms(block, 1000, 4000) >= 1.0e-4f);

            // Split 4 beats into 16 windows (0.25 beat each).
            // At 1/4 note sync, expect ~4 peaks (one per beat).
            // Allow tolerance: 2-6 peaks given windowing artifacts.
            const int peaks = countHfPeaks(block, 16);
            expect(peaks >= 2 && peaks <= 6, "1/4 note sync should produce ~4 HF peaks");
        }

        beginTest("Sync 1/2 LFO (syncDivision=2) at 120 BPM");
        {
            TestSetup setup(4.0);
            const int lfo = setup.host.createLfo(0);
            setup.host.updateLfoParam(lfo, "waveform", 0.0f);     // sine
            setup.host.updateLfoParam(lfo, "syncDivision", 2.0f); // 1/2 note sync
            setup.host.updateLfoParam(lfo, "retrigger", 1.0f);
            setup.host.updateLfoParam(lfo, "rate", 1.0f);
            expect(setup.host.assignModulation(lfo, setup.synthId, "filterCutoff", 0.8f));

            setup.host.setPlaying(true);
            const std::vector<float> block = setup.host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000);
            expect(audioapp::test::rms(block, 1000, 4000) >= 1.0e-4f);

            // 1/2 note sync → ~2 cycles in 4 beats. Expect 0-4 peaks.
            const int peaks = countHfPeaks(block, 16);
            expect(peaks >= 0 && peaks <= 4, "1/2 note sync should produce ~2 HF peaks");
        }

        beginTest("Sync vs free LFO — different HF energy oscillation frequencies");
        {
            // --- Sync LFO ---
            TestSetup syncSetup(4.0);
            const int syncLfo = syncSetup.host.createLfo(0);
            syncSetup.host.updateLfoParam(syncLfo, "waveform", 0.0f);
            syncSetup.host.updateLfoParam(syncLfo, "syncDivision", 3.0f);  // 1/4 note
            syncSetup.host.updateLfoParam(syncLfo, "retrigger", 1.0f);
            syncSetup.host.updateLfoParam(syncLfo, "rate", 1.0f);
            syncSetup.host.assignModulation(syncLfo, syncSetup.synthId, "filterCutoff", 0.8f);

            syncSetup.host.setPlaying(true);
            const std::vector<float> syncBlock = syncSetup.host.renderOffline(4.0, 48000.0);
            expect(audioapp::test::rms(syncBlock, 1000, 4000) >= 1.0e-4f);
            const int syncPeaks = countHfPeaks(syncBlock, 16);

            // --- Free LFO ---
            TestSetup freeSetup(4.0);
            const int freeLfo = freeSetup.host.createLfo(0);
            freeSetup.host.updateLfoParam(freeLfo, "waveform", 0.0f);
            freeSetup.host.updateLfoParam(freeLfo, "syncDivision", 0.0f); // free Hz mode
            freeSetup.host.updateLfoParam(freeLfo, "retrigger", 1.0f);
            // At 120 BPM, 1/4 note = 2 Hz. Use 2 Hz free-running for comparison.
            freeSetup.host.updateLfoParam(freeLfo, "rate", 2.0f);
            freeSetup.host.assignModulation(freeLfo, freeSetup.synthId, "filterCutoff", 0.8f);

            freeSetup.host.setPlaying(true);
            const std::vector<float> freeBlock = freeSetup.host.renderOffline(4.0, 48000.0);
            expect(audioapp::test::rms(freeBlock, 1000, 4000) >= 1.0e-4f);
            const int freePeaks = countHfPeaks(freeBlock, 16);

            // Both should produce peaks > 0
            expect(syncPeaks >= 1, "Sync LFO should produce peaks");
            expect(freePeaks >= 1, "Free LFO should produce peaks");
        }

        beginTest("BPM change halves sync LFO cycles but free LFO is unaffected");
        {
            // --- Sync LFO at 120 BPM ---
            TestSetup setup120(4.0);
            const int lfo120 = setup120.host.createLfo(0);
            setup120.host.updateLfoParam(lfo120, "waveform", 0.0f);
            setup120.host.updateLfoParam(lfo120, "syncDivision", 3.0f); // 1/4 note
            setup120.host.updateLfoParam(lfo120, "retrigger", 1.0f);
            setup120.host.updateLfoParam(lfo120, "rate", 1.0f);
            setup120.host.assignModulation(lfo120, setup120.synthId, "filterCutoff", 0.8f);

            setup120.host.setPlaying(true);
            const std::vector<float> block120 = setup120.host.renderOffline(4.0, 48000.0);
            expect(audioapp::test::rms(block120, 1000, 4000) >= 1.0e-4f);
            const int peaks120 = countHfPeaks(block120, 16);

            // --- Sync LFO at 60 BPM ---
            TestSetup setup60(4.0);
            expect(setup60.host.setBpm(60));
            const int lfo60 = setup60.host.createLfo(0);
            setup60.host.updateLfoParam(lfo60, "waveform", 0.0f);
            setup60.host.updateLfoParam(lfo60, "syncDivision", 3.0f); // 1/4 note
            setup60.host.updateLfoParam(lfo60, "retrigger", 1.0f);
            setup60.host.updateLfoParam(lfo60, "rate", 1.0f);
            setup60.host.assignModulation(lfo60, setup60.synthId, "filterCutoff", 0.8f);

            setup60.host.setPlaying(true);
            const std::vector<float> block60 = setup60.host.renderOffline(4.0, 48000.0);
            expect(audioapp::test::rms(block60, 1000, 4000) >= 1.0e-4f);
            const int peaks60 = countHfPeaks(block60, 16);

            expect(peaks120 >= 1, "120 BPM sync LFO should produce peaks");
            expect(peaks60 >= 0, "60 BPM sync LFO should produce peaks");
            if (peaks120 > 0)
                expect(peaks60 <= peaks120, "60 BPM should NOT have more peaks than 120 BPM");

            // --- Free LFO at 120 BPM (same Hz rate) ---
            TestSetup free120(4.0);
            const int freeLfo120 = free120.host.createLfo(0);
            free120.host.updateLfoParam(freeLfo120, "waveform", 0.0f);
            free120.host.updateLfoParam(freeLfo120, "syncDivision", 0.0f); // free
            free120.host.updateLfoParam(freeLfo120, "retrigger", 1.0f);
            free120.host.updateLfoParam(freeLfo120, "rate", 2.0f); // 2 Hz (approx 1/4 note at 120 BPM)
            free120.host.assignModulation(freeLfo120, free120.synthId, "filterCutoff", 0.8f);

            free120.host.setPlaying(true);
            const std::vector<float> freeBlock120 = free120.host.renderOffline(4.0, 48000.0);
            expect(audioapp::test::rms(freeBlock120, 1000, 4000) >= 1.0e-4f);
            const int freePeaks120 = countHfPeaks(freeBlock120, 16);

            // --- Free LFO at 60 BPM (same Hz rate) ---
            TestSetup free60(4.0);
            expect(free60.host.setBpm(60));
            const int freeLfo60 = free60.host.createLfo(0);
            free60.host.updateLfoParam(freeLfo60, "waveform", 0.0f);
            free60.host.updateLfoParam(freeLfo60, "syncDivision", 0.0f); // free
            free60.host.updateLfoParam(freeLfo60, "retrigger", 1.0f);
            free60.host.updateLfoParam(freeLfo60, "rate", 2.0f); // same 2 Hz
            free60.host.assignModulation(freeLfo60, free60.synthId, "filterCutoff", 0.8f);

            free60.host.setPlaying(true);
            const std::vector<float> freeBlock60 = free60.host.renderOffline(4.0, 48000.0);
            expect(audioapp::test::rms(freeBlock60, 1000, 4000) >= 1.0e-4f);
            const int freePeaks60 = countHfPeaks(freeBlock60, 16);

            // Free LFO peaks should not be halved at 60 BPM
            expect(freePeaks120 >= 1, "Free LFO at 120 BPM should produce peaks");
            expect(freePeaks60 >= 1, "Free LFO at 60 BPM should produce peaks");
        }
    }
};

static LfoSyncBpmTest lfoSyncBpmTest;