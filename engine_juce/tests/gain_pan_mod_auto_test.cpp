/// Test: Gain/pan modulation + automation combine additively without conflict.
///
/// Tests verify that:
///   1. Automation-only on gain: smooth RMS ramp (early lower, late higher)
///   2. Modulation-only on gain: periodic RMS variation across windows
///   3. Combined mod+auto on gain: overall upward RMS trend WITH ripple
///   4. Combined mod+auto on pan: no crash, valid audio output
///
/// All tests use EngineHost::renderOffline to exercise the complete
/// control-thread -> audio-thread path for combined mod/auto on common params.

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
#include <vector>

class GainPanModAutoTest : public juce::UnitTest {
public:
    GainPanModAutoTest() : juce::UnitTest("GainPanModAuto", "Effects") {}
    void runTest() override {
        using namespace audioapp;
        using namespace audioapp::test;

        beginTest("automation-only on gain — smooth RMS ramp");
        {
            EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Test");
            host.selectTrack(trackId);
            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
            expect(!midiClipId.empty(), "midi clip created");
            std::vector<MidiNoteState> notes;
            notes.push_back({60, 0.0, 4.0, 100.0f});
            expect(host.setMidiClipNotes(midiClipId, notes), "set midi notes");

            const std::string autoClipId = host.createAutomationClip(trackId, 0.0, 4.0);
            expect(!autoClipId.empty(), "auto clip created");
            expect(host.assignAutomationTarget(autoClipId, synthId, "gain"),
                   "assign auto target");
            std::vector<AutomationPointState> points;
            points.push_back({0.0, 0.0f});
            points.push_back({4.0, 1.0f});
            expect(host.setAutomationPoints(autoClipId, points), "set auto points");

            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000, "enough audio");

            constexpr int kWindows = 8;
            const std::vector<float> rmsPerWindow = windowRMS(block, kWindows);
            expect(rmsPerWindow[0] < rmsPerWindow[4],
                   "early window quieter than mid window");

            int risingPairs = 0;
            for (int w = 1; w < kWindows; ++w) {
                if (rmsPerWindow[w] > rmsPerWindow[w - 1])
                    ++risingPairs;
            }
            expect(risingPairs >= kWindows - 2, "monotonic upward trend");
        }

        beginTest("modulation-only on gain — periodic RMS variation");
        {
            EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Test");
            host.selectTrack(trackId);
            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
            expect(!midiClipId.empty(), "midi clip created");
            std::vector<MidiNoteState> notes;
            notes.push_back({60, 0.0, 4.0, 100.0f});
            expect(host.setMidiClipNotes(midiClipId, notes), "set midi notes");

            const int lfoId = host.createLfo(0);
            host.updateLfoParam(lfoId, "waveform", 1.0f);   // triangle
            host.updateLfoParam(lfoId, "rate", 4.0f);
            host.updateLfoParam(lfoId, "syncDivision", 0.0f);
            expect(host.assignModulation(lfoId, synthId, "gain", 0.3f),
                   "assign modulation");

            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000, "enough audio");
            expect(rms(block, 1000, 4000) >= 1.0e-4f, "audible output");

            constexpr int kWindows = 8;
            const std::vector<float> rmsPerWindow = windowRMS(block, kWindows);

            int differingPairs = 0;
            for (int w = 1; w < kWindows; ++w) {
                const float a = rmsPerWindow[w - 1];
                const float b = rmsPerWindow[w];
                const float maxVal = std::max(a, b);
                if (maxVal > 1.0e-6f && std::abs(a - b) / maxVal > 0.05f)
                    ++differingPairs;
            }
            std::fprintf(stderr, "DBG GainPanModAuto test5 differingPairs=%d\n", differingPairs);
            expect(differingPairs >= 2, "adjacent windows differ due to LFO");
        }

        beginTest("combined mod+auto on gain — ramp + ripple");
        {
            EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Test");
            host.selectTrack(trackId);
            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
            expect(!midiClipId.empty(), "midi clip created");
            std::vector<MidiNoteState> notes;
            notes.push_back({60, 0.0, 4.0, 100.0f});
            expect(host.setMidiClipNotes(midiClipId, notes), "set midi notes");

            const std::string autoClipId = host.createAutomationClip(trackId, 0.0, 4.0);
            expect(!autoClipId.empty(), "auto clip created");
            expect(host.assignAutomationTarget(autoClipId, synthId, "gain"),
                   "assign auto target");
            std::vector<AutomationPointState> points;
            points.push_back({0.0, 0.0f});
            points.push_back({4.0, 1.0f});
            expect(host.setAutomationPoints(autoClipId, points), "set auto points");

            const int lfoId = host.createLfo(0);
            host.updateLfoParam(lfoId, "waveform", 1.0f);   // triangle
            host.updateLfoParam(lfoId, "rate", 4.0f);
            host.updateLfoParam(lfoId, "syncDivision", 0.0f);
            expect(host.assignModulation(lfoId, synthId, "gain", 0.3f),
                   "assign modulation");

            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000, "enough audio");

            constexpr int kWindows = 8;
            const std::vector<float> rmsPerWindow = windowRMS(block, kWindows);

            // A) Upward trend
            expect(rmsPerWindow[0] < rmsPerWindow[4],
                   "upward trend: window 0 < window 4");

            // B) Ripple
            int differingPairs = 0;
            for (int w = 1; w < kWindows; ++w) {
                const float a = rmsPerWindow[w - 1];
                const float b = rmsPerWindow[w];
                const float maxVal = std::max(a, b);
                if (maxVal > 1.0e-6f && std::abs(a - b) / maxVal > 0.05f)
                    ++differingPairs;
            }
            std::fprintf(stderr, "DBG GainPanModAuto test6 differingPairs=%d\n", differingPairs);
            expect(differingPairs >= 2, "ripple from LFO visible");

            // C) No clipping
            constexpr int kPeakCheckWindows = 2;
            const int peakWindowFrames = static_cast<int>(block.size()) / kWindows;
            const float peakLevel = peak(block, peakWindowFrames * (kWindows - kPeakCheckWindows),
                                         peakWindowFrames * kPeakCheckWindows);
            expect(peakLevel <= 2.0f, "peak within bounds");
        }

        beginTest("combined mod+auto on pan — no crash, valid output");
        {
            EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Test");
            host.selectTrack(trackId);
            const std::string synthId = host.addDeviceToTrack(trackId, "subtractive_synth");

            const std::string midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
            expect(!midiClipId.empty(), "midi clip created");
            std::vector<MidiNoteState> notes;
            notes.push_back({60, 0.0, 4.0, 100.0f});
            expect(host.setMidiClipNotes(midiClipId, notes), "set midi notes");

            const std::string autoClipId = host.createAutomationClip(trackId, 0.0, 4.0);
            expect(!autoClipId.empty(), "auto clip created");
            expect(host.assignAutomationTarget(autoClipId, synthId, "pan"),
                   "assign auto target (pan)");
            std::vector<AutomationPointState> points;
            points.push_back({0.0, -1.0f});
            points.push_back({4.0, 1.0f});
            expect(host.setAutomationPoints(autoClipId, points), "set auto points");

            const int lfoId = host.createLfo(0);
            host.updateLfoParam(lfoId, "waveform", 1.0f);   // triangle
            host.updateLfoParam(lfoId, "rate", 4.0f);
            host.updateLfoParam(lfoId, "syncDivision", 0.0f);
            expect(host.assignModulation(lfoId, synthId, "pan", 0.3f),
                   "assign pan modulation");

            host.setPlaying(true);
            const std::vector<float> block = host.renderOffline(4.0, 48000.0);
            expect(block.size() >= 48000, "enough audio");
            expect(rms(block, 1000, 4000) >= 1.0e-4f, "audible output");
            expect(peak(block, 0, static_cast<int>(block.size())) <= 2.0f,
                   "peak within bounds");
        }
    }
};
static GainPanModAutoTest gainPanModAutoTest;