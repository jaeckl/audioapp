#pragma once

namespace audioapp {

class SampleBank;

struct PlaybackBuildContext {
    const SampleBank* sampleBank = nullptr;
};

} // namespace audioapp
