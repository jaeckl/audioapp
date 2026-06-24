/// Golden-file tests for LFO BPM-sync behavior.
///
/// Each test renders 4 beats with a specific LFO sync config and compares
/// to a golden reference.
///
/// To regenerate goldens: build with -DAUDIOAPP_REGENERATE_GOLDEN=ON and run.

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include "audioapp/EngineHost.hpp"

#include <vector>

namespace {

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
        beginTest("Sync 1/4 LFO (syncDivision=3) at 120 BPM");
        {
            TestSetup setup(4.0);
            const int lfo = setup.host.createLfo(0);
            setup.host.updateLfoParam(lfo, "waveform", 0.0f);
            setup.host.updateLfoParam(lfo, "syncDivision", 3.0f); // 1/4 note sync
            setup.host.updateLfoParam(lfo, "retrigger", 1.0f);
            setup.host.updateLfoParam(lfo, "rate", 1.0f);
            expect(setup.host.assignModulation(lfo, setup.synthId, "filterCutoff", 0.8f));

            expect(audioapp::test::checkRenderGolden(
                "lfo_sync_1_4.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        beginTest("Sync 1/2 LFO (syncDivision=2) at 120 BPM");
        {
            TestSetup setup(4.0);
            const int lfo = setup.host.createLfo(0);
            setup.host.updateLfoParam(lfo, "waveform", 0.0f);
            setup.host.updateLfoParam(lfo, "syncDivision", 2.0f); // 1/2 note sync
            setup.host.updateLfoParam(lfo, "retrigger", 1.0f);
            setup.host.updateLfoParam(lfo, "rate", 1.0f);
            expect(setup.host.assignModulation(lfo, setup.synthId, "filterCutoff", 0.8f));

            expect(audioapp::test::checkRenderGolden(
                "lfo_sync_1_2.bin", setup.host, 4.0, 48000.0, 2.0e-4f));
        }

        beginTest("Sync vs free LFO — different output");
        {
            // Sync LFO
            TestSetup syncSetup(4.0);
            const int syncLfo = syncSetup.host.createLfo(0);
            syncSetup.host.updateLfoParam(syncLfo, "waveform", 0.0f);
            syncSetup.host.updateLfoParam(syncLfo, "syncDivision", 3.0f); // 1/4 note
            syncSetup.host.updateLfoParam(syncLfo, "retrigger", 1.0f);
            syncSetup.host.updateLfoParam(syncLfo, "rate", 1.0f);
            syncSetup.host.assignModulation(syncLfo, syncSetup.synthId, "filterCutoff", 0.8f);

            expect(audioapp::test::checkRenderGolden(
                "lfo_sync_vs_free_sync.bin", syncSetup.host, 4.0, 48000.0, 2.0e-4f));

            // Free LFO
            TestSetup freeSetup(4.0);
            const int freeLfo = freeSetup.host.createLfo(0);
            freeSetup.host.updateLfoParam(freeLfo, "waveform", 0.0f);
            freeSetup.host.updateLfoParam(freeLfo, "syncDivision", 0.0f); // free
            freeSetup.host.updateLfoParam(freeLfo, "retrigger", 1.0f);
            freeSetup.host.updateLfoParam(freeLfo, "rate", 2.0f);
            freeSetup.host.assignModulation(freeLfo, freeSetup.synthId, "filterCutoff", 0.8f);

            expect(audioapp::test::checkRenderGolden(
                "lfo_sync_vs_free_free.bin", freeSetup.host, 4.0, 48000.0, 2.0e-4f));
        }

        beginTest("BPM change alters render output");
        {
            // Sync LFO at 120 BPM
            TestSetup setup120(4.0);
            const int lfo120 = setup120.host.createLfo(0);
            setup120.host.updateLfoParam(lfo120, "waveform", 0.0f);
            setup120.host.updateLfoParam(lfo120, "syncDivision", 3.0f);
            setup120.host.updateLfoParam(lfo120, "retrigger", 1.0f);
            setup120.host.updateLfoParam(lfo120, "rate", 1.0f);
            setup120.host.assignModulation(lfo120, setup120.synthId, "filterCutoff", 0.8f);

            expect(audioapp::test::checkRenderGolden(
                "lfo_sync_bpm_120.bin", setup120.host, 4.0, 48000.0, 2.0e-4f));

            // Sync LFO at 60 BPM
            TestSetup setup60(4.0);
            expect(setup60.host.setBpm(60));
            const int lfo60 = setup60.host.createLfo(0);
            setup60.host.updateLfoParam(lfo60, "waveform", 0.0f);
            setup60.host.updateLfoParam(lfo60, "syncDivision", 3.0f);
            setup60.host.updateLfoParam(lfo60, "retrigger", 1.0f);
            setup60.host.updateLfoParam(lfo60, "rate", 1.0f);
            setup60.host.assignModulation(lfo60, setup60.synthId, "filterCutoff", 0.8f);

            expect(audioapp::test::checkRenderGolden(
                "lfo_sync_bpm_60.bin", setup60.host, 4.0, 48000.0, 2.0e-4f));

            // Free LFO at 120 BPM
            TestSetup free120(4.0);
            const int freeLfo120 = free120.host.createLfo(0);
            free120.host.updateLfoParam(freeLfo120, "waveform", 0.0f);
            free120.host.updateLfoParam(freeLfo120, "syncDivision", 0.0f);
            free120.host.updateLfoParam(freeLfo120, "retrigger", 1.0f);
            free120.host.updateLfoParam(freeLfo120, "rate", 2.0f);
            free120.host.assignModulation(freeLfo120, free120.synthId, "filterCutoff", 0.8f);

            expect(audioapp::test::checkRenderGolden(
                "lfo_sync_free_120.bin", free120.host, 4.0, 48000.0, 2.0e-4f));

            // Free LFO at 60 BPM
            TestSetup free60(4.0);
            expect(free60.host.setBpm(60));
            const int freeLfo60 = free60.host.createLfo(0);
            free60.host.updateLfoParam(freeLfo60, "waveform", 0.0f);
            free60.host.updateLfoParam(freeLfo60, "syncDivision", 0.0f);
            free60.host.updateLfoParam(freeLfo60, "retrigger", 1.0f);
            free60.host.updateLfoParam(freeLfo60, "rate", 2.0f);
            free60.host.assignModulation(freeLfo60, free60.synthId, "filterCutoff", 0.8f);

            expect(audioapp::test::checkRenderGolden(
                "lfo_sync_free_60.bin", free60.host, 4.0, 48000.0, 2.0e-4f));
        }
    }
};

static LfoSyncBpmTest lfoSyncBpmTest;