// Temporary audit probe for optimistic/auto freeze planning. Not a unit test:
// it prints measurements used to confirm or refute specific claims about the
// current freeze implementation. Safe to delete.

#include "audioapp/EngineHost.hpp"

#include <juce_core/juce_core.h>
#include <pthread.h>
#include <cerrno>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

namespace {

double peakDb(const std::vector<float>& audio, size_t from = 0, size_t to = SIZE_MAX) {
    double peak = 0.0;
    const size_t end = std::min(to, audio.size());
    for (size_t i = from; i < end; ++i) {
        peak = std::max(peak, std::abs(static_cast<double>(audio[i])));
    }
    return peak <= 0.0 ? -200.0 : 20.0 * std::log10(peak);
}

std::vector<float> diff(const std::vector<float>& a, const std::vector<float>& b) {
    const size_t n = std::min(a.size(), b.size());
    std::vector<float> out(n, 0.0f);
    for (size_t i = 0; i < n; ++i) out[i] = a[i] - b[i];
    return out;
}

bool trackReportsStale(const audioapp::EngineHost& host) {
    const auto json = host.getProjectSnapshotJson();
    const auto pos = json.find("\"freeze\"");
    if (pos == std::string::npos) return false;
    const auto stalePos = json.find("\"stale\"", pos);
    if (stalePos == std::string::npos) return false;
    return json.compare(stalePos + 8, 40, ": true", 0, 6) == 0 ||
           json.find("true", stalePos) - stalePos < 12;
}

std::vector<audioapp::MidiNoteState> chord() {
    return {{48, 0.0, 0.9, 110.0f}, {55, 1.0, 0.9, 96.0f},
            {60, 2.0, 0.9, 104.0f}, {64, 3.0, 0.9, 88.0f}};
}

std::string buildSynthTrack(audioapp::EngineHost& host, const char* extraFx) {
    const auto trackId = host.addTrack("T");
    if (host.addDeviceToTrack(trackId, "subtractive_synth").empty()) return {};
    if (extraFx != nullptr && host.addDeviceToTrack(trackId, extraFx).empty()) return {};
    const auto clipId = host.createMidiClip(trackId, 0.0, 4.0);
    if (clipId.empty() || !host.setMidiClipNotes(clipId, chord())) return {};
    return trackId;
}

void probeTailTruncation() {
    std::cout << "\n[A] effect tail beyond last clip end (clip 0-4, render 8 beats)\n";
    const auto render = [](bool freeze, const char* fx) {
        audioapp::EngineHost host;
        host.createProject();
        const auto trackId = buildSynthTrack(host, fx);
        if (trackId.empty()) return std::vector<float>{};
        if (freeze && !host.freezeTrack(trackId)) {
            std::cout << "    freeze rejected for fx=" << fx << "\n";
            return std::vector<float>{};
        }
        return host.renderOffline(8.0, 48000.0);
    };
    for (const char* fx : {"delay", "reverb"}) {
        const auto live = render(false, fx);
        const auto frozen = render(true, fx);
        if (live.empty() || frozen.empty()) continue;
        // Beats 4..8 = second half of the render.
        const size_t half = live.size() / 2;
        std::cout << "    fx=" << std::setw(7) << std::left << fx
                  << " live tail(beats 4-8) " << std::fixed << std::setprecision(1)
                  << peakDb(live, half) << " dBFS, frozen tail "
                  << peakDb(frozen, half, frozen.size()) << " dBFS, residual(0-8) "
                  << peakDb(diff(live, frozen)) << " dBFS\n";
    }
}

void probeStalePlaysOldAudio() {
    std::cout << "\n[B] edit a frozen track: does playback follow the edit?\n";
    audioapp::EngineHost host;
    host.createProject();
    const auto trackId = host.addTrack("T");
    host.addDeviceToTrack(trackId, "subtractive_synth");
    const auto clipId = host.createMidiClip(trackId, 0.0, 4.0);
    host.setMidiClipNotes(clipId, chord());
    if (!host.freezeTrack(trackId)) { std::cout << "    freeze rejected\n"; return; }
    const auto frozenBefore = host.renderOffline(4.0, 48000.0);

    // Transpose every note two octaves down: unmistakably different audio.
    std::vector<audioapp::MidiNoteState> edited = chord();
    for (auto& note : edited) note.pitch -= 24;
    const bool editAccepted = host.setMidiClipNotes(clipId, edited);
    const bool stale = trackReportsStale(host);
    const auto frozenAfter = host.renderOffline(4.0, 48000.0);

    audioapp::EngineHost liveHost;
    liveHost.createProject();
    const auto liveTrack = liveHost.addTrack("T");
    liveHost.addDeviceToTrack(liveTrack, "subtractive_synth");
    const auto liveClip = liveHost.createMidiClip(liveTrack, 0.0, 4.0);
    liveHost.setMidiClipNotes(liveClip, edited);
    const auto liveEdited = liveHost.renderOffline(4.0, 48000.0);

    std::cout << "    setMidiClipNotes on frozen track accepted: "
              << (editAccepted ? "yes" : "no") << ", snapshot stale flag: "
              << (stale ? "true" : "false") << "\n"
              << "    frozen-after-edit vs frozen-before-edit residual "
              << std::fixed << std::setprecision(1)
              << peakDb(diff(frozenAfter, frozenBefore)) << " dBFS"
              << "   (~-200 = playback ignored the edit)\n"
              << "    frozen-after-edit vs live-edited residual        "
              << peakDb(diff(frozenAfter, liveEdited)) << " dBFS"
              << "   (loud = audibly wrong audio)\n";
}

void probeBpmChange() {
    std::cout << "\n[C] tempo change while frozen\n";
    audioapp::EngineHost host;
    host.createProject();
    const auto trackId = host.addTrack("T");
    host.createSampleClip(trackId, "sample_kick", 0.0, 2.0);
    if (!host.freezeTrack(trackId)) { std::cout << "    freeze rejected\n"; return; }
    const auto at120 = host.renderOffline(2.0, 48000.0);
    host.setBpm(160);
    const bool stale = trackReportsStale(host);
    const auto frozenAt160 = host.renderOffline(2.0, 48000.0);

    audioapp::EngineHost liveHost;
    liveHost.createProject();
    const auto liveTrack = liveHost.addTrack("T");
    liveHost.createSampleClip(liveTrack, "sample_kick", 0.0, 2.0);
    liveHost.setBpm(160);
    const auto liveAt160 = liveHost.renderOffline(2.0, 48000.0);

    std::cout << "    stale flag after setBpm: " << (stale ? "true" : "false") << "\n"
              << "    frozen@160 vs live@160 residual " << std::fixed
              << std::setprecision(1) << peakDb(diff(frozenAt160, liveAt160))
              << " dBFS (reference " << peakDb(liveAt160) << " dBFS)\n"
              << "    frame counts: frozen@120 " << at120.size()
              << ", frozen@160 " << frozenAt160.size() << "\n";
}

void probeNestedDeviceInvalidation() {
    std::cout << "\n[D] parameter change on a device nested inside a baked container\n";
    audioapp::EngineHost host;
    host.createProject();
    const auto trackId = host.addTrack("T");
    host.addDeviceToTrack(trackId, "subtractive_synth");
    const auto chainId = host.addDeviceToTrack(trackId, "device_chain");
    if (chainId.empty()) { std::cout << "    chain device unavailable\n"; return; }
    const auto nestedId = host.addDeviceToChain(chainId, "filter", -1);
    if (nestedId.empty()) { std::cout << "    nested filter unavailable\n"; return; }
    const auto clipId = host.createMidiClip(trackId, 0.0, 4.0);
    host.setMidiClipNotes(clipId, chord());
    if (!host.freezeTrack(trackId)) { std::cout << "    freeze rejected\n"; return; }
    const auto before = host.renderOffline(4.0, 48000.0);

    const bool applied = host.setDeviceParameter(nestedId, "gain", 0.25f);
    const bool staleNested = trackReportsStale(host);

    // For contrast: the same edit on a top-level baked device.
    audioapp::EngineHost host2;
    host2.createProject();
    const auto track2 = host2.addTrack("T");
    host2.addDeviceToTrack(track2, "subtractive_synth");
    const auto topFilter = host2.addDeviceToTrack(track2, "filter");
    const auto clip2 = host2.createMidiClip(track2, 0.0, 4.0);
    host2.setMidiClipNotes(clip2, chord());
    host2.freezeTrack(track2);
    host2.setDeviceParameter(topFilter, "ffxCutoff", 0.08f);
    const bool staleTop = trackReportsStale(host2);

    std::cout << "    nested setDeviceParameter accepted: " << (applied ? "yes" : "no")
              << ", stale flag: " << (staleNested ? "true" : "false") << "\n"
              << "    top-level equivalent stale flag:  " << (staleTop ? "true" : "false")
              << "\n";
    (void)before;
}

void probeBpmChangeSynth() {
    std::cout << "\n[C2] tempo change while frozen, MIDI/synth track\n";
    audioapp::EngineHost host;
    host.createProject();
    const auto trackId = buildSynthTrack(host, nullptr);
    if (trackId.empty() || !host.freezeTrack(trackId)) {
        std::cout << "    freeze rejected\n";
        return;
    }
    host.setBpm(160);
    const auto frozenAt160 = host.renderOffline(4.0, 48000.0);

    audioapp::EngineHost liveHost;
    liveHost.createProject();
    buildSynthTrack(liveHost, nullptr);
    liveHost.setBpm(160);
    const auto liveAt160 = liveHost.renderOffline(4.0, 48000.0);

    std::cout << "    frozen@160 vs live@160 residual " << std::fixed
              << std::setprecision(1) << peakDb(diff(frozenAt160, liveAt160))
              << " dBFS (reference " << peakDb(liveAt160)
              << " dBFS, transparency floor -90)\n";
}

void probeMidArrangementStart() {
    std::cout << "\n[E] frozen vs live when the bake is beat-anchored (random S&H modulator)\n";
    const auto build = [](audioapp::EngineHost& host) {
        const auto trackId = host.addTrack("T");
        host.addDeviceToTrack(trackId, "subtractive_synth");
        const auto filterId = host.addDeviceToTrack(trackId, "filter");
        const auto clipId = host.createMidiClip(trackId, 0.0, 8.0);
        std::vector<audioapp::MidiNoteState> notes;
        for (int i = 0; i < 8; ++i)
            notes.push_back({48 + i, static_cast<double>(i), 0.9, 100.0f});
        host.setMidiClipNotes(clipId, notes);
        // modulatorType 3 is looked up by index; fall back silently if absent.
        const int lfoId = host.createLfo(3);
        if (lfoId > 0) {
            host.updateLfoParam(lfoId, "retrigger", 1.0f);  // Sync
            host.assignModulation(lfoId, filterId, "ffxCutoff", 0.7f);
        }
        return trackId;
    };
    audioapp::EngineHost liveHost;
    liveHost.createProject();
    build(liveHost);
    const auto live = liveHost.renderOffline(8.0, 48000.0);

    audioapp::EngineHost frozenHost;
    frozenHost.createProject();
    const auto trackId = build(frozenHost);
    if (!frozenHost.freezeTrack(trackId)) { std::cout << "    freeze rejected\n"; return; }
    const auto frozen = frozenHost.renderOffline(8.0, 48000.0);
    std::cout << "    residual over full 8 beats " << std::fixed << std::setprecision(1)
              << peakDb(diff(live, frozen)) << " dBFS (reference " << peakDb(live)
              << " dBFS)\n";
}

void probeBakeSizeForLateContent() {
    std::cout << "\n[F] bake length when content starts late (clip at beat 120, 1 beat long)\n";
    audioapp::EngineHost host;
    host.createProject();
    const auto trackId = host.addTrack("T");
    host.createSampleClip(trackId, "sample_kick", 120.0, 1.0);
    if (!host.freezeTrack(trackId)) { std::cout << "    freeze rejected\n"; return; }
    const auto json = host.getProjectSnapshotJson();
    const auto pos = json.find("\"lengthBeats\"", json.find("\"freeze\""));
    std::cout << "    freeze metadata: "
              << (pos == std::string::npos ? std::string("n/a")
                                          : json.substr(pos, 40))
              << "\n    (bake always starts at beat 0, so leading silence is stored as PCM)\n";
}

/// The bake split only protects a cross-track reader it can see. isTappedSource
/// walks top-level devices of every track, so a ducker nested in a chain is
/// invisible and the source it keys off can be baked away.
void probeNestedSidechainBlindSpot() {
    std::cout << "\n[G] sidechain consumer nested inside a chain on another track\n";
    // A device-level source is the interesting case: isTappedSource matches on
    // device ids, so it is the one the split has to notice.
    const auto run = [](bool nestTheDucker, bool deviceLevelSource) {
        audioapp::EngineHost host;
        host.createProject();
        const auto keyTrack = host.addTrack("Key");
        const auto keySynth = host.addDeviceToTrack(keyTrack, "subtractive_synth");
        const auto keyClip = host.createMidiClip(keyTrack, 0.0, 4.0);
        host.setMidiClipNotes(keyClip, chord());
        host.addDeviceToTrack(keyTrack, "filter");

        const auto padTrack = host.addTrack("Pad");
        host.createSampleClip(padTrack, "sample_kick", 0.0, 4.0);
        std::string duckerId;
        if (nestTheDucker) {
            const auto chainId = host.addDeviceToTrack(padTrack, "device_chain");
            duckerId = host.addDeviceToChain(chainId, "ducker", -1);
        } else {
            duckerId = host.addDeviceToTrack(padTrack, "ducker");
        }
        if (duckerId.empty()) {
            std::cout << "    ducker unavailable (nested=" << nestTheDucker << ")\n";
            return;
        }
        const std::string sourceId =
            deviceLevelSource ? keySynth : ("track-audio:" + keyTrack);
        host.setDeviceStringParameter(duckerId, "sidechainSourceId", sourceId);
        host.setDeviceParameter(duckerId, "duckDepth", 0.9f);

        const auto liveMix = host.renderOffline(4.0, 48000.0);
        const bool froze = host.freezeTrack(keyTrack);
        const auto frozenMix = host.renderOffline(4.0, 48000.0);
        std::cout << "    source=" << (deviceLevelSource ? "device" : "track ")
                  << " ducker=" << (nestTheDucker ? "nested in chain" : "top level     ")
                  << ": froze=" << (froze ? "yes" : "no ") << ", mix residual "
                  << std::fixed << std::setprecision(1)
                  << peakDb(diff(liveMix, frozenMix)) << " dBFS (reference "
                  << peakDb(liveMix) << " dBFS)\n";
    };
    run(false, false);
    run(true, false);
    run(false, true);
    run(true, true);
}

/// Static TLS is charged against the worker stack, so the bake needs a stack far
/// larger than any platform default before it can run off the caller thread.
void probeWorkerThreadBake() {
    std::cout << "\n[H] bake off the caller thread, concurrent with rendering\n";
    audioapp::EngineHost host;
    host.createProject();
    const auto trackId = host.addTrack("T");
    host.addDeviceToTrack(trackId, "subtractive_synth");
    const auto clipId = host.createMidiClip(trackId, 0.0, 64.0);
    std::vector<audioapp::MidiNoteState> notes;
    for (int i = 0; i < 64; ++i)
        notes.push_back({48 + (i % 12), static_cast<double>(i), 0.9, 100.0f});
    host.setMidiClipNotes(clipId, notes);
    host.setPlaying(true);

    struct Args {
        audioapp::EngineHost* host;
        std::string trackId;
        std::atomic<bool> done;
        bool committed;
        long long micros;
    } args{&host, trackId, {false}, false, 0};

    const auto entry = +[](void* raw) -> void* {
        auto* a = static_cast<Args*>(raw);
        const auto t0 = std::chrono::steady_clock::now();
        a->committed = a->host->freezeTrack(a->trackId);
        a->micros = std::chrono::duration_cast<std::chrono::microseconds>(
                        std::chrono::steady_clock::now() - t0)
                        .count();
        a->done.store(true, std::memory_order_release);
        return nullptr;
    };

    // 25.3 MiB of static TLS is carved out of the worker's stack mapping, so a
    // stack anywhere near a platform default is rejected outright.
    for (unsigned stackMiB : {1u, 8u, 96u}) {
        pthread_attr_t attr;
        pthread_attr_init(&attr);
        pthread_attr_setstacksize(&attr, static_cast<size_t>(stackMiB) * 1024u * 1024u);
        args.committed = false;
        args.micros = 0;
        args.done.store(false, std::memory_order_release);
        pthread_t worker{};
        const int rc = pthread_create(&worker, &attr, entry, &args);
        pthread_attr_destroy(&attr);
        if (rc != 0) {
            std::cout << "    stack " << std::setw(3) << stackMiB
                      << " MiB: pthread_create failed rc=" << rc
                      << (rc == EINVAL ? " (EINVAL: stack < static TLS)" : "") << "\n";
            continue;
        }
        // Render on this thread meanwhile: that is the audio callback's role.
        float left[512];
        float right[512];
        double beat = 0.0;
        long long worstMicros = 0;
        long long blocks = 0;
        while (!args.done.load(std::memory_order_acquire)) {
            const auto t0 = std::chrono::steady_clock::now();
            host.readMasterMixStereo(left, right, 512, 48000.0, beat);
            worstMicros = std::max(
                worstMicros,
                static_cast<long long>(
                    std::chrono::duration_cast<std::chrono::microseconds>(
                        std::chrono::steady_clock::now() - t0)
                        .count()));
            beat += 512.0 / 48000.0 * 2.0;
            ++blocks;
        }
        pthread_join(worker, nullptr);
        std::cout << "    stack " << std::setw(3) << stackMiB << " MiB: bake "
                  << (args.committed ? "committed" : "rejected ") << " in "
                  << args.micros / 1000 << " ms; " << blocks
                  << " blocks rendered meanwhile, worst block "
                  << std::fixed << std::setprecision(2) << worstMicros / 1000.0
                  << " ms (512 frames at 48k must finish in 10.67 ms)\n";
        host.unfreezeTrack(trackId);
    }
}

void probeGuiParameterVisibility() {
    std::cout << "\n[I] GUI effective parameter on a baked, modulated device\n";
    const auto readCutoff = [](bool freeze) {
        audioapp::EngineHost host;
        host.createProject();
        const auto trackId = host.addTrack("T");
        host.addDeviceToTrack(trackId, "subtractive_synth");
        const auto filterId = host.addDeviceToTrack(trackId, "filter");
        const auto clipId = host.createMidiClip(trackId, 0.0, 4.0);
        host.setMidiClipNotes(clipId, chord());
        const int lfoId = host.createLfo();
        host.assignModulation(lfoId, filterId, "ffxCutoff", 0.9f);
        host.selectTrack(trackId);
        if (freeze && !host.freezeTrack(trackId)) std::cout << "    freeze rejected\n";
        host.setPlaying(true);

        // Drive real blocks so the DSP publishes presentation values, then
        // sample the reported value at several playhead positions.
        float left[512];
        float right[512];
        std::vector<std::string> samples;
        for (int block = 0; block < 24; ++block) {
            const double beat = static_cast<double>(block) * 512.0 / 48000.0 * 2.0;
            host.readMasterMixStereo(left, right, 512, 48000.0, beat);
            if (block % 8 == 7) {
                samples.push_back(host.readEffectiveParameterJson(filterId, "ffxCutoff"));
            }
        }
        std::cout << "    " << (freeze ? "frozen" : "live  ") << " selected track:\n";
        for (const auto& s : samples) std::cout << "        " << s << "\n";
    };
    readCutoff(false);
    readCutoff(true);
}

void probeMetersAndTapsOnBakedDevice() {
    std::cout << "\n[J] meters and graph taps on a device that got baked away\n";
    const auto run = [](bool freeze) {
        audioapp::EngineHost host;
        host.createProject();
        const auto trackId = host.addTrack("T");
        host.addDeviceToTrack(trackId, "subtractive_synth");
        const auto filterId = host.addDeviceToTrack(trackId, "filter");
        const auto clipId = host.createMidiClip(trackId, 0.0, 4.0);
        host.setMidiClipNotes(clipId, chord());
        host.setMeterSubscriptions({filterId});
        const auto deviceTap =
            host.createGraphTap(filterId, audioapp::GraphTapKind::Analyzer);
        const auto trackTap =
            host.createGraphTap(trackId, audioapp::GraphTapKind::Analyzer);
        if (freeze && !host.freezeTrack(trackId)) std::cout << "    freeze rejected\n";
        host.setPlaying(true);
        float left[512];
        float right[512];
        for (int block = 0; block < 40; ++block) {
            host.readMasterMixStereo(left, right, 512, 48000.0,
                                     static_cast<double>(block) * 512.0 / 48000.0 * 2.0);
        }
        const auto tapPeak = [&](const std::string& tapId) {
            const auto json = host.readGraphTapJson(tapId, 256);
            const auto seqPos = json.find("\"sequence\"");
            const auto peakPos = json.find("\"peakL\"");
            return (seqPos == std::string::npos ? std::string("no sequence")
                                               : json.substr(seqPos, 22)) +
                   " " +
                   (peakPos == std::string::npos ? std::string("no peakL")
                                                 : json.substr(peakPos, 20));
        };
        std::cout << "    " << (freeze ? "frozen" : "live  ") << ": device tap "
                  << tapPeak(deviceTap) << "\n"
                  << "            track tap  " << tapPeak(trackTap) << "\n"
                  << "            meters " << host.getDeviceMetersJson() << "\n";
    };
    run(false);
    run(true);
}

void probeSnapshotCostAndMemory() {
    std::cout << "\n[K] snapshot size and asset memory as tracks are frozen\n";
    audioapp::EngineHost host;
    host.createProject();
    std::vector<std::string> tracks;
    for (int t = 0; t < 6; ++t) {
        const auto trackId = host.addTrack("T");
        host.addDeviceToTrack(trackId, "subtractive_synth");
        const auto clipId = host.createMidiClip(trackId, 0.0, 64.0);
        std::vector<audioapp::MidiNoteState> notes;
        for (int i = 0; i < 64; ++i)
            notes.push_back({48 + (i % 12), static_cast<double>(i), 0.9, 100.0f});
        host.setMidiClipNotes(clipId, notes);
        tracks.push_back(trackId);
    }
    std::cout << "    snapshot json before any freeze: "
              << host.getProjectSnapshotJson().size() / 1024 << " KiB\n";
    const double assetMiB = 64.0 * 60.0 / 120.0 * 48000.0 * 2.0 * 4.0 / 1048576.0;
    for (size_t i = 0; i < tracks.size(); ++i) {
        if (!host.freezeTrack(tracks[i])) {
            std::cout << "    freeze rejected for track " << i << "\n";
            continue;
        }
        std::cout << "    after freezing " << (i + 1) << " track(s): snapshot json "
                  << host.getProjectSnapshotJson().size() / 1024 << " KiB, resident PCM ~"
                  << std::fixed << std::setprecision(1)
                  << assetMiB * static_cast<double>(i + 1) << " MiB\n";
    }
}

void probeCancelRace() {
    std::cout << "\n[L] cancelTrackFreezeRender issued just before a bake starts\n";
    audioapp::EngineHost host;
    host.createProject();
    const auto trackId = host.addTrack("T");
    host.addDeviceToTrack(trackId, "subtractive_synth");
    const auto clipId = host.createMidiClip(trackId, 0.0, 16.0);
    std::vector<audioapp::MidiNoteState> notes;
    for (int i = 0; i < 16; ++i)
        notes.push_back({48 + (i % 12), static_cast<double>(i), 0.9, 100.0f});
    host.setMidiClipNotes(clipId, notes);

    host.cancelTrackFreezeRender();
    const bool committed = host.freezeTrack(trackId);
    std::cout << "    cancel requested, then a bake started: committed="
              << (committed ? "yes (cancel dropped)" : "no") << "\n";
}

} // namespace

int main() {
    std::cout << "freeze audit probe\n==================\n";
    probeTailTruncation();
    probeStalePlaysOldAudio();
    probeBpmChange();
    probeBpmChangeSynth();
    probeNestedDeviceInvalidation();
    probeMidArrangementStart();
    probeBakeSizeForLateContent();
    probeNestedSidechainBlindSpot();
    probeWorkerThreadBake();
    probeGuiParameterVisibility();
    probeMetersAndTapsOnBakedDevice();
    probeSnapshotCostAndMemory();
    probeCancelRace();
    std::cout << "\ndone\n";
    return 0;
}
