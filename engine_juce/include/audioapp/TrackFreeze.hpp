#pragma once

#include "audioapp/model/TrackModel.hpp"

#include <cstddef>
#include <vector>

namespace audioapp {

double trackContentEndBeat(const Track& track) noexcept;
int findTrackGainDeviceIndex(const std::vector<DeviceSlot>& devices) noexcept;
bool trackHasRoutingReceivers(const Track& track) noexcept;

struct FreezePlaybackRegion {
    double startBeat = 0.0;
    double lengthBeats = 0.0;
    const float* pcmL = nullptr;
    const float* pcmR = nullptr;
    int frameCount = 0;
    double pcmSampleRate = 48000.0;
};

void mixFreezeStereoBlock(float* leftOut,
                          float* rightOut,
                          int numFrames,
                          double sampleRate,
                          int bpm,
                          double playheadStartBeat,
                          const FreezePlaybackRegion& region) noexcept;

int freezeWaveformBinCount(int frameCount, double lengthBeats) noexcept;

std::vector<float> computeFreezeWaveformPeaks(const float* pcmL,
                                              const float* pcmR,
                                              int frameCount,
                                              int binCount);

uint64_t computeTrackFreezeSignature(const Track& track, int bpm) noexcept;

} // namespace audioapp
