// Verifies that a frozen track sounds like the live track it replaced.
//
// Freeze is only safe to apply on the user's behalf if substituting baked audio
// is inaudible. Each scenario renders the project live, freezes, renders again,
// and requires the difference to sit below a residual floor. Anything that fails
// here is a track that must not be frozen automatically.

#include "audioapp/EngineHost.hpp"

#include <juce_core/juce_core.h>

#include <algorithm>
#include <cmath>
#include <functional>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

namespace {

int failures = 0;

constexpr double kRenderBeats = 4.0;
constexpr double kRenderSampleRate = 48000.0;
// -90 dBFS is well below anything audible under a full mix and leaves room for
// float accumulation order differing between the bake and the live mix path.
constexpr double kResidualFloorDb = -90.0;

double peakDb(const std::vector<float>& audio) {
    double peak = 0.0;
    for (float sample : audio) {
        peak = std::max(peak, std::abs(static_cast<double>(sample)));
    }
    return peak <= 0.0 ? -200.0 : 20.0 * std::log10(peak);
}

std::vector<float> difference(const std::vector<float>& a, const std::vector<float>& b) {
    const size_t count = std::min(a.size(), b.size());
    std::vector<float> out(count, 0.0f);
    for (size_t i = 0; i < count; ++i) {
        out[i] = a[i] - b[i];
    }
    return out;
}

void report(const char* scenario, double referenceDb, double residualDb, bool ok) {
    std::cout << (ok ? "  ok   " : "  FAIL ") << std::left << std::setw(34) << scenario
              << " reference " << std::fixed << std::setprecision(1) << referenceDb
              << " dBFS, residual " << residualDb << " dBFS\n";
}

using SceneBuilder = std::function<std::string(audioapp::EngineHost&)>;

/// Renders live, freezes `trackId`, renders again, and compares.
///
/// Each render gets its own engine because renderOffline does not reset DSP
/// state on entry: effect tails and envelope followers would otherwise survive
/// into the next render and swamp the comparison.
void checkFreezeIsTransparent(const char* scenario, const SceneBuilder& build) {
    const auto renderScene = [&](bool freeze, bool& ok) {
        audioapp::EngineHost host;
        host.createProject();
        const std::string trackId = build(host);
        if (trackId.empty()) {
            ok = false;
            return std::vector<float>{};
        }
        if (freeze && !host.freezeTrack(trackId)) {
            ok = false;
            return std::vector<float>{};
        }
        ok = true;
        return host.renderOffline(kRenderBeats, kRenderSampleRate);
    };

    bool built = false;
    const auto live = renderScene(false, built);
    if (!built) {
        ++failures;
        std::cerr << "  FAIL " << scenario << " — scenario setup failed\n";
        return;
    }
    // Two identically built projects must render identically, otherwise the
    // scenario is not deterministic and a freeze comparison proves nothing.
    const auto liveAgain = renderScene(false, built);
    const double repeatabilityDb = peakDb(difference(live, liveAgain));
    if (repeatabilityDb > kResidualFloorDb) {
        ++failures;
        report(scenario, peakDb(live), repeatabilityDb, false);
        std::cerr << "         scenario is not deterministic; cannot judge freeze\n";
        return;
    }

    const auto frozen = renderScene(true, built);
    if (!built) {
        ++failures;
        std::cerr << "  FAIL " << scenario << " — freeze rejected\n";
        return;
    }

    const double referenceDb = peakDb(live);
    const double residualDb = peakDb(difference(live, frozen));
    const bool ok = referenceDb > -80.0 && residualDb <= kResidualFloorDb;
    if (!ok) {
        ++failures;
    }
    report(scenario, referenceDb, residualDb, ok);
}

std::vector<audioapp::MidiNoteState> chordPattern() {
    return {
        {48, 0.0, 0.9, 110.0f},
        {55, 1.0, 0.9, 96.0f},
        {60, 2.0, 0.9, 104.0f},
        {64, 3.0, 0.9, 88.0f},
    };
}

/// A new track only carries track_gain, so the instrument is added explicitly.
std::string addSynthTrack(audioapp::EngineHost& host, const char* name) {
    const auto trackId = host.addTrack(name);
    if (trackId.empty() || host.addDeviceToTrack(trackId, "subtractive_synth").empty()) {
        return {};
    }
    const auto clipId = host.createMidiClip(trackId, 0.0, 4.0);
    if (clipId.empty() || !host.setMidiClipNotes(clipId, chordPattern())) {
        return {};
    }
    return trackId;
}

} // namespace

int main() {
    std::cout << "freeze transparency (residual must be <= " << kResidualFloorDb
              << " dBFS)\n";

    checkFreezeIsTransparent("sample clip only", [](audioapp::EngineHost& host) {
        const auto trackId = host.addTrack("Sample");
        return host.createSampleClip(trackId, "sample_kick", 0.0, 2.0).empty()
                   ? std::string{}
                   : trackId;
    });

    checkFreezeIsTransparent("instrument + midi", [](audioapp::EngineHost& host) {
        return addSynthTrack(host, "Synth");
    });

    checkFreezeIsTransparent("instrument + filter", [](audioapp::EngineHost& host) {
        const auto trackId = addSynthTrack(host, "Synth");
        if (trackId.empty() || host.addDeviceToTrack(trackId, "filter").empty()) {
            return std::string{};
        }
        return trackId;
    });

    checkFreezeIsTransparent("block-rate lfo on filter", [](audioapp::EngineHost& host) {
        const auto trackId = addSynthTrack(host, "Synth");
        if (trackId.empty()) {
            return std::string{};
        }
        const auto filterId = host.addDeviceToTrack(trackId, "filter");
        if (filterId.empty()) {
            return std::string{};
        }
        const int lfoId = host.createLfo();
        if (lfoId <= 0 || !host.assignModulation(lfoId, filterId, "ffxCutoff", 0.6f)) {
            return std::string{};
        }
        return trackId;
    });

    checkFreezeIsTransparent("per-note lfo on filter", [](audioapp::EngineHost& host) {
        const auto trackId = addSynthTrack(host, "Synth");
        if (trackId.empty()) {
            return std::string{};
        }
        const auto filterId = host.addDeviceToTrack(trackId, "filter");
        if (filterId.empty()) {
            return std::string{};
        }
        const int lfoId = host.createLfo();
        if (lfoId <= 0) {
            return std::string{};
        }
        // Retrigger mode 2 = OnNote, the case the bake used to skip entirely.
        host.updateLfoParam(lfoId, "retrigger", 2.0f);
        if (!host.assignModulation(lfoId, filterId, "ffxCutoff", 0.6f)) {
            return std::string{};
        }
        return trackId;
    });

    checkFreezeIsTransparent("automation on filter cutoff", [](audioapp::EngineHost& host) {
        const auto trackId = addSynthTrack(host, "Synth");
        if (trackId.empty()) {
            return std::string{};
        }
        const auto filterId = host.addDeviceToTrack(trackId, "filter");
        if (filterId.empty()) {
            return std::string{};
        }
        const auto clipId = host.createAutomationClip(trackId, 0.0, 4.0);
        if (clipId.empty() || !host.assignAutomationTarget(clipId, filterId, "ffxCutoff")) {
            return std::string{};
        }
        const std::vector<audioapp::AutomationPointState> points{
            {0.0, 0.15f}, {2.0, 0.9f}, {4.0, 0.25f}};
        if (!host.setAutomationPoints(clipId, points)) {
            return std::string{};
        }
        return trackId;
    });

    checkFreezeIsTransparent("stateful fx (delay)", [](audioapp::EngineHost& host) {
        const auto trackId = addSynthTrack(host, "Synth");
        if (trackId.empty() || host.addDeviceToTrack(trackId, "delay").empty()) {
            return std::string{};
        }
        return trackId;
    });

    // The ducker reads another track's audio. Baking it would capture a silent
    // sidechain, so the split has to leave it running live.
    checkFreezeIsTransparent("ducker keyed off other track", [](audioapp::EngineHost& host) {
        const auto keyTrack = host.addTrack("Key");
        if (host.createSampleClip(keyTrack, "sample_kick", 0.0, 4.0).empty()) {
            return std::string{};
        }
        const auto trackId = addSynthTrack(host, "Pad");
        if (trackId.empty()) {
            return std::string{};
        }
        const auto duckerId = host.addDeviceToTrack(trackId, "ducker");
        if (duckerId.empty()) {
            return std::string{};
        }
        if (!host.setDeviceStringParameter(duckerId, "sidechainSourceId",
                                           "track-audio:" + keyTrack)) {
            return std::string{};
        }
        host.setDeviceParameter(duckerId, "duckDepth", 0.9f);
        return trackId;
    });

    if (failures > 0) {
        std::cerr << failures << " freeze transparency check(s) failed\n";
        return 1;
    }
    std::cout << "All freeze transparency checks passed\n";
    return 0;
}
