#include "audioapp/ProjectEngine.hpp"
#include "audioapp/TrackFreeze.hpp"
#include "audioapp/TrackFreezeAssetStore.hpp"
#include "audioapp/ClipContentPlayback.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/DeviceChainOrchestrator.hpp"
#include "audioapp/ProjectJson.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <memory>
#include <thread>
#include <vector>

namespace audioapp {
namespace {

constexpr int kFreezeRenderBlock = kScratchFrames;

} // namespace

/// Everything the bake reads, copied so the render never touches live state.
struct ProjectEngine::FreezeRenderJob {
    std::string trackId;
    std::string assetId;
    std::string previousAssetId;
    /// Owns a private arena, so rendering does not disturb the processors the
    /// audio thread is running for this track.
    TrackPlaybackSnapshot playback;
    ModulatorArena modulators;
    std::vector<IModulator*> modulatorPtrs;
    std::vector<bool> relevantLfos;
    std::vector<bool> perNoteLfos;
    /// Notes from every track that feeds the project-wide per-note clock.
    std::vector<PlaybackNote> perNoteClockNotes;
    bool needsPerNoteElapsed = false;
    uint32_t retriggerGeneration = 0;
    int lfoCount = 0;
    int bpm = 120;
    double sampleRate = 48000.0;
    int blockFrames = kFreezeRenderBlock;
    int bakeEndIndex = 0;
    double lengthBeats = 0.0;
    int totalFrames = 0;
    /// Signature at prepare time. The commit re-checks it and drops the render
    /// if the project moved on, so an edit during the bake cannot publish audio
    /// that no longer matches the project.
    uint64_t signature = 0;
};

bool ProjectEngine::prepareFreezeJobLocked(const Track& track,
                                           int trackIndex,
                                           FreezeRenderJob& job) const {
    if (track.isGroup || captureActive_) {
        return false;
    }
    const double endBeat = trackContentEndBeat(track);
    if (endBeat <= 0.0) {
        return false;
    }

    // Devices from bakeEndIndex on read or publish cross-track signal, so they
    // stay live and the baked audio becomes their input. A split at 0 still pays
    // off for a sample-clip track (the clip mix gets baked), but on a track whose
    // audio comes only from devices it would bake silence.
    const int bakeEndIndex = computeFreezeBakeEndIndex(track, trackRepo_.tracks());
    if (bakeEndIndex < 0 || (bakeEndIndex == 0 && track.sampleClips.empty())) {
        return false;
    }

    const int trackCount = trackPlayback_.count();
    if (trackIndex < 0 || trackIndex >= trackCount) {
        return false;
    }

    const double renderSampleRate = outputSampleRate_.load(std::memory_order_relaxed);
    if (!(renderSampleRate > 0.0)) {
        return false;
    }

    job.trackId = track.id;
    job.assetId = "freeze-" + track.id;
    job.previousAssetId = track.freeze.assetId;
    job.bakeEndIndex = bakeEndIndex;
    job.sampleRate = renderSampleRate;
    // Block-rate modulation is held for a whole block, so the bake has to use
    // the same block size the live callback does or the frozen result would
    // modulate at a different resolution than what the user just heard.
    job.blockFrames = std::clamp(
        outputBlockFrames_.load(std::memory_order_relaxed), 1, kFreezeRenderBlock);
    job.bpm = transport_.bpm();
    job.lengthBeats = endBeat;
    job.totalFrames = static_cast<int>(
        std::ceil(job.lengthBeats * renderSampleRate * 60.0 /
                  static_cast<double>(std::max(job.bpm, 1))));
    if (job.totalFrames <= 0) {
        return false;
    }
    job.signature = trackFreezeSignatureLocked(track, bakeEndIndex);

    job.playback = trackPlayback_[trackIndex];
    // Copying the snapshot shares its arena; swap in a private one before the
    // render so baked DSP state stays out of the live chain.
    job.playback.arena = ProcessorArena(std::max(1, bakeEndIndex));
    buildProcessorChain(job.playback.devices, bakeEndIndex, job.playback.arena);
    resetPlaybackStateInArena(job.playback.arena);

    const int lfoCount = modulationGraph_.lfoPlaybackCount();
    job.lfoCount = lfoCount;
    job.relevantLfos.assign(static_cast<size_t>(lfoCount), false);
    job.perNoteLfos.assign(static_cast<size_t>(lfoCount), false);
    for (int edge = 0; edge < job.playback.modEdgeCount; ++edge) {
        const int index = static_cast<int>(job.playback.modEdges[edge].lfoId);
        if (index >= 0 && index < lfoCount) {
            job.relevantLfos[static_cast<size_t>(index)] = true;
        }
    }
    job.modulatorPtrs.assign(static_cast<size_t>(lfoCount), nullptr);
    const auto& records = modulationGraph_.lfos();
    const auto& types = modulationGraph_.modulatorTypes();
    for (int i = 0; i < lfoCount; ++i) {
        IModulator* modulator = nullptr;
        if (i < static_cast<int>(records.size())) {
            const auto& record = records[static_cast<size_t>(i)];
            if (record.typeIndex >= 0 && record.typeIndex < static_cast<int>(types.size())) {
                modulator = types[static_cast<size_t>(record.typeIndex)]->createModulator(
                    job.modulators, record.params);
            }
        }
        job.modulatorPtrs[static_cast<size_t>(i)] = modulator;
        job.perNoteLfos[static_cast<size_t>(i)] = modulatorUsesPerNoteClock(modulator);
    }

    // The per-note clock is shared project-wide: realtime playback derives it
    // from the most recent note onset across every track that owns a per-note
    // mod edge. The bake has to use the same set of tracks or a per-note
    // modulated device would come out different from what the user just heard.
    job.needsPerNoteElapsed = false;
    job.perNoteClockNotes.clear();
    for (int other = 0; other < trackCount; ++other) {
        const auto& candidate = trackPlayback_[other];
        bool drivesClock = false;
        for (int edge = 0; edge < candidate.modEdgeCount; ++edge) {
            const int index = static_cast<int>(candidate.modEdges[edge].lfoId);
            if (index >= 0 && index < lfoCount &&
                job.perNoteLfos[static_cast<size_t>(index)]) {
                drivesClock = true;
                break;
            }
        }
        if (!drivesClock) {
            continue;
        }
        job.needsPerNoteElapsed = true;
        for (int noteIndex = 0; noteIndex < candidate.noteCount; ++noteIndex) {
            job.perNoteClockNotes.push_back(candidate.notes[noteIndex]);
        }
    }

    job.retriggerGeneration = modulationGraph_.noteRetriggerGeneration() + 1u;
    return true;
}

bool ProjectEngine::renderFreezeJob(FreezeRenderJob& job, FreezeAsset& outAsset) {
    std::vector<float> pcmL(static_cast<size_t>(job.totalFrames), 0.0f);
    std::vector<float> pcmR(static_cast<size_t>(job.totalFrames), 0.0f);
    thread_local float blockL[kFreezeRenderBlock];
    thread_local float blockR[kFreezeRenderBlock];
    thread_local DeviceChainScratch freezeScratch;
    thread_local std::vector<float> lfoValues;

    const int lfoCount = job.lfoCount;
    const int bpm = job.bpm;
    const double invBpmSeconds = 60.0 / static_cast<double>(std::max(bpm, 1));
    const double samplePeriod = 1.0 / job.sampleRate;
    lfoValues.resize(static_cast<size_t>(lfoCount) * kFreezeRenderBlock);

    const auto noteElapsedSecondsAtBeat = [&](double beat) noexcept -> double {
        double latestOnsetBeat = -1.0;
        for (const PlaybackNote& note : job.perNoteClockNotes) {
            const double onset = midiActiveNoteOnsetBeat(beat,
                                                         note.clipStartBeat,
                                                         note.clipLengthBeats,
                                                         note.contentLengthBeats,
                                                         note.loopContent,
                                                         note.noteStartBeat,
                                                         note.noteDurationBeats);
            if (onset > latestOnsetBeat) {
                latestOnsetBeat = onset;
            }
        }
        if (latestOnsetBeat < 0.0) {
            return -1.0;
        }
        return (beat - latestOnsetBeat) * invBpmSeconds;
    };

    // Long bakes run while audio is playing, so hand the CPU back regularly.
    // A slice is short enough that the audio thread never waits behind us and
    // long enough that yielding is not the dominant cost.
    constexpr int kBlocksPerSlice = 32;
    int blocksInSlice = 0;

    for (int offset = 0; offset < job.totalFrames; offset += job.blockFrames) {
        if (freezeCancelRequested_.load(std::memory_order_acquire)) {
            return false;
        }
        const int frames = std::min(job.blockFrames, job.totalFrames - offset);
        const double beat = static_cast<double>(offset) / job.sampleRate *
                            static_cast<double>(bpm) / 60.0;
        if (lfoCount > 0) {
            std::fill(lfoValues.begin(),
                      lfoValues.begin() + static_cast<std::ptrdiff_t>(lfoCount * frames),
                      0.0f);
            const double playheadSeconds = beat * invBpmSeconds;
            for (int i = 0; i < lfoCount; ++i) {
                if (!job.relevantLfos[static_cast<size_t>(i)]) continue;
                auto* mod = job.modulatorPtrs[static_cast<size_t>(i)];
                if (mod == nullptr) {
                    continue;
                }
                if (!job.perNoteLfos[static_cast<size_t>(i)] || !job.needsPerNoteElapsed) {
                    const float value = mod->evaluate(
                        beat, bpm, 0.0, playheadSeconds, job.retriggerGeneration, -1.0);
                    for (int frame = 0; frame < frames; ++frame) {
                        lfoValues[static_cast<size_t>(i * frames + frame)] = value;
                    }
                    continue;
                }
                for (int frame = 0; frame < frames; ++frame) {
                    const double secondsWithinBlock =
                        static_cast<double>(frame) * samplePeriod;
                    const double frameBeat =
                        beat + secondsWithinBlock *
                                   (static_cast<double>(std::max(bpm, 1)) / 60.0);
                    lfoValues[static_cast<size_t>(i * frames + frame)] =
                        mod->evaluate(frameBeat,
                                      bpm,
                                      secondsWithinBlock,
                                      playheadSeconds,
                                      job.retriggerGeneration,
                                      noteElapsedSecondsAtBeat(frameBeat));
                }
            }
        }
        std::memset(blockL, 0, static_cast<size_t>(frames) * sizeof(float));
        std::memset(blockR, 0, static_cast<size_t>(frames) * sizeof(float));
        mixTrackPreGainStereoWithArena(job.playback,
                                       job.playback.arena,
                                       blockL,
                                       blockR,
                                       frames,
                                       job.sampleRate,
                                       beat,
                                       lfoCount > 0 ? lfoValues.data() : nullptr,
                                       lfoCount,
                                       lfoCount > 0 ? job.modulatorPtrs.data() : nullptr,
                                       job.retriggerGeneration,
                                       &freezeScratch,
                                       job.bakeEndIndex);
        std::memcpy(pcmL.data() + offset, blockL, static_cast<size_t>(frames) * sizeof(float));
        std::memcpy(pcmR.data() + offset, blockR, static_cast<size_t>(frames) * sizeof(float));

        if (++blocksInSlice >= kBlocksPerSlice) {
            blocksInSlice = 0;
            std::this_thread::yield();
        }
    }

    outAsset.id = job.assetId;
    outAsset.pcmL = std::move(pcmL);
    outAsset.pcmR = std::move(pcmR);
    outAsset.sampleRate = job.sampleRate;
    outAsset.peaks = computeFreezeWaveformPeaks(
        outAsset.pcmL.data(),
        outAsset.pcmR.data(),
        static_cast<int>(outAsset.pcmL.size()),
        freezeWaveformBinCount(static_cast<int>(outAsset.pcmL.size()), job.lengthBeats));
    return true;
}

bool ProjectEngine::commitFreezeJobLocked(const FreezeRenderJob& job,
                                          FreezeAsset&& asset,
                                          TrackFreezeAssetStore& assets) {
    Track* track = trackRepo_.findTrack(job.trackId);
    if (track == nullptr) {
        return false;
    }
    // The project may have changed while the render ran off the lock. Anything
    // the bake depended on is in the signature, so a mismatch means this audio
    // is stale and must be thrown away rather than published.
    const int bakeEndIndex = computeFreezeBakeEndIndex(*track, trackRepo_.tracks());
    if (bakeEndIndex != job.bakeEndIndex ||
        trackFreezeSignatureLocked(*track, bakeEndIndex) != job.signature) {
        return false;
    }

    if (!job.previousAssetId.empty() && job.previousAssetId != job.assetId) {
        assets.remove(job.previousAssetId);
    }
    if (!assets.upsert(std::move(asset))) {
        return false;
    }
    const FreezeAssetRef stored = assets.find(job.assetId);
    if (stored == nullptr) {
        return false;
    }

    track->freeze.enabled = true;
    track->freeze.stale = false;
    track->freeze.assetId = job.assetId;
    track->freeze.startBeat = 0.0;
    track->freeze.lengthBeats = job.lengthBeats;
    track->freeze.sampleRate = job.sampleRate;
    track->freeze.bpmAtFreeze = job.bpm;
    track->freeze.bakeEndDeviceIndex = job.bakeEndIndex;
    track->freeze.contentSignature = job.signature;
    track->freeze.waveformPeaks = stored->peaks;
    return true;
}

bool ProjectEngine::freezeTrackLocked(Track& track,
                                      int trackIndex,
                                      TrackFreezeAssetStore& assets) {
    auto job = std::make_unique<FreezeRenderJob>();
    if (!prepareFreezeJobLocked(track, trackIndex, *job)) {
        return false;
    }
    FreezeAsset asset;
    if (!renderFreezeJob(*job, asset)) {
        return false;
    }
    return commitFreezeJobLocked(*job, std::move(asset), assets);
}

bool ProjectEngine::trackUsesPerNoteModulatorLocked(const Track& track,
                                                    int bakeEndDeviceIndex) const {
    const int lfoCount = modulationGraph_.lfoPlaybackCount();
    if (lfoCount <= 0) {
        return false;
    }
    const int bakedCount =
        std::clamp(bakeEndDeviceIndex, 0, static_cast<int>(track.devices.size()));
    for (const auto& edge : modulationGraph_.modEdges()) {
        bool targetsBakedDevice = false;
        for (int i = 0; i < bakedCount; ++i) {
            if (track.devices[static_cast<size_t>(i)].id == edge.deviceId) {
                targetsBakedDevice = true;
                break;
            }
        }
        if (!targetsBakedDevice) {
            continue;
        }
        for (int i = 0; i < lfoCount; ++i) {
            if (modulationGraph_.lfos().size() <= static_cast<size_t>(i)) {
                break;
            }
            if (modulationGraph_.lfos()[static_cast<size_t>(i)].id != edge.lfoId) {
                continue;
            }
            if (modulatorUsesPerNoteClock(modulationGraph_.modulator(i))) {
                return true;
            }
        }
    }
    return false;
}

uint64_t ProjectEngine::freezeExternalDependencyHashLocked(const Track& track,
                                                           int bakeEndDeviceIndex) const {
    uint64_t hash = 1469598103934665603ull;
    const int bakedCount =
        std::clamp(bakeEndDeviceIndex, 0, static_cast<int>(track.devices.size()));

    // Serialized configs cover every device parameter, including ones added
    // later, so a new field can never silently escape invalidation.
    for (int i = 0; i < bakedCount; ++i) {
        const auto& device = track.devices[static_cast<size_t>(i)];
        hash = freezeHashString(hash, deviceSlotToVar(device, deviceRegistry_));
    }

    const auto isBakedDevice = [&](const std::string& deviceId) {
        for (int i = 0; i < bakedCount; ++i) {
            if (track.devices[static_cast<size_t>(i)].id == deviceId) {
                return true;
            }
        }
        return false;
    };

    const auto& types = modulationGraph_.modulatorTypes();
    for (const auto& edge : modulationGraph_.modEdges()) {
        if (!isBakedDevice(edge.deviceId)) {
            continue;
        }
        hash = freezeHashString(hash, edge.deviceId);
        hash = freezeHashString(hash, edge.paramId);
        hash = freezeHashBytes(hash, &edge.amount, sizeof(edge.amount));
        hash = freezeHashBytes(hash, &edge.lfoId, sizeof(edge.lfoId));
        for (const auto& record : modulationGraph_.lfos()) {
            if (record.id != edge.lfoId) {
                continue;
            }
            hash = freezeHashBytes(hash, &record.typeIndex, sizeof(record.typeIndex));
            if (record.typeIndex >= 0 &&
                static_cast<size_t>(record.typeIndex) < types.size()) {
                hash = freezeHashString(
                    hash,
                    juce::JSON::toString(
                        types[static_cast<size_t>(record.typeIndex)]->paramsToVar(record.params))
                        .toStdString());
            }
        }
    }

    for (const auto& clip : automationClipStore_.clips()) {
        if (!isBakedDevice(clip.deviceId)) {
            continue;
        }
        hash = freezeHashString(hash, clip.id);
        hash = freezeHashString(hash, clip.paramId);
        hash = freezeHashBytes(hash, &clip.startBeat, sizeof(clip.startBeat));
        hash = freezeHashBytes(hash, &clip.lengthBeats, sizeof(clip.lengthBeats));
        hash = freezeHashBytes(hash, &clip.naturalLengthBeats,
                               sizeof(clip.naturalLengthBeats));
        hash = freezeHashBytes(hash, &clip.loopContent, sizeof(clip.loopContent));
        for (const auto& point : clip.points) {
            hash = freezeHashBytes(hash, &point.beat, sizeof(point.beat));
            hash = freezeHashBytes(hash, &point.value, sizeof(point.value));
        }
    }

    // A per-note modulator reads a project-wide clock, so notes on other tracks
    // change this track's baked audio.
    if (trackUsesPerNoteModulatorLocked(track, bakeEndDeviceIndex)) {
        for (const auto& other : trackRepo_.tracks()) {
            for (const auto& clip : other.midiClips) {
                hash = freezeHashBytes(hash, &clip.startBeat, sizeof(clip.startBeat));
                hash = freezeHashBytes(hash, &clip.lengthBeats, sizeof(clip.lengthBeats));
                hash = freezeHashBytes(hash, &clip.naturalLengthBeats,
                                       sizeof(clip.naturalLengthBeats));
                hash = freezeHashBytes(hash, &clip.loopContent, sizeof(clip.loopContent));
                for (const auto& note : clip.notes) {
                    hash = freezeHashBytes(hash, &note.pitch, sizeof(note.pitch));
                    hash = freezeHashBytes(hash, &note.startBeat, sizeof(note.startBeat));
                    hash = freezeHashBytes(hash, &note.durationBeats,
                                           sizeof(note.durationBeats));
                }
            }
        }
    }

    return hash;
}

uint64_t ProjectEngine::trackFreezeSignatureLocked(const Track& track,
                                                   int bakeEndDeviceIndex) const {
    const int blockFrames = std::clamp(
        outputBlockFrames_.load(std::memory_order_relaxed), 1, kFreezeRenderBlock);
    uint64_t external = freezeExternalDependencyHashLocked(track, bakeEndDeviceIndex);
    external = freezeHashBytes(external, &blockFrames, sizeof(blockFrames));
    return computeTrackFreezeSignature(
        track,
        transport_.bpm(),
        outputSampleRate_.load(std::memory_order_relaxed),
        bakeEndDeviceIndex,
        external);
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
        // A chain edit can move the split (e.g. a ducker gained a sidechain
        // source), which invalidates the asset even if nothing else changed.
        const int bakeEndIndex = computeFreezeBakeEndIndex(track, trackRepo_.tracks());
        if (bakeEndIndex != track.freeze.bakeEndDeviceIndex) {
            track.freeze.stale = true;
            continue;
        }
        const uint64_t signature = trackFreezeSignatureLocked(track, bakeEndIndex);
        track.freeze.stale = signature != track.freeze.contentSignature;
    }
}

void ProjectEngine::markDeviceOwnerFreezeStaleLocked(const std::string& deviceId) {
    for (auto& track : trackRepo_.tracks()) {
        if (!track.freeze.enabled) {
            continue;
        }
        const int bakedCount = std::clamp(track.freeze.bakeEndDeviceIndex,
                                          0,
                                          static_cast<int>(track.devices.size()));
        for (int i = 0; i < bakedCount; ++i) {
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

void ProjectEngine::cancelFreezeRender() noexcept {
    freezeCancelRequested_.store(true, std::memory_order_release);
}

bool ProjectEngine::freezeTrackWithoutBlocking(const std::string& trackId,
                                               TrackFreezeAssetStore& assets) {
    // One bake at a time: concurrent renders would fight over CPU that the
    // audio callback needs, and the later commit would invalidate the earlier.
    if (freezeRenderActive_.exchange(true, std::memory_order_acq_rel)) {
        return false;
    }
    struct ActiveGuard {
        std::atomic<bool>& flag;
        ~ActiveGuard() { flag.store(false, std::memory_order_release); }
    } guard{freezeRenderActive_};
    freezeCancelRequested_.store(false, std::memory_order_release);

    auto job = std::make_unique<FreezeRenderJob>();
    {
        const juce::ScopedWriteLock lock(mutex_);
        const Track* track = trackRepo_.findTrack(trackId);
        if (track == nullptr) {
            return false;
        }
        const int trackIndex = static_cast<int>(std::distance(
            trackRepo_.tracks().begin(),
            std::find_if(trackRepo_.tracks().begin(),
                         trackRepo_.tracks().end(),
                         [&](const Track& candidate) { return candidate.id == trackId; })));
        if (!prepareFreezeJobLocked(*track, trackIndex, *job)) {
            return false;
        }
    }

    FreezeAsset asset;
    if (!renderFreezeJob(*job, asset)) {
        return false;
    }

    const juce::ScopedWriteLock lock(mutex_);
    if (!commitFreezeJobLocked(*job, std::move(asset), assets)) {
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
