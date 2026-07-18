#pragma once

#include "audioapp/DedicatedPercussionAlgorithm.hpp"
#include "audioapp/dsp/DeviceProcessor.hpp"

namespace audioapp {

class HihatProcessor final : public DeviceProcessor {
    HihatGeneratorRuntime runtime_{};
public:
    void process(AudioBlock&, ProcessContext&) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::HihatGenerator; }
    void resetPlaybackState() noexcept override { runtime_ = {}; }
};

class RideProcessor final : public DeviceProcessor {
    RideGeneratorRuntime runtime_{};
public:
    void process(AudioBlock&, ProcessContext&) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::RideGenerator; }
    void resetPlaybackState() noexcept override { runtime_ = {}; }
};

class TomProcessor final : public DeviceProcessor {
    TomGeneratorRuntime runtime_{};
public:
    void process(AudioBlock&, ProcessContext&) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::TomGenerator; }
    void resetPlaybackState() noexcept override { runtime_ = {}; }
};

class RimshotProcessor final : public DeviceProcessor {
    RimshotGeneratorRuntime runtime_{};
public:
    void process(AudioBlock&, ProcessContext&) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::RimshotGenerator; }
    void resetPlaybackState() noexcept override { runtime_ = {}; }
};

} // namespace audioapp
