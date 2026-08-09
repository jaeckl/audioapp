#pragma once

#include "audioapp/model/TrackModel.hpp"
#include "audioapp/TrackFreezeAssetStore.hpp"

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace audioapp {

double trackContentEndBeat(const Track& track) noexcept;
int findTrackGainDeviceIndex(const std::vector<DeviceSlot>& devices) noexcept;
bool trackHasRoutingReceivers(const Track& track) noexcept;

/// Highest device index (exclusive) whose output can be baked for `track`.
///
/// Baking replaces devices with recorded audio, which silently breaks any
/// device that reads signal from another track (routing receiver, ducker with a
/// sidechain source) or that publishes its own intermediate output to another
/// track (a device tapped as a graph source). The split therefore lands before
/// the first such device; everything from there on keeps running live and the
/// baked audio is fed in as its input. Returns 0 when nothing can be baked.
int computeFreezeBakeEndIndex(const Track& track,
                              const std::vector<Track>& allTracks) noexcept;

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

std::string freezeWavArchivePath(const std::string& assetId);
bool loadFreezeAssetFromWavBytes(const std::string& assetId,
                                 const std::vector<uint8_t>& wavBytes,
                                 FreezeAsset& out);
std::vector<uint8_t> encodeFreezeAssetWav(const FreezeAsset& asset);

int freezeWaveformBinCount(int frameCount, double lengthBeats) noexcept;

std::vector<float> computeFreezeWaveformPeaks(const float* pcmL,
                                              const float* pcmR,
                                              int frameCount,
                                              int binCount);

/// FNV-1a over arbitrary bytes; exposed so callers can fold serialized state
/// (device configs, modulator params, automation) into a freeze signature.
uint64_t freezeHashBytes(uint64_t seed, const void* data, size_t size) noexcept;
uint64_t freezeHashString(uint64_t seed, std::string_view text) noexcept;

/// Content hash used to decide whether a baked asset is still valid.
///
/// Under-invalidation means playing back audio that no longer matches the
/// project, so this covers every field the bake reads. `externalDependencyHash`
/// carries the parts that live outside `Track` (device configs, modulator
/// params, automation clips, cross-track per-note clocks) and is folded in by
/// the caller, which has access to the registry and the modulation graph.
uint64_t computeTrackFreezeSignature(const Track& track,
                                     int bpm,
                                     double renderSampleRate,
                                     int bakeEndDeviceIndex,
                                     uint64_t externalDependencyHash) noexcept;

} // namespace audioapp
