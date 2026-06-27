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
    int64_t blockDeadlineNs = 0; // set on stream open

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
        // readPreviewMix now writes stereo: the fallback oscillator's per-voice
        // panning goes directly into masterLeft/masterRight; the preset
        // renderers are mono and get duplicated to L=R inside the function.
        self->owner.readPreviewMix(masterLeft, masterRight, framesToProcess, rate);
        self->owner.readLiveMix(monoScratch, framesToProcess, rate);
        for (int32_t frame = 0; frame < framesToProcess; ++frame) {
            masterLeft[frame] += monoScratch[frame];
            masterRight[frame] += monoScratch[frame];
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

        // Log peak every ~1000 callbacks (~5-10s at 512 frames)
        const uint32_t count = self->callbackCount.fetch_add(1, std::memory_order_relaxed);
        if ((count % 1000) == 0) {
            const int64_t peak = self->maxCallbackNs.load(std::memory_order_relaxed);
            const int64_t peakUs = peak / 1000;
            const int64_t bufUs = deadlineNs / 1000;
            if (peak > deadlineNs) {
                AUDIOAPP_ERR("STATS: callbacks=%u peak=%lldus OVER deadline=%lldus by %lldus",
                             count, peakUs, bufUs, peakUs - bufUs);
            } else {
                AUDIOAPP_LOG("STATS: callbacks=%u peak=%lldus deadline=%lldus (%.0f%%)",
                             count, peakUs, bufUs, 100.0 * peak / deadlineNs);
            }
            // Reset peak for next window
            self->maxCallbackNs.store(0, std::memory_order_relaxed);
        }

        // Individual overrun log (throttled)
        if (deadlineNs > 0 && elapsedNs > deadlineNs) {
            static thread_local int32_t xrunThrottle = 0;
            if ((++xrunThrottle % 50) == 0) {
                AUDIOAPP_ERR("XRUN: callback took %lld us (deadline %lld us)",
                             elapsedNs / 1000, deadlineNs / 1000);
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

        AAudioStreamBuilder_setDirection(builder, AAUDIO_DIRECTION_OUTPUT);
        AAudioStreamBuilder_setPerformanceMode(builder, AAUDIO_PERFORMANCE_MODE_NONE);
        AAudioStreamBuilder_setBufferCapacityInFrames(builder, 1024);
        AAudioStreamBuilder_setSharingMode(builder, AAUDIO_SHARING_MODE_SHARED);
        AAudioStreamBuilder_setFormat(builder, AAUDIO_FORMAT_PCM_FLOAT);
        AAudioStreamBuilder_setChannelCount(builder, 2);
        AAudioStreamBuilder_setDataCallback(builder, &Impl::dataCallback, this);
        AAudioStreamBuilder_setErrorCallback(builder, &Impl::errorCallback, this);

        result = AAudioStreamBuilder_openStream(builder, &stream);
        AAudioStreamBuilder_delete(builder);

        if (result != AAUDIO_OK || stream == nullptr) {
            AUDIOAPP_LOG("AAudioStreamBuilder_openStream failed: %s", AAudio_convertResultToText(result));
            stream = nullptr;
            return false;
        }

        sampleRate.store(AAudioStream_getSampleRate(stream), std::memory_order_release);
        // Compute per-callback deadline: bufferSize / sampleRate in nanoseconds
        const int32_t actualBufSize = AAudioStream_getBufferSizeInFrames(stream);
        const int32_t framesPerCallback = AAudioStream_getFramesPerDataCallback(stream);
        const int32_t effectiveFrames = framesPerCallback > 0 ? framesPerCallback : actualBufSize;
        blockDeadlineNs = static_cast<int64_t>(static_cast<double>(effectiveFrames) / sampleRate.load(std::memory_order_acquire) * 1e9);
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
    if (shouldPlay) {
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

void EngineHost::ensureAudioOutput() {
    impl_->startStream();
}

} // namespace audioapp
