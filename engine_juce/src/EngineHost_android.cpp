#include "audioapp/EngineHost.hpp"
#include "audioapp/TestOscillator.hpp"

#include <aaudio/AAudio.h>

#include <android/log.h>

#include <atomic>
#include <cmath>
#include <cstring>
#include <mutex>

#define AUDIOAPP_LOG(...) __android_log_print(ANDROID_LOG_INFO, "audioapp_engine", __VA_ARGS__)

namespace audioapp {

struct EngineHost::Impl {
    explicit Impl(EngineHost& host) : owner(host) {}

    EngineHost& owner;
    TestOscillator oscillator;
    std::atomic<bool> playing{false};
    std::atomic<double> sampleRate{48000.0};
    AAudioStream* stream = nullptr;
    std::mutex streamMutex;

    static aaudio_data_callback_result_t dataCallback(AAudioStream* /*stream*/,
                                                        void* userData,
                                                        void* audioData,
                                                        int32_t numFrames) {
        auto* self = static_cast<Impl*>(userData);
        if (self == nullptr || audioData == nullptr || numFrames <= 0) {
            return AAUDIO_CALLBACK_RESULT_STOP;
        }

        auto* output = static_cast<float*>(audioData);
        const bool shouldPlay = self->playing.load(std::memory_order_acquire);
        const double rate = self->sampleRate.load(std::memory_order_acquire);
        constexpr int32_t kMaxFrames = 4096;
        float masterLeft[kMaxFrames];
        float masterRight[kMaxFrames];
        const int32_t framesToProcess = numFrames > kMaxFrames ? kMaxFrames : numFrames;

        std::memset(masterLeft, 0, static_cast<size_t>(framesToProcess) * sizeof(float));
        std::memset(masterRight, 0, static_cast<size_t>(framesToProcess) * sizeof(float));

        const double playheadStart = self->owner.playheadBeats();
        if (shouldPlay) {
            self->owner.readMasterMixStereo(
                masterLeft, masterRight, framesToProcess, rate, playheadStart);
            self->owner.advancePlayheadForBlock(framesToProcess, rate);
        }
        float monoScratch[kMaxFrames];
        self->owner.readPreviewMix(monoScratch, framesToProcess, rate);
        for (int32_t frame = 0; frame < framesToProcess; ++frame) {
            masterLeft[frame] += monoScratch[frame];
            masterRight[frame] += monoScratch[frame];
        }
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
        std::lock_guard<std::mutex> lock(streamMutex);
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
        AAudioStreamBuilder_setPerformanceMode(builder, AAUDIO_PERFORMANCE_MODE_LOW_LATENCY);
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
        oscillator.setFrequency(440.0f);
        AUDIOAPP_LOG("AAudio stream open, sample rate %.1f", sampleRate.load());
        return true;
    }

    void closeStream() {
        std::lock_guard<std::mutex> lock(streamMutex);
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

        std::lock_guard<std::mutex> lock(streamMutex);
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
        std::lock_guard<std::mutex> lock(streamMutex);
        if (stream != nullptr) {
            AAudioStream_requestStop(stream);
        }
    }
};

EngineHost::EngineHost() : impl_(std::make_unique<Impl>(*this)) {
    ensureSampleBankReady();
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
            project_.setPlaying(false);
            return;
        }
    } else {
        impl_->stopStream();
    }

    project_.setPlaying(shouldPlay);
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
