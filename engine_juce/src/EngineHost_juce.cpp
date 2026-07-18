#include "audioapp/EngineHost.hpp"
#include "audioapp/TestOscillator.hpp"

#include <juce_audio_devices/juce_audio_devices.h>
#include <juce_events/juce_events.h>

#include <atomic>
#include <cstring>

namespace audioapp {

struct EngineHost::Impl : juce::AudioIODeviceCallback {
    explicit Impl(EngineHost& host) : owner(host) {}

    EngineHost& owner;
    juce::AudioDeviceManager deviceManager;
    TestOscillator oscillator;
    std::atomic<bool> playing{false};
    std::atomic<double> sampleRate{48000.0};
    std::atomic<bool> audioInitialized{false};
    juce::CriticalSection initMutex;
    std::string audioProfile{"balanced"};
    int requestedSampleRate = 48000;
    int requestedFramesPerCallback = 192;
    int requestedBufferCapacity = 2048;
    int requestedBufferSize = 768;

    void ensureAudioInitialized() {
        if (audioInitialized.load(std::memory_order_acquire)) {
            return;
        }

        const juce::ScopedLock lock(initMutex);
        if (audioInitialized.load(std::memory_order_relaxed)) {
            return;
        }

        if (juce::MessageManager::getInstanceWithoutCreating() == nullptr) {
            juce::MessageManager::getInstance();
        }

        const juce::String error = deviceManager.initialiseWithDefaultDevices(0, 2);
        if (error.isNotEmpty()) {
            return;
        }

        deviceManager.addAudioCallback(this);
        audioInitialized.store(true, std::memory_order_release);
    }

    void audioDeviceAboutToStart(juce::AudioIODevice* device) override {
        sampleRate.store(device != nullptr ? device->getCurrentSampleRate() : 48000.0,
                         std::memory_order_release);
        oscillator.setFrequency(440.0f);
    }

    void audioDeviceStopped() override {
        sampleRate.store(48000.0, std::memory_order_release);
    }

    void audioDeviceIOCallbackWithContext(const float* const* /*inputChannelData*/,
                                          int /*numInputChannels*/,
                                          float* const* outputChannelData,
                                          int numOutputChannels,
                                          int numSamples,
                                          const juce::AudioIODeviceCallbackContext& /*context*/) override {
        if (outputChannelData == nullptr || numOutputChannels <= 0 || numSamples <= 0) {
            return;
        }

        float* const left = outputChannelData[0];
        if (left == nullptr) {
            return;
        }
        float* const right = numOutputChannels >= 2 ? outputChannelData[1] : left;

        // Clear all output channels before rendering so no stale samples
        // remain from the previous block.
        for (int ch = 0; ch < numOutputChannels; ++ch) {
            float* const out = outputChannelData[ch];
            if (out != nullptr) {
                juce::FloatVectorOperations::clear(out, numSamples);
            }
        }

        const bool shouldPlay = playing.load(std::memory_order_acquire);
        const double rate = sampleRate.load(std::memory_order_acquire);
        const double playheadStart = owner.playheadBeats();
        if (shouldPlay) {
            owner.readMasterMix(left, numSamples, rate, playheadStart);
            owner.advancePlayheadForBlock(numSamples, rate);
            // Mono master → L=R duplicate so stereo speakers both hear it.
            if (right != left) {
                juce::FloatVectorOperations::copy(right, left, numSamples);
            }
        }
        // Preview mix is stereo: the fallback oscillator writes per-voice
        // panned output to L/R; the preset preview renderers are still mono
        // and duplicate to L=R inside readPreviewMix.
        if (owner.hasPreviewActivity()) {
            owner.readPreviewMix(left, right, numSamples, rate);
        }
        if (owner.hasLiveVoices()) {
            owner.readLiveMix(left, numSamples, rate);
            // readLiveMix is mono: duplicate to right.
            if (right != left) {
                juce::FloatVectorOperations::copy(right, left, numSamples);
            }
        }
    }
};

EngineHost::EngineHost() : impl_(std::make_unique<Impl>(*this)), project_(std::make_unique<ProjectEngine>()) {
    ensureSampleBankReady();
    registerAllCommands();
}

EngineHost::~EngineHost() {
    if (impl_->audioInitialized.load(std::memory_order_acquire)) {
        impl_->deviceManager.removeAudioCallback(impl_.get());
        impl_->deviceManager.closeAudioDevice();
    }
}

std::string EngineHost::ping() const {
    return "pong";
}

void EngineHost::setPlaying(bool shouldPlay) {
    if (shouldPlay && isAudioOutputEnabled()) {
        impl_->ensureAudioInitialized();
        if (!impl_->audioInitialized.load(std::memory_order_acquire)) {
            project_->setPlaying(false);
            return;
        }
    }

    project_->setPlaying(shouldPlay);
    impl_->playing.store(shouldPlay, std::memory_order_release);
    impl_->oscillator.setEnabled(shouldPlay);
}

bool EngineHost::isPlaying() const noexcept {
    return impl_->playing.load(std::memory_order_acquire);
}

bool EngineHost::configureAudioEngine(const std::string& profile,
                                      int sampleRate,
                                      int framesPerCallback,
                                      int bufferCapacityFrames,
                                      int bufferSizeFrames,
                                      bool /*lowLatency*/,
                                      bool /*exclusive*/) {
    if (profile != "low_latency" && profile != "balanced" &&
        profile != "safe" && profile != "custom") {
        return false;
    }
    if (profile == "custom" &&
        (sampleRate < 8000 || sampleRate > 192000 ||
         framesPerCallback < 16 || framesPerCallback > 4096 ||
         bufferCapacityFrames < 64 || bufferCapacityFrames > 32768 ||
         bufferSizeFrames < 16 || bufferSizeFrames > bufferCapacityFrames)) {
        return false;
    }
    setPlaying(false);
    stopPreview();
    allNotesOff();
    impl_->audioProfile = profile;
    if (profile == "custom") {
        impl_->requestedSampleRate = sampleRate;
        impl_->requestedFramesPerCallback = framesPerCallback;
        impl_->requestedBufferCapacity = bufferCapacityFrames;
        impl_->requestedBufferSize = bufferSizeFrames;
    }
    return true;
}

std::string EngineHost::getAudioEngineStatusJson() const {
    auto* status = new juce::DynamicObject();
    status->setProperty("ok", true);
    status->setProperty("profile", juce::String(impl_->audioProfile));
    status->setProperty("platform", "JUCE");
    status->setProperty("streamOpen", impl_->audioInitialized.load(std::memory_order_acquire));
    status->setProperty("sampleRate", impl_->sampleRate.load(std::memory_order_acquire));
    status->setProperty("framesPerBurst", 0);
    status->setProperty("bufferSizeFrames", 0);
    status->setProperty("bufferCapacityFrames", 0);
    status->setProperty("framesPerCallback", 0);
    status->setProperty("xRunCount", 0);
    status->setProperty("callbackOverruns", 0);
    status->setProperty("maxCallbackMicros", 0.0);
    status->setProperty("requestedSampleRate", impl_->requestedSampleRate);
    status->setProperty("requestedFramesPerCallback", impl_->requestedFramesPerCallback);
    status->setProperty("requestedBufferCapacityFrames", impl_->requestedBufferCapacity);
    status->setProperty("requestedBufferSizeFrames", impl_->requestedBufferSize);
    status->setProperty("sharingMode", "system");
    status->setProperty("performanceMode", juce::String(impl_->audioProfile));
    return juce::JSON::toString(juce::var(status), true).toStdString();
}

void EngineHost::ensureAudioOutput() {
    if (isAudioOutputEnabled()) {
        impl_->ensureAudioInitialized();
    }
}

} // namespace audioapp
