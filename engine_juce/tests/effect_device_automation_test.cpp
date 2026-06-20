/// E2E test suite for automation clips targeting effect device parameters.
///
/// Tests verify that dynamic parameter changes via automation produce
/// measurable changes in audio output for each effect type.
///
/// Device type IDs (from DeviceTypeIds.hpp):
///   "simple_oscillator", "compressor", "gate", "expander", "limiter"
///
/// Mapping notes:
///   - normToThresholdDb maps [0.0, 1.0] to [-60 dB,  -6 dB]
///   - normToCeilingDb  maps [0.0, 1.0] to [-12 dB,   0 dBFS]
///   - normToMakeupDb   maps [0.0, 1.0] to [  0 dB,  18 dB]
///
/// All tests reduce the oscillator gain to ≈0.3 (−10 dBFS) so the
/// signal sits well inside the threshold range of each effect.

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/EngineHost.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <limits>
#include <string>
#include <vector>

namespace {

// ---------- audio analysis helpers ----------

float rms(const std::vector<float>& samples, int start, int count) {
    double acc = 0.0;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i) {
        const double s = static_cast<double>(samples[static_cast<size_t>(i)]);
        acc += s * s;
    }
    return end > start ? static_cast<float>(std::sqrt(acc / (end - start))) : 0.0f;
}

float peak(const std::vector<float>& samples, int start, int count) {
    float p = 0.0f;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i) {
        p = std::max(p, std::abs(samples[static_cast<size_t>(i)]));
    }
    return p;
}

/// Create a project with one track containing an oscillator at reduced gain
/// and a sustained MIDI note. The oscillator produces a ~-10 dBFS 440 Hz sine.
struct EffectTestSetup {
    audioapp::EngineHost host;
    std::string trackId;
    std::string oscId;

    EffectTestSetup() {
        host.createProject();
        trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        oscId = host.addDeviceToTrack(trackId, "simple_oscillator");
        // Reduce oscillator gain so the signal sits at ~−10 dBFS, well
        // inside the threshold range [−60 dB, −6 dB] of the dynamics effects.
        host.setDeviceParameter(oscId, "gain", 0.3f);
    }

    void addMidiNote() {
        const std::string clipId = host.createMidiClip(trackId, 0.0, 4.0);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        host.setMidiClipNotes(clipId, notes);
    }
};

/// Render 4 beats at 48000 Hz sample rate. Split into 8 half-beat windows.
struct RenderedAudio {
    std::vector<float> samples;
    int windowFrames;
    static constexpr int kWindows = 8;

    explicit RenderedAudio(const std::vector<float>& s)
        : samples(s), windowFrames(static_cast<int>(s.size()) / kWindows) {}

    int windowStart(int w) const { return w * windowFrames; }
    float windowRms(int w) const { return rms(samples, windowStart(w), windowFrames); }
    float windowPeak(int w) const { return peak(samples, windowStart(w), windowFrames); }
};

} // namespace

int main() {
    using namespace audioapp;

    // =====================================================================
    // Test 1: Automation on Compressor threshold
    //
    // compThreshold ramp: 0.0 → 1.0  (thresholdDb: −60 dB → −6 dB)
    // The signal at ≈−10 dBFS is above the threshold at both ends, but the
    // amount of gain reduction changes. Makeup gain is applied in both cases.
    //
    //   At threshold = −60 dB: heavy GR, output is quiet
    //   At threshold =  −6 dB: light GR, output is louder
    //
    // Expectation: early RMS < late RMS
    // =====================================================================
    {
        EffectTestSetup setup;
        const std::string compId = setup.host.addDeviceToTrack(setup.trackId, "compressor");
        setup.addMidiNote();

        // Automation clip: ramp compThreshold from 0.0 → 1.0 over 4 beats
        const std::string autoClipId = setup.host.createAutomationClip(setup.trackId, 0.0, 4.0);
        if (autoClipId.empty()) return EXIT_FAILURE;
        if (!setup.host.assignAutomationTarget(autoClipId, compId, "compThreshold")) {
            return EXIT_FAILURE;
        }
        std::vector<AutomationPointState> points;
        points.push_back({0.0, 0.0f});  // threshold = −60 dB:  everything compressed
        points.push_back({4.0, 1.0f});  // threshold =  −6 dB:  only peaks compressed
        if (!setup.host.setAutomationPoints(autoClipId, points)) return EXIT_FAILURE;

        setup.host.setPlaying(true);
        const RenderedAudio audio(setup.host.renderOffline(4.0, 48000.0));
        if (audio.samples.size() < 48000) return EXIT_FAILURE;
        if (audio.windowRms(0) < 1.0e-6f) return EXIT_FAILURE;
        if (audio.windowRms(7) < 1.0e-6f) return EXIT_FAILURE;

        // Early: threshold very low → heavy compression → quieter.
        // Late:  threshold higher  →  light compression → louder.
        const float earlySum = audio.windowRms(0) + audio.windowRms(1);
        const float lateSum  = audio.windowRms(6) + audio.windowRms(7);
        if (lateSum < earlySum * 1.05f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 2: Automation on Gate threshold
    //
    // gateThreshold ramp: 1.0 → 0.0  (thresholdDb: −6 dB → −60 dB)
    // Signal at ≈−10 dBFS:
    //   At threshold =  −6 dB: signal is JUST below → gate mostly closed, quiet
    //   At threshold = −60 dB: signal is well above → gate fully open, louder
    //
    // Expectation: early RMS < late RMS
    // =====================================================================
    {
        EffectTestSetup setup;
        const std::string gateId = setup.host.addDeviceToTrack(setup.trackId, "gate");
        setup.addMidiNote();

        // Automation clip: ramp gateThreshold from 1.0 → 0.0 over 4 beats
        const std::string autoClipId = setup.host.createAutomationClip(setup.trackId, 0.0, 4.0);
        if (autoClipId.empty()) return EXIT_FAILURE;
        if (!setup.host.assignAutomationTarget(autoClipId, gateId, "gateThreshold")) {
            return EXIT_FAILURE;
        }
        std::vector<AutomationPointState> points;
        points.push_back({0.0, 1.0f});  // threshold =  −6 dB:  gate mostly closed
        points.push_back({4.0, 0.0f});  // threshold = −60 dB:  gate always open
        if (!setup.host.setAutomationPoints(autoClipId, points)) return EXIT_FAILURE;

        setup.host.setPlaying(true);
        const RenderedAudio audio(setup.host.renderOffline(4.0, 48000.0));
        if (audio.samples.size() < 48000) return EXIT_FAILURE;
        if (audio.windowRms(0) < 1.0e-6f) return EXIT_FAILURE;
        if (audio.windowRms(7) < 1.0e-6f) return EXIT_FAILURE;

        // Early: threshold high → gate closed more often → quieter.
        // Late:  threshold low  → gate always open     → louder.
        const float earlySum = audio.windowRms(0) + audio.windowRms(1);
        const float lateSum  = audio.windowRms(6) + audio.windowRms(7);
        if (lateSum < earlySum * 1.02f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 3: Automation on Expander threshold
    //
    // expandThreshold ramp: 0.0 → 1.0  (thresholdDb: −60 dB → −6 dB)
    // Signal at ≈−10 dBFS:
    //   At threshold = −60 dB: signal is well above → no expansion, louder
    //   At threshold =  −6 dB: signal is below     → expansion, quieter
    //
    // Expectation: early RMS > late RMS
    // =====================================================================
    {
        EffectTestSetup setup;
        const std::string expanderId = setup.host.addDeviceToTrack(setup.trackId, "expander");
        setup.addMidiNote();

        // Automation clip: ramp expandThreshold from 0.0 → 1.0 over 4 beats
        const std::string autoClipId = setup.host.createAutomationClip(setup.trackId, 0.0, 4.0);
        if (autoClipId.empty()) return EXIT_FAILURE;
        if (!setup.host.assignAutomationTarget(autoClipId, expanderId, "expandThreshold")) {
            return EXIT_FAILURE;
        }
        std::vector<AutomationPointState> points;
        points.push_back({0.0, 0.0f});  // threshold = −60 dB: signal well above → no expansion
        points.push_back({4.0, 1.0f});  // threshold =  −6 dB: signal below     → expansion
        if (!setup.host.setAutomationPoints(autoClipId, points)) return EXIT_FAILURE;

        setup.host.setPlaying(true);
        const RenderedAudio audio(setup.host.renderOffline(4.0, 48000.0));
        if (audio.samples.size() < 48000) return EXIT_FAILURE;
        if (audio.windowRms(0) < 1.0e-6f) return EXIT_FAILURE;
        if (audio.windowRms(7) < 1.0e-6f) return EXIT_FAILURE;

        // Early: no expansion → signal passes through at full level.
        // Late:  expansion active → signal attenuated.
        const float earlySum = audio.windowRms(0) + audio.windowRms(1);
        const float lateSum  = audio.windowRms(6) + audio.windowRms(7);
        if (earlySum < lateSum * 1.02f) return EXIT_FAILURE;
    }

    // =====================================================================
    // Test 4: Automation on Limiter ceiling
    //
    // limitCeiling ramp: 0.0 → 1.0  (ceilingDb: −12 dB → 0 dBFS)
    // Signal peak at ≈−10 dBFS:
    //   At ceiling = −12 dB: peaks are clamped (lower peak value)
    //   At ceiling =   0 dB: peaks pass unclamped (full peak value)
    //
    // Expectation: early peak < late peak
    // =====================================================================
    {
        EffectTestSetup setup;
        const std::string limiterId = setup.host.addDeviceToTrack(setup.trackId, "limiter");
        setup.addMidiNote();

        // Automation clip: ramp limitCeiling from 0.0 → 1.0 over 4 beats
        const std::string autoClipId = setup.host.createAutomationClip(setup.trackId, 0.0, 4.0);
        if (autoClipId.empty()) return EXIT_FAILURE;
        if (!setup.host.assignAutomationTarget(autoClipId, limiterId, "limitCeiling")) {
            return EXIT_FAILURE;
        }
        std::vector<AutomationPointState> points;
        points.push_back({0.0, 0.0f});  // ceiling = −12 dB:  peaks clamped
        points.push_back({4.0, 1.0f});  // ceiling =   0 dB:  peaks pass through
        if (!setup.host.setAutomationPoints(autoClipId, points)) return EXIT_FAILURE;

        setup.host.setPlaying(true);
        const RenderedAudio audio(setup.host.renderOffline(4.0, 48000.0));
        if (audio.samples.size() < 48000) return EXIT_FAILURE;

        // Early: low ceiling → peaks hard-clamped → lower peak value.
        // Late:  high ceiling → peaks pass unclamped → higher peak value.
        const float earlyPk = audio.windowPeak(0) + audio.windowPeak(1);
        const float latePk  = audio.windowPeak(7);
        if (earlyPk <= 0.0f || latePk <= 0.0f) return EXIT_FAILURE;
        if (latePk < earlyPk * 1.10f) return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}