#pragma once

#include <string>
#include <vector>
#include <span>

namespace audioapp {

struct WavetableEntry {
    std::string name;
    std::vector<float> pcm;     ///< Interleaved single-cycle frames
    int frameCount = 0;         ///< Number of single-cycle frames
    int frameLength = 0;        ///< Samples per frame
    float sampleRate = 48000.0f;
};

/// Manages a collection of loaded wavetables.
/// Each wavetable is a multi-frame .wav where each frame is a single cycle.
class WavetableBank {
public:
    /// Load a wavetable from raw .wav file bytes.
    /// Returns the index of the loaded wavetable, or -1 on failure.
    int loadFromBytes(const std::string& name, const uint8_t* data, size_t dataSize);

    /// Access loaded wavetable by index.
    const WavetableEntry* get(int index) const noexcept;

    /// Number of loaded wavetables.
    int size() const noexcept { return static_cast<int>(entries_.size()); }

    /// Access all entries.
    std::span<const WavetableEntry> entries() const noexcept { return entries_; }

    /// Find index by name, or -1.
    int findByName(const std::string& name) const noexcept;

    /// Clear all entries.
    void clear() noexcept { entries_.clear(); }

private:
    std::vector<WavetableEntry> entries_;
};

} // namespace audioapp
