#pragma once

namespace audioapp {

class SampleBank;
class WavetableBank;
class DeviceRegistry;

struct PlaybackBuildContext {
    const SampleBank* sampleBank = nullptr;
    const WavetableBank* wavetableBank = nullptr;
    const DeviceRegistry* deviceRegistry = nullptr;
};

} // namespace audioapp
