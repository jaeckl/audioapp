#pragma once

namespace audioapp {

class SampleBank;
class WavetableBank;

struct PlaybackBuildContext {
    const SampleBank* sampleBank = nullptr;
    const WavetableBank* wavetableBank = nullptr;
};

} // namespace audioapp
