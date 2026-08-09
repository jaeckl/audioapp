#pragma once

namespace audioapp {

/// Serum-style morph wavetable for subtractive osc shapes:
/// frames = sine → tri → saw → square → pulse, with mip levels picked by Hz.
struct SubtractiveMorphTable {
    static constexpr int kFrames = 5;
    static constexpr int kBaseLength = 2048;
    static constexpr int kMipCount = 7; // 2048 … 32

    /// Shape + mip resolved once per osc bank; phase lookup only per unison.
    struct PreparedLookup {
        const float* frameA = nullptr;
        const float* frameB = nullptr;
        float frameFrac = 0.0f;
        int len = 0;
    };

    static const SubtractiveMorphTable& instance() noexcept;

    int lengthForMip(int mip) const noexcept;
    int pickMip(float rootHz, float sampleRate) const noexcept;

    /// phaseRadians in [0, 2π) (wrap OK). shape in [0, 1] morphs across frames.
    float lookup(float shape,
                 float phaseRadians,
                 float rootHz,
                 float sampleRate) const noexcept;

    float lookupMip(float shape, float phaseRadians, int mip) const noexcept;

    PreparedLookup prepareLookup(float shape, int mip) const noexcept;
    float lookupPrepared(const PreparedLookup& prep, float phaseRadians) const noexcept;

    const float* frameData(int mip, int frame) const noexcept;

private:
    struct Storage;
    SubtractiveMorphTable();
    Storage* storage_ = nullptr;
    float* pcm_ = nullptr;
    int mipOffsets_[kMipCount]{};
};

} // namespace audioapp
