#include "audioapp/EngineHost.hpp"
#include "audioapp/SampleBank.hpp"

#include <cmath>
#include <cstring>
#include <vector>

namespace {

bool hasNonZeroSample(const std::vector<float>& buffer) {
    for (float sample : buffer) {
        if (std::fabs(sample) > 1.0e-5f) {
            return true;
        }
    }
    return false;
}

} // namespace

int main() {
    audioapp::EngineHost host;
    host.createProject();
    const std::string trackId = host.addTrack("Live");
    host.selectTrack(trackId);
    if (!host.setDeviceStringParameter("dev-1", "sampleId", "sample_kick")) {
        return 1;
    }
    host.setRecordArmed(false);

    host.enterPlayMode();
    const bool noteStarted = host.noteOn(60, 110.0f);
    if (!noteStarted) {
        return 1;
    }

    std::vector<float> buffer(2048, 0.0f);
    host.readLiveMix(buffer.data(), static_cast<int>(buffer.size()), 48000.0);
    if (!hasNonZeroSample(buffer)) {
        return 2;
    }

    host.noteOff(60);
    host.allNotesOff();
    return 0;
}
