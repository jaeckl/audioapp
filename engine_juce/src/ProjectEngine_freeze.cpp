#include "audioapp/ProjectEngine.hpp"
#include "audioapp/TrackFreeze.hpp"
#include "audioapp/TrackFreezeAssetStore.hpp"
#include "audioapp/ClipContentPlayback.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <vector>

namespace audioapp {
namespace {

constexpr double kFreezeRenderSampleRate = 48000.0;
constexpr int kFreezeRenderBlock = 512;

} // namespace

bool ProjectEngine::freezeTrackLocked(Track& track,
                                      int trackIndex,
                                      TrackFreezeAssetStore& assets) {
    if (track.isGroup || trackHasRoutingReceivers(track)) {
        return false;
    }
    const double endBeat = trackContentEndBeat(track);
    if (endBeat <= 0.0) {
        return false;
    }
    if (findTrackGainDeviceIndex(track.devices) < 0) {
        return false;
    }

    const int trackCount = trackPlaybackCount_.load(std::memory_order_acquire);
    if (trackIndex < 0 || trackIndex >= trackCount) {
        return false;
    }

    rebuildTrackPlaybackLocked();

    const double lengthBeats = endBeat;
    const int totalFrames = static_cast<int>(
        std::ceil(lengthBeats * kFreezeRenderSampleRate * 60.0 /
                  static_cast<double>(std::max(transport_.bpm(), 1))));
    if (totalFrames <= 0) {
        return false;
    }

    std::vector<float> pcmL(static_cast<size_t>(totalFrames), 0.0f);
    std::vector<float> pcmR(static_cast<size_t>(totalFrames), 0.0f);
    thread_local float blockL[kFreezeRenderBlock];
    thread_local float blockR[kFreezeRenderBlock];
    thread_local std::vector<float> lfoValues;
    thread_local std::vector<IModulator*> modulatorPtrs;

    const int lfoCount = modulationGraph_.lfoPlaybackCount();
    modulatorPtrs.resize(static_cast<size_t>(lfoCount));
    for (int i = 0; i < lfoCount; ++i) {
        modulatorPtrs[static_cast<size_t>(i)] = modulationGraph_.modulator(i);
    }
    const uint32_t retriggerGeneration = modulationGraph_.noteRetriggerGeneration();

    for (int offset = 0; offset < totalFrames; offset += kFreezeRenderBlock) {
        const int frames = std::min(kFreezeRenderBlock, totalFrames - offset);
        const double beat = static_cast<double>(offset) / kFreezeRenderSampleRate *
                            static_cast<double>(transport_.bpm()) / 60.0;
        if (lfoCount > 0) {
            lfoValues.assign(static_cast<size_t>(lfoCount) * static_cast<size_t>(frames), 0.0f);
            const double playheadSeconds =
                beat * 60.0 / static_cast<double>(std::max(transport_.bpm(), 1));
            for (int i = 0; i < lfoCount; ++i) {
                auto* mod = modulationGraph_.modulator(i);
                if (mod == nullptr) {
                    continue;
                }
                const float value = mod->evaluate(
                    beat, transport_.bpm(), 0.0, playheadSeconds, retriggerGeneration, -1.0);
                for (int frame = 0; frame < frames; ++frame) {
                    lfoValues[static_cast<size_t>(i * frames + frame)] = value;
                }
            }
        }
        std::memset(blockL, 0, static_cast<size_t>(frames) * sizeof(float));
        std::memset(blockR, 0, static_cast<size_t>(frames) * sizeof(float));
        mixTrackPreGainStereo(trackIndex,
                              blockL,
                              blockR,
                              frames,
                              kFreezeRenderSampleRate,
                              beat,
                              lfoCount > 0 ? lfoValues.data() : nullptr,
                              lfoCount,
                              lfoCount > 0 ? modulatorPtrs.data() : nullptr,
                              retriggerGeneration);
        std::memcpy(pcmL.data() + offset, blockL, static_cast<size_t>(frames) * sizeof(float));
        std::memcpy(pcmR.data() + offset, blockR, static_cast<size_t>(frames) * sizeof(float));
    }

    const std::string assetId = "freeze-" + track.id;
    if (!track.freeze.assetId.empty() && track.freeze.assetId != assetId) {
        assets.remove(track.freeze.assetId);
    }

    FreezeAsset asset;
    asset.id = assetId;
    asset.pcmL = std::move(pcmL);
    asset.pcmR = std::move(pcmR);
    asset.sampleRate = kFreezeRenderSampleRate;
    asset.peaks = computeFreezeWaveformPeaks(
        asset.pcmL.data(), asset.pcmR.data(), static_cast<int>(asset.pcmL.size()),
        freezeWaveformBinCount(static_cast<int>(asset.pcmL.size()), lengthBeats));
    if (!assets.upsert(std::move(asset))) {
        return false;
    }

    const FreezeAsset* stored = assets.find(assetId);
    if (stored == nullptr) {
        return false;
    }

    track.freeze.enabled = true;
    track.freeze.stale = false;
    track.freeze.assetId = assetId;
    track.freeze.startBeat = 0.0;
    track.freeze.lengthBeats = lengthBeats;
    track.freeze.sampleRate = kFreezeRenderSampleRate;
    track.freeze.bpmAtFreeze = transport_.bpm();
    track.freeze.contentSignature =
        computeTrackFreezeSignature(track, transport_.bpm());
    track.freeze.waveformPeaks = stored->peaks;
    return true;
}

bool ProjectEngine::refreshTrackFreeze(const std::string& trackId, TrackFreezeAssetStore& assets) {
    const juce::ScopedWriteLock lock(mutex_);
    Track* track = trackRepo_.findTrack(trackId);
    if (track == nullptr || !track->freeze.enabled) {
        return false;
    }
    const int trackIndex = static_cast<int>(std::distance(
        trackRepo_.tracks().begin(),
        std::find_if(trackRepo_.tracks().begin(),
                     trackRepo_.tracks().end(),
                     [&](const Track& candidate) { return candidate.id == trackId; })));
    if (!freezeTrackLocked(*track, trackIndex, assets)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

void ProjectEngine::reconcileTrackFreezeStaleLocked() {
    for (auto& track : trackRepo_.tracks()) {
        if (!track.freeze.enabled) {
            continue;
        }
        const uint64_t signature = computeTrackFreezeSignature(track, transport_.bpm());
        track.freeze.stale = signature != track.freeze.contentSignature;
    }
}

void ProjectEngine::markDeviceOwnerFreezeStaleLocked(const std::string& deviceId) {
    for (auto& track : trackRepo_.tracks()) {
        if (!track.freeze.enabled) {
            continue;
        }
        const int gainIdx = findTrackGainDeviceIndex(track.devices);
        const int preGainCount =
            gainIdx < 0 ? static_cast<int>(track.devices.size()) : gainIdx;
        for (int i = 0; i < preGainCount; ++i) {
            if (track.devices[static_cast<size_t>(i)].id == deviceId) {
                track.freeze.stale = true;
                return;
            }
        }
    }
}

bool ProjectEngine::freezeTrack(const std::string& trackId, TrackFreezeAssetStore& assets) {
    const juce::ScopedWriteLock lock(mutex_);
    Track* track = trackRepo_.findTrack(trackId);
    if (track == nullptr) {
        return false;
    }
    const int trackIndex = static_cast<int>(std::distance(
        trackRepo_.tracks().begin(),
        std::find_if(trackRepo_.tracks().begin(),
                     trackRepo_.tracks().end(),
                     [&](const Track& candidate) { return candidate.id == trackId; })));
    if (!freezeTrackLocked(*track, trackIndex, assets)) {
        return false;
    }
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

bool ProjectEngine::unfreezeTrack(const std::string& trackId, TrackFreezeAssetStore& assets) {
    const juce::ScopedWriteLock lock(mutex_);
    Track* track = trackRepo_.findTrack(trackId);
    if (track == nullptr || !track->freeze.enabled) {
        return false;
    }
    if (!track->freeze.assetId.empty()) {
        assets.remove(track->freeze.assetId);
    }
    track->freeze = {};
    syncProjectTreeLocked();
    rebuildTrackPlaybackLocked();
    return true;
}

void ProjectEngine::ensureFrozenAssets(TrackFreezeAssetStore& assets) {
    const juce::ScopedWriteLock lock(mutex_);
    int trackIndex = 0;
    for (auto& track : trackRepo_.tracks()) {
        if (track.freeze.enabled && assets.find(track.freeze.assetId) == nullptr) {
            freezeTrackLocked(track, trackIndex, assets);
        }
        ++trackIndex;
    }
    rebuildTrackPlaybackLocked();
}

bool ProjectEngine::isTrackFrozen(const std::string& trackId) const {
    const juce::ScopedReadLock lock(mutex_);
    const Track* track = trackRepo_.findTrack(trackId);
    return track != nullptr && track->freeze.enabled;
}

} // namespace audioapp
