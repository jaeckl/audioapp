#pragma once

namespace audioapp {

class SampleBank;

struct SampleClipPlaybackRegion {
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    const float* pcm = nullptr;
    int frameCount = 0;
    double sampleRate = 48000.0;
};

void mixSampleRegionsBlock(float* monoOut,
                           int numFrames,
                           double sampleRate,
                           int bpm,
                           double playheadStartBeat,
                           const SampleClipPlaybackRegion* regions,
                           int regionCount);

} // namespace audioapp
