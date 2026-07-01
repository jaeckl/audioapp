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

std::string extractFreezePeaksJson(const std::string& json) {
    const auto freezePos = json.find("\"freeze\"");
    if (freezePos == std::string::npos) {
        return {};
    }
    const auto peaksPos = json.find("\"waveformPeaks\"", freezePos);
    if (peaksPos == std::string::npos) {
        return {};
    }
    const auto start = json.find('[', peaksPos);
    const auto end = json.find(']', start);
    if (start == std::string::npos || end == std::string::npos) {
        return {};
    }
    return json.substr(start, end - start + 1);
}

int countPeaksInJsonArray(const std::string& arrayJson) {
    int count = 0;
    for (char c : arrayJson) {
        if (c == ',') {
            ++count;
        }
    }
    return arrayJson.size() > 2 ? count + 1 : 0;
}

} // namespace

int main() {
    audioapp::EngineHost host;
    host.createProject();

    const auto trackA = host.addTrack("A");
    expect(!host.createSampleClip(trackA, "sample_kick", 0.0, 2.0).empty(), "sample clip created");

    const float live = rms(host.renderOffline(2.0, 48000.0));
    expect(live > 0.001f, "live track renders");

    expect(host.freezeTrack(trackA), "freeze succeeds");
    const std::string frozenJson = host.getProjectSnapshotJson();
    expect(frozenJson.find("\"freeze\"") != std::string::npos, "snapshot exposes freeze");
    const int peakCount = countPeaksInJsonArray(extractFreezePeaksJson(frozenJson));
    expect(peakCount >= 128, "freeze waveform has high-resolution peaks");

    const float frozen = rms(host.renderOffline(2.0, 48000.0));
    expect(frozen > 0.001f, "frozen track still audible");

    expect(host.createMidiClip(trackA, 4.0, 2.0).empty(), "cannot add midi clip to frozen track");

    expect(host.unfreezeTrack(trackA), "unfreeze succeeds");
    expect(!host.createMidiClip(trackA, 4.0, 2.0).empty(), "clip add works after unfreeze");

    if (failures != 0) return 1;
    std::cout << "All track freeze tests passed\n";
    return 0;
}
