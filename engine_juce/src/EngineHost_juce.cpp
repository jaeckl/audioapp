#include "audioapp/EngineHost.hpp"
#include "audioapp/TestOscillator.hpp"

#include <juce_audio_devices/juce_audio_devices.h>
#include <juce_events/juce_events.h>

#include <atomic>
#include <cstring>
#include <mutex>

namespace audioapp {

struct EngineHost::Impl : juce::AudioIODeviceCallback {
    explicit Impl(EngineHost& host) : owner(host) {}

    EngineHost& owner;
    juce::AudioDeviceManager deviceManager;
    TestOscillator oscillator;
    std::atomic<bool> playing{false};
    std::atomic<double> sampleRate{48000.0};
    std::atomic<bool> audioInitialized{false};
    std::mutex initMutex;

    void ensureAudioInitialized() {
        if (audioInitialized.load(std::memory_order_acquire)) {
            return;
        }

        std::lock_guard<std::mutex> lock(initMutex);
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

        const bool shouldPlay = playing.load(std::memory_order_acquire);
        const double rate = sampleRate.load(std::memory_order_acquire);
        const double playheadStart = owner.playheadBeats();
        if (shouldPlay) {
            owner.readMasterMix(left, numSamples, rate, playheadStart);
            owner.advancePlayheadForBlock(numSamples, rate);
        } else {
            juce::FloatVectorOperations::clear(left, numSamples);
        }
        owner.readPreviewMix(left, numSamples, rate);
        owner.readLiveMix(left, numSamples, rate);

        for (int ch = 1; ch < numOutputChannels; ++ch) {
            float* const out = outputChannelData[ch];
            if (out == nullptr || out == left) {
                continue;
            }
            juce::FloatVectorOperations::copy(out, left, numSamples);
        }
    }
};

EngineHost::EngineHost() : impl_(std::make_unique<Impl>(*this)) {
    ensureSampleBankReady();
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
    if (shouldPlay) {
        impl_->ensureAudioInitialized();
        if (!impl_->audioInitialized.load(std::memory_order_acquire)) {
            project_.setPlaying(false);
            return;
        }
    }

    project_.setPlaying(shouldPlay);
    impl_->playing.store(shouldPlay, std::memory_order_release);
    impl_->oscillator.setEnabled(shouldPlay);
}

bool EngineHost::isPlaying() const noexcept {
    return impl_->playing.load(std::memory_order_acquire);
}

void EngineHost::ensureAudioOutput() {
    impl_->ensureAudioInitialized();
}

} // namespace audioapp
