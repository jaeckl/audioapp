#include "audioapp/SamplePlayback.hpp"

#include <algorithm>
#include <cmath>

namespace audioapp {

namespace {

double beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0;
}

} // namespace

void mixSampleRegionsBlock(float* monoOut,
                           int numFrames,
                           double sampleRate,
                           int bpm,
                           double playheadStartBeat,
                           const SampleClipPlaybackRegion* regions,
                           int regionCount) {
    if (monoOut == nullptr || numFrames <= 0 || regions == nullptr || regionCount <= 0 || bpm <= 0) {
        return;
    }

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(playheadStartBeat, frame, sampleRate, bpm);
        float mix = 0.0f;
        for (int regionIndex = 0; regionIndex < regionCount; ++regionIndex) {
            const auto& region = regions[regionIndex];
            if (region.pcm == nullptr || region.frameCount <= 0 || region.clipLengthBeats <= 0.0) {
                continue;
            }
            const double clipEnd = region.clipStartBeat + region.clipLengthBeats;
            if (beat < region.clipStartBeat || beat >= clipEnd) {
                continue;
            }
            const double localBeat = beat - region.clipStartBeat;
            const double progress = localBeat / region.clipLengthBeats;
            const double readPos = progress * static_cast<double>(region.frameCount);
            const int index = static_cast<int>(readPos);
            const float frac = static_cast<float>(readPos - static_cast<double>(index));
            const int next = std::min(index + 1, region.frameCount - 1);
            const float sample =
                region.pcm[index] * (1.0f - frac) + region.pcm[next] * frac;
            mix += sample;
        }
        monoOut[frame] += mix;
    }
}

} // namespace audioapp
