#include "audioapp/EngineHost.hpp"

#include <cmath>
#include <iostream>
#include <vector>

namespace {

int failures = 0;

void expect(bool condition, const char* message) {
    if (condition) return;
    ++failures;
    std::cerr << "FAIL: " << message << '\n';
}

float rms(const std::vector<float>& audio) {
    double sum = 0.0;
    for (float sample : audio) sum += static_cast<double>(sample) * sample;
    return audio.empty() ? 0.0f : static_cast<float>(std::sqrt(sum / audio.size()));
}

} // namespace

int main() {
    audioapp::EngineHost::setAudioOutputEnabled(false);

    {
        audioapp::EngineHost host;
        host.createProject();
        const auto a = host.addTrack("A");
        const auto b = host.addTrack("B");
        expect(host.selectTrack("master"), "can select virtual master");
        expect(host.getProjectSnapshotJson().find("\"selectedTrackId\": \"master\"") !=
                   std::string::npos,
               "snapshot shows master selected");
        const auto osc = host.addDeviceToTrack("master", "simple_oscillator");
        expect(!osc.empty(), "instruments allowed on virtual master");
        expect(host.addDeviceToTrack("master", "track_gain").empty(),
               "TrackGain rejected on master");
        const auto fx = host.addDeviceToTrack("master", "delay");
        expect(!fx.empty(), "FX can be added to master");
        expect(host.setTrackMuted("master", true), "master can mute");
        expect(!host.setTrackOutput("master", "device"), "cannot set master output");
        expect(host.setTrackOutput(a, "device"), "track can route to device");
        expect(host.setTrackOutput(a, b), "track can route to another track");
        expect(!host.setTrackOutput(b, a), "cycle A->B->A rejected");
        expect(host.setTrackOutput(a, "master"), "reset A to master");
        expect(host.setTrackOutput(b, a), "B can feed A");
        expect(!host.setTrackOutput(a, b), "cycle rejected when closing loop");
    }

    {
        audioapp::EngineHost host;
        host.createProject();
        const auto track = host.addTrack("Direct");
        host.addDeviceToTrack(track, "simple_oscillator");
        const auto clip = host.createMidiClip(track, 0.0, 4.0);
        host.setMidiClipNotes(clip, {{69, 0.0, 4.0, 100.0f}});
        host.setPlaying(true);

        const float viaMaster = rms(host.renderOffline(1.0, 48000.0));
        expect(viaMaster > 0.001f, "default master path audible");

        expect(host.setMasterGain(0.0f), "mute virtual master fader");
        // Master gain ramps across callbacks — drain the smoother.
        (void)host.renderOffline(1.0, 48000.0);
        const float mutedMaster = rms(host.renderOffline(1.0, 48000.0));
        expect(mutedMaster < viaMaster * 0.05f, "master fader silences master path");

        expect(host.setTrackOutput(track, "device"), "bypass to device bus");
        const float directDevice = rms(host.renderOffline(1.0, 48000.0));
        expect(directDevice > viaMaster * 0.5f,
               "device route bypasses virtual master fader");
    }

    {
        audioapp::EngineHost host;
        host.createProject();
        const auto bus = host.addTrack("Bus");
        const auto child = host.addTrack("Child");
        host.addDeviceToTrack(child, "simple_oscillator");
        const auto clip = host.createMidiClip(child, 0.0, 4.0);
        host.setMidiClipNotes(clip, {{69, 0.0, 4.0, 100.0f}});
        host.setPlaying(true);

        const float direct = rms(host.renderOffline(1.0, 48000.0));
        expect(direct > 0.001f, "child direct path audible");

        expect(host.setTrackOutput(child, bus), "child routes into bus track");
        // Bus has only TrackGain by default — audio should still reach master.
        const float viaBus = rms(host.renderOffline(1.0, 48000.0));
        expect(viaBus > direct * 0.5f && viaBus < direct * 1.5f,
               "track-to-track routing reaches master once");

        expect(host.setTrackMuted(bus, true), "mute bus track");
        (void)host.renderOffline(1.0, 48000.0);
        const float mutedBus = rms(host.renderOffline(1.0, 48000.0));
        expect(mutedBus < viaBus * 0.05f, "muted bus silences routed child");

        expect(host.setTrackMuted(bus, false), "unmute bus");
        expect(host.setTrackOutput(child, "device"), "child bypass to device");
        const float childDirect = rms(host.renderOffline(1.0, 48000.0));
        expect(childDirect > 0.001f, "device-routed child audible");

        // Snapshot persists child outputTarget
        const auto snap = host.getProjectSnapshotJson();
        expect(snap.find("\"outputTarget\": \"device\"") != std::string::npos,
               "snapshot persists child outputTarget");
    }

    {
        audioapp::EngineHost host;
        host.createProject();
        expect(host.selectTrack("master"), "select master");
        const auto clip = host.createMidiClip("master", 0.0, 4.0);
        expect(!clip.empty(), "can create MIDI clip on master");
        expect(host.getProjectSnapshotJson().find(clip) != std::string::npos,
               "master clip appears in snapshot");
    }

    if (failures != 0) return 1;
    std::cout << "All track output routing tests passed\n";
    return 0;
}
