#include "audioapp/EngineHost.hpp"
#include "audioapp/TestOscillator.hpp"

#include <aaudio/AAudio.h>

#include <android/log.h>

#include <atomic>
#include <cmath>
#include <cstring>
#include <juce_core/juce_core.h>
#include <time.h>

#define AUDIOAPP_LOG(...) __android_log_print(ANDROID_LOG_INFO, "audioapp_engine", __VA_ARGS__)
#define AUDIOAPP_ERR(...) __android_log_print(ANDROID_LOG_ERROR, "audioapp_engine", __VA_ARGS__)

namespace audioapp {

struct EngineHost::Impl {
    explicit Impl(EngineHost& host) : owner(host) {}

    EngineHost& owner;
    TestOscillator oscillator;
    std::atomic<bool> playing{false};
    std::atomic<double> sampleRate{48000.0};
    AAudioStream* stream = nullptr;
    juce::CriticalSection streamMutex;

    // Timing instrumentation (audio-thread safe, atomics)
    std::atomic<int64_t> maxCallbackNs{0};
    std::atomic<uint32_t> callbackCount{0};
    std::atomic<uint32_t> callbackOverrunCount{0};
    int64_t blockDeadlineNs = 0; // set on stream open

    enum class AudioProfile : int { LowLatency, Balanced, Safe, Custom };
    std::atomic<AudioProfile> profile{AudioProfile::Balanced};
    std::atomic<int32_t> requestedSampleRate{48000};
    std::atomic<int32_t> requestedFramesPerCallback{1024};
    std::atomic<int32_t> requestedBufferCapacity{8192};
    std::atomic<int32_t> requestedBufferSize{8192};
    std::atomic<bool> requestedLowLatency{true};
    std::atomic<bool> requestedExclusive{false};
    std::atomic<int32_t> actualFramesPerBurst{0};
    std::atomic<int32_t> actualBufferSize{0};
    std::atomic<int32_t> actualBufferCapacity{0};
    std::atomic<int32_t> actualFramesPerCallback{0};
    std::atomic<int32_t> actualPerformanceMode{AAUDIO_PERFORMANCE_MODE_NONE};
    std::atomic<int32_t> actualSharingMode{AAUDIO_SHARING_MODE_SHARED};

    static aaudio_data_callback_result_t dataCallback(AAudioStream* /*stream*/,
                                                        void* userData,
                                                        void* audioData,
                                                        int32_t numFrames) {
        auto* self = static_cast<Impl*>(userData);
        if (self == nullptr || audioData == nullptr || numFrames <= 0) {
            return AAUDIO_CALLBACK_RESULT_STOP;
        }

        // --- Timing instrumentation ---
        timespec t0;
        clock_gettime(CLOCK_MONOTONIC, &t0);
        const int64_t deadlineNs = self->blockDeadlineNs;
        self->callbackCount.fetch_add(1, std::memory_order_relaxed);

        // --- Core render ---
        auto* output = static_cast<float*>(audioData);
        const bool shouldPlay = self->playing.load(std::memory_order_acquire);
        const double rate = self->sampleRate.load(std::memory_order_acquire);
        constexpr int32_t kMaxFrames = 4096;
        thread_local float masterLeft[kMaxFrames];
        thread_local float masterRight[kMaxFrames];
        thread_local float monoScratch[kMaxFrames];
        const int32_t framesToProcess = numFrames > kMaxFrames ? kMaxFrames : numFrames;

        std::memset(masterLeft, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
        std::memset(masterRight, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
        std::memset(monoScratch, 0, static_cast<size_t>(framesToProcess) * sizeof(float));

        const double playheadStart = self->owner.playheadBeats();
        if (shouldPlay) {
            self->owner.readMasterMixStereo(
                masterLeft, masterRight, framesToProcess, rate, playheadStart);
            self->owner.advancePlayheadForBlock(framesToProcess, rate);
        }
        if (self->owner.hasPreviewActivity()) {
            self->owner.readPreviewMix(masterLeft, masterRight, framesToProcess, rate);
        }
        if (self->owner.hasLiveVoices()) {
            self->owner.readLiveMix(monoScratch, framesToProcess, rate);
            for (int32_t frame = 0; frame < framesToProcess; ++frame) {
                masterLeft[frame] += monoScratch[frame];
                masterRight[frame] += monoScratch[frame];
            }
        }

        for (int32_t frame = 0; frame < framesToProcess; ++frame) {
            output[frame * 2] = masterLeft[frame];
            output[frame * 2 + 1] = masterRight[frame];
        }

        if (framesToProcess < numFrames) {
            std::memset(output + (framesToProcess * 2), 0,
                        static_cast<size_t>(numFrames - framesToProcess) * 2 * sizeof(float));
        }

        // --- Timing check (post-render, not in hot path) ---
        timespec t1;
        clock_gettime(CLOCK_MONOTONIC, &t1);
        const int64_t elapsedNs = (t1.tv_sec - t0.tv_sec) * 1000000000LL + (t1.tv_nsec - t0.tv_nsec);
        int64_t prevMax = self->maxCallbackNs.load(std::memory_order_relaxed);
        while (elapsedNs > prevMax &&
               !self->maxCallbackNs.compare_exchange_weak(prevMax, elapsedNs, std::memory_order_relaxed)) {}

        // Log overruns only — STATS logging on the audio thread can itself cause XRUNs.
        if (deadlineNs > 0 && elapsedNs > deadlineNs) {
            self->callbackOverrunCount.fetch_add(1, std::memory_order_relaxed);
            static thread_local int32_t xrunThrottle = 0;
            if ((++xrunThrottle % 20) == 0) {
                AUDIOAPP_ERR("XRUN: callback took %lld us (deadline %lld us) ph=%.2f",
                             elapsedNs / 1000, deadlineNs / 1000,
                             static_cast<double>(self->owner.playheadBeats()));
            }
        }

        return AAUDIO_CALLBACK_RESULT_CONTINUE;
    }

    static void errorCallback(AAudioStream* /*stream*/, void* userData, aaudio_result_t error) {
        auto* self = static_cast<Impl*>(userData);
        if (self != nullptr) {
            AUDIOAPP_LOG("AAudio error: %s", AAudio_convertResultToText(error));
            self->owner.setPlaying(false);
        }
    }

    bool openStream() {
        juce::ScopedLock lock(streamMutex);
        if (stream != nullptr) {
            return true;
        }

        AAudioStreamBuilder* builder = nullptr;
        aaudio_result_t result = AAudio_createStreamBuilder(&builder);
        if (result != AAUDIO_OK || builder == nullptr) {
            AUDIOAPP_LOG("AAudio_createStreamBuilder failed: %s", AAudio_convertResultToText(result));
            return false;
        }

        const auto requestedProfile = profile.load(std::memory_order_acquire);
        const bool custom = requestedProfile == AudioProfile::Custom;
        const bool wantsLowLatency = custom
            ? requestedLowLatency.load(std::memory_order_acquire)
            : requestedProfile != AudioProfile::Safe;
        const bool wantsExclusive = custom
            ? requestedExclusive.load(std::memory_order_acquire)
            : requestedProfile == AudioProfile::LowLatency;
        const auto performanceMode = wantsLowLatency
            ? AAUDIO_PERFORMANCE_MODE_LOW_LATENCY
            : AAUDIO_PERFORMANCE_MODE_POWER_SAVING;
        const auto sharingMode = wantsExclusive
            ? AAUDIO_SHARING_MODE_EXCLUSIVE
            : AAUDIO_SHARING_MODE_SHARED;
        const int32_t callbackFrames = custom
            ? requestedFramesPerCallback.load(std::memory_order_acquire)
            : requestedProfile == AudioProfile::LowLatency ? 512 : 1024;
        const int32_t bufferCapacity = custom
            ? requestedBufferCapacity.load(std::memory_order_acquire)
            : requestedProfile == AudioProfile::LowLatency ? 2048
            : requestedProfile == AudioProfile::Balanced ? 8192 : 16384;
        const int32_t activeBuffer = custom
            ? requestedBufferSize.load(std::memory_order_acquire)
            : requestedProfile == AudioProfile::LowLatency ? 1024
            : requestedProfile == AudioProfile::Balanced ? 4096 : 8192;

        AAudioStreamBuilder_setDirection(builder, AAUDIO_DIRECTION_OUTPUT);
        AAudioStreamBuilder_setPerformanceMode(builder, performanceMode);
        AAudioStreamBuilder_setBufferCapacityInFrames(builder, bufferCapacity);
        AAudioStreamBuilder_setFramesPerDataCallback(builder, callbackFrames);
        if (custom) {
            AAudioStreamBuilder_setSampleRate(
                builder, requestedSampleRate.load(std::memory_order_acquire));
        }
        AAudioStreamBuilder_setSharingMode(builder, sharingMode);
        AAudioStreamBuilder_setFormat(builder, AAUDIO_FORMAT_PCM_FLOAT);
        AAudioStreamBuilder_setChannelCount(builder, 2);
        AAudioStreamBuilder_setDataCallback(builder, &Impl::dataCallback, this);
        AAudioStreamBuilder_setErrorCallback(builder, &Impl::errorCallback, this);

        result = AAudioStreamBuilder_openStream(builder, &stream);
        AAudioStreamBuilder_delete(builder);

        if ((result != AAUDIO_OK || stream == nullptr) &&
            sharingMode == AAUDIO_SHARING_MODE_EXCLUSIVE) {
            // Exclusive mode is opportunistic on Android. Retry the same
            // low-latency profile in shared mode instead of failing playback.
            stream = nullptr;
            result = AAudio_createStreamBuilder(&builder);
            if (result == AAUDIO_OK && builder != nullptr) {
                AAudioStreamBuilder_setDirection(builder, AAUDIO_DIRECTION_OUTPUT);
                AAudioStreamBuilder_setPerformanceMode(builder, performanceMode);
                AAudioStreamBuilder_setSharingMode(builder, AAUDIO_SHARING_MODE_SHARED);
                AAudioStreamBuilder_setBufferCapacityInFrames(builder, bufferCapacity);
                AAudioStreamBuilder_setFramesPerDataCallback(builder, callbackFrames);
                if (custom) {
                    AAudioStreamBuilder_setSampleRate(
                        builder, requestedSampleRate.load(std::memory_order_acquire));
                }
                AAudioStreamBuilder_setFormat(builder, AAUDIO_FORMAT_PCM_FLOAT);
                AAudioStreamBuilder_setChannelCount(builder, 2);
                AAudioStreamBuilder_setDataCallback(builder, &Impl::dataCallback, this);
                AAudioStreamBuilder_setErrorCallback(builder, &Impl::errorCallback, this);
                result = AAudioStreamBuilder_openStream(builder, &stream);
                AAudioStreamBuilder_delete(builder);
            }
        }

        if (result != AAUDIO_OK || stream == nullptr) {
            AUDIOAPP_LOG("AAudioStreamBuilder_openStream failed: %s", AAudio_convertResultToText(result));
            stream = nullptr;
            return false;
        }

        sampleRate.store(AAudioStream_getSampleRate(stream), std::memory_order_release);
        const int32_t framesPerBurst = AAudioStream_getFramesPerBurst(stream);
        AAudioStream_setBufferSizeInFrames(stream, activeBuffer);
        // Compute per-callback deadline: bufferSize / sampleRate in nanoseconds
        const int32_t actualBufSize = AAudioStream_getBufferSizeInFrames(stream);
        const int32_t framesPerCallback = AAudioStream_getFramesPerDataCallback(stream);
        const int32_t effectiveFrames = framesPerCallback > 0 ? framesPerCallback : actualBufSize;
        blockDeadlineNs = static_cast<int64_t>(static_cast<double>(effectiveFrames) / sampleRate.load(std::memory_order_acquire) * 1e9);
        actualFramesPerBurst.store(framesPerBurst, std::memory_order_release);
        actualBufferSize.store(actualBufSize, std::memory_order_release);
        actualBufferCapacity.store(AAudioStream_getBufferCapacityInFrames(stream), std::memory_order_release);
        actualFramesPerCallback.store(framesPerCallback, std::memory_order_release);
        actualPerformanceMode.store(AAudioStream_getPerformanceMode(stream), std::memory_order_release);
        actualSharingMode.store(AAudioStream_getSharingMode(stream), std::memory_order_release);
        oscillator.setFrequency(440.0f);
        AUDIOAPP_LOG("AAudio stream open, sampleRate=%.0f bufferFrames=%d callbackFrames=%d deadlineNs=%lld",
                     sampleRate.load(), actualBufSize, framesPerCallback, blockDeadlineNs);
        return true;
    }

    void closeStream() {
        juce::ScopedLock lock(streamMutex);
        if (stream == nullptr) {
            return;
        }
        AAudioStream_requestStop(stream);
        AAudioStream_close(stream);
        stream = nullptr;
        blockDeadlineNs = 0;
    }

    bool startStream() {
        if (!openStream()) {
            return false;
        }

        juce::ScopedLock lock(streamMutex);
        if (stream == nullptr) {
            return false;
        }

        const aaudio_stream_state_t state = AAudioStream_getState(stream);
        if (state == AAUDIO_STREAM_STATE_STARTED || state == AAUDIO_STREAM_STATE_STARTING) {
            return true;
        }

        const aaudio_result_t result = AAudioStream_requestStart(stream);
        if (result != AAUDIO_OK) {
            AUDIOAPP_LOG("AAudioStream_requestStart failed: %s", AAudio_convertResultToText(result));
            return false;
        }
        return true;
    }

    void stopStream() {
        juce::ScopedLock lock(streamMutex);
        if (stream != nullptr) {
            AAudioStream_requestStop(stream);
        }
    }
};

EngineHost::EngineHost() : impl_(std::make_unique<Impl>(*this)), project_(std::make_unique<ProjectEngine>()) {
    ensureSampleBankReady();
    registerAllCommands();
}

EngineHost::~EngineHost() {
    impl_->playing.store(false, std::memory_order_release);
    impl_->stopStream();
    impl_->closeStream();
}

std::string EngineHost::ping() const {
    return "pong";
}

void EngineHost::setPlaying(bool shouldPlay) {
    if (shouldPlay && isAudioOutputEnabled()) {
        if (!impl_->startStream()) {
            AUDIOAPP_LOG("Failed to start audio stream");
            project_->setPlaying(false);
            return;
        }
    } else {
        impl_->stopStream();
    }

    project_->setPlaying(shouldPlay);
    impl_->playing.store(shouldPlay, std::memory_order_release);
    impl_->oscillator.setEnabled(shouldPlay);
}

bool EngineHost::isPlaying() const noexcept {
    return impl_->playing.load(std::memory_order_acquire);
}

bool EngineHost::configureAudioEngine(const std::string& profileName,
                                      int requestedRate,
                                      int requestedCallback,
                                      int requestedCapacity,
                                      int requestedActiveBuffer,
                                      bool lowLatency,
                                      bool exclusive) {
    const auto previousProfile = impl_->profile.load(std::memory_order_acquire);
    const int previousRate = impl_->requestedSampleRate.load(std::memory_order_acquire);
    const int previousCallback = impl_->requestedFramesPerCallback.load(std::memory_order_acquire);
    const int previousCapacity = impl_->requestedBufferCapacity.load(std::memory_order_acquire);
    const int previousBuffer = impl_->requestedBufferSize.load(std::memory_order_acquire);
    const bool previousLowLatency = impl_->requestedLowLatency.load(std::memory_order_acquire);
    const bool previousExclusive = impl_->requestedExclusive.load(std::memory_order_acquire);
    Impl::AudioProfile nextProfile;
    if (profileName == "low_latency") {
        nextProfile = Impl::AudioProfile::LowLatency;
    } else if (profileName == "balanced") {
        nextProfile = Impl::AudioProfile::Balanced;
    } else if (profileName == "safe") {
        nextProfile = Impl::AudioProfile::Safe;
    } else if (profileName == "custom") {
        const bool validRate = requestedRate == 44100 || requestedRate == 48000 ||
            requestedRate == 88200 || requestedRate == 96000 || requestedRate == 192000;
        const bool validCallback = requestedCallback == 512 || requestedCallback == 1024 ||
            requestedCallback == 2048 || requestedCallback == 4096;
        const bool validCapacity = requestedCapacity == 2048 || requestedCapacity == 4096 ||
            requestedCapacity == 8192 || requestedCapacity == 16384 || requestedCapacity == 32768;
        const bool validBuffer = requestedActiveBuffer == 1024 || requestedActiveBuffer == 2048 ||
            requestedActiveBuffer == 4096 || requestedActiveBuffer == 8192 ||
            requestedActiveBuffer == 16384 || requestedActiveBuffer == 32768;
        if (!validRate || !validCallback || !validCapacity || !validBuffer ||
            requestedActiveBuffer > requestedCapacity) {
            return false;
        }
        nextProfile = Impl::AudioProfile::Custom;
    } else {
        return false;
    }

    setPlaying(false);
    stopPreview();
    allNotesOff();
    impl_->closeStream();
    impl_->profile.store(nextProfile, std::memory_order_release);
    if (nextProfile == Impl::AudioProfile::Custom) {
        impl_->requestedSampleRate.store(requestedRate, std::memory_order_release);
        impl_->requestedFramesPerCallback.store(requestedCallback, std::memory_order_release);
        impl_->requestedBufferCapacity.store(requestedCapacity, std::memory_order_release);
        impl_->requestedBufferSize.store(requestedActiveBuffer, std::memory_order_release);
        impl_->requestedLowLatency.store(lowLatency, std::memory_order_release);
        impl_->requestedExclusive.store(exclusive, std::memory_order_release);
    }
    impl_->maxCallbackNs.store(0, std::memory_order_release);
    impl_->callbackCount.store(0, std::memory_order_release);
    impl_->callbackOverrunCount.store(0, std::memory_order_release);
    if (isAudioOutputEnabled() && !impl_->openStream()) {
        impl_->profile.store(previousProfile, std::memory_order_release);
        impl_->requestedSampleRate.store(previousRate, std::memory_order_release);
        impl_->requestedFramesPerCallback.store(previousCallback, std::memory_order_release);
        impl_->requestedBufferCapacity.store(previousCapacity, std::memory_order_release);
        impl_->requestedBufferSize.store(previousBuffer, std::memory_order_release);
        impl_->requestedLowLatency.store(previousLowLatency, std::memory_order_release);
        impl_->requestedExclusive.store(previousExclusive, std::memory_order_release);
        return false;
    }
    return true;
}

std::string EngineHost::getAudioEngineStatusJson() const {
    const juce::ScopedLock lock(impl_->streamMutex);
    const auto selected = impl_->profile.load(std::memory_order_acquire);
    const char* profileName = selected == Impl::AudioProfile::LowLatency ? "low_latency"
        : selected == Impl::AudioProfile::Safe ? "safe"
        : selected == Impl::AudioProfile::Custom ? "custom" : "balanced";
    const bool streamOpen = impl_->stream != nullptr;
    const int32_t xruns = streamOpen ? AAudioStream_getXRunCount(impl_->stream) : 0;
    auto* status = new juce::DynamicObject();
    status->setProperty("ok", true);
    status->setProperty("profile", profileName);
    status->setProperty("platform", "AAudio");
    status->setProperty("streamOpen", streamOpen);
    status->setProperty("sampleRate", impl_->sampleRate.load(std::memory_order_acquire));
    status->setProperty("framesPerBurst", impl_->actualFramesPerBurst.load(std::memory_order_acquire));
    status->setProperty("bufferSizeFrames", impl_->actualBufferSize.load(std::memory_order_acquire));
    status->setProperty("bufferCapacityFrames", impl_->actualBufferCapacity.load(std::memory_order_acquire));
    status->setProperty("framesPerCallback", impl_->actualFramesPerCallback.load(std::memory_order_acquire));
    status->setProperty("xRunCount", xruns);
    status->setProperty("callbackOverruns", static_cast<int>(impl_->callbackOverrunCount.load(std::memory_order_acquire)));
    status->setProperty("maxCallbackMicros", static_cast<double>(impl_->maxCallbackNs.load(std::memory_order_acquire)) / 1000.0);
    status->setProperty("requestedSampleRate", impl_->requestedSampleRate.load(std::memory_order_acquire));
    status->setProperty("requestedFramesPerCallback", impl_->requestedFramesPerCallback.load(std::memory_order_acquire));
    status->setProperty("requestedBufferCapacityFrames", impl_->requestedBufferCapacity.load(std::memory_order_acquire));
    status->setProperty("requestedBufferSizeFrames", impl_->requestedBufferSize.load(std::memory_order_acquire));
    const bool exclusive = streamOpen
        ? impl_->actualSharingMode.load(std::memory_order_acquire) == AAUDIO_SHARING_MODE_EXCLUSIVE
        : selected == Impl::AudioProfile::Custom
            ? impl_->requestedExclusive.load(std::memory_order_acquire)
            : selected == Impl::AudioProfile::LowLatency;
    const bool lowLatency = streamOpen
        ? impl_->actualPerformanceMode.load(std::memory_order_acquire) == AAUDIO_PERFORMANCE_MODE_LOW_LATENCY
        : selected == Impl::AudioProfile::Custom
            ? impl_->requestedLowLatency.load(std::memory_order_acquire)
            : selected != Impl::AudioProfile::Safe;
    status->setProperty("sharingMode", exclusive ? "exclusive" : "shared");
    status->setProperty("performanceMode", lowLatency ? "low_latency" : "power_saving");
    return juce::JSON::toString(juce::var(status), true).toStdString();
}

void EngineHost::ensureAudioOutput() {
    if (isAudioOutputEnabled()) {
        impl_->startStream();
    }
}

} // namespace audioapp
