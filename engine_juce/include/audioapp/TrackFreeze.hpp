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

/// How many playback slots one model device expands to (noteFx + self + audioFx
/// for synths; 1 otherwise). Matches ProjectEngine flatten order.
int flattenedPlaybackSlotCount(const DeviceSlot& device) noexcept;

/// Exclusive flattened playback index where freeze bake ends for `track`.
///
/// Index space matches the realtime device array (noteFx…, synth, audioFx…),
/// not `Track::devices`. Baking replaces those slots with recorded audio, which
/// silently breaks any device that reads signal from another track (routing
/// receiver, ducker with a sidechain source) or that publishes its own
/// intermediate output to another track (a device tapped as a graph source).
/// The split lands before the first such model device's flattened span;
/// everything from there on keeps running live and the baked audio is fed in
/// as its input. Returns 0 when nothing can be baked.
int computeFreezeBakeEndIndex(const Track& track,
                              const std::vector<Track>& allTracks) noexcept;

/// True when `deviceId` is a top-level or nested slot fully covered by the
/// flattened bake range `[0, flattenedBakeEnd)`.
bool freezeBakeCoversDeviceId(const Track& track,
                              int flattenedBakeEnd,
                              std::string_view deviceId) noexcept;

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
