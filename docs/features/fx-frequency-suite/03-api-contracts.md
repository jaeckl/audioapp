# Frequency FX Suite — API Contracts

## IDeviceType Implementations

### FilterDeviceType

```cpp
class FilterDeviceType final : public IDeviceType {
    std::string typeId() const override;                         // → "filter"
    DeviceSlot createDefault(const std::string& deviceId) const override;
    DeviceParameterResult setParameter(DeviceSlot& slot,
                                       std::string_view parameterId,
                                       float value) const override;
    bool setStringParameter(DeviceSlot&, std::string_view,
                            const std::string&,
                            const PlaybackBuildContext&) const override;  // → false
    std::vector<std::string_view> modulatableParams() const override;
    void buildPlaybackNode(const DeviceSlot& slot,
                           const PlaybackBuildContext& context,
                           DeviceNodePlayback& out) const override;
    bool buildLiveInstrument(const DeviceSlot&, const PlaybackBuildContext&,
                             LiveInstrumentSnapshot&) const override;  // → false
    juce::var slotToVar(const DeviceSlot& slot) const override;
    DeviceSlot varToSlot(const juce::var& obj) const override;
};
```

### FourBandEqDeviceType

Same interface pattern. typeId() → "four_band_eq".

### FrequencyShifterDeviceType

Same interface pattern. typeId() → "frequency_shifter".

## Processing Functions

All in `audioapp::` namespace, declared in `FrequencyFxProcessor.hpp`:

```cpp
// Filter: stereo in-place biquad (also used by single-channel eq processing)
void processBiquadStereoBlock(float* left,
                              float* right,
                              int numFrames,
                              const BiquadCoeffs& coeffs,
                              BiquadState state[2]) noexcept;
void cookFilterCoeffs(BiquadCoeffs& coeffs,
                      int mode,
                      double sampleRate,
                      float cutoffHz,
                      float q) noexcept;

void processFilterStereoBlock(float* trackLeft,
                              float* trackRight,
                              int numFrames,
                              double sampleRate,
                              const FilterParams& params,
                              FilterRuntime& runtime) noexcept;

void processFourBandEqStereoBlock(float* trackLeft,
                                  float* trackRight,
                                  int numFrames,
                                  double sampleRate,
                                  const FourBandEqParams& params,
                                  FourBandEqRuntime& runtime) noexcept;

void processFrequencyShifterStereoBlock(float* trackLeft,
                                        float* trackRight,
                                        int numFrames,
                                        double sampleRate,
                                        const FrequencyShifterParams& params,
                                        FrequencyShifterRuntime& runtime) noexcept;

// Helper: normalized (0-1) to frequency (20-20000 Hz)
float normalizedToFrequency(float normalized) noexcept;

// Helper: normalized (0-1) to Q (0.1-20)
float normalizedToQ(float normalized) noexcept;

// Helper: normalized (0-1) to dB (-24 to +24)
float normalizedToDb(float normalized) noexcept;
```

## Parameter Setting

Each device type implements `setParameter()` per the pattern:

**FilterDeviceType::setParameter**:
- `"gain"`, `"pan"`, `"bypass"`: delegated to `device_strip::setStripParameter()`
- `"ffxCutoff"`: `instance.ffxCutoff = std::clamp(value, 0.0f, 1.0f)`
- `"ffxResonance"`: `instance.ffxResonance = std::clamp(value, 0.0f, 1.0f)`
- `"ffxFilterMode"`: `instance.ffxFilterMode = std::clamp(value, 0.0f, 1.0f)`

**FourBandEqDeviceType::setParameter**:
- `"ffxBand{N}Freq"`: normalized 0-1 for band N (1-4)
- `"ffxBand{N}Gain"`: normalized 0-1
- `"ffxBand{N}Q"`: normalized 0-1

**FrequencyShifterDeviceType::setParameter**:
- `"ffxShift"`: normalized 0-1 (center=0.5 = no shift)

## Modulatable Params

**Filter**: `{"gain", "pan", "ffxCutoff", "ffxResonance", "ffxFilterMode"}`

**4-Band EQ**: `{"gain", "pan", "ffxBand1Freq", "ffxBand1Gain", "ffxBand1Q", "ffxBand2Freq", "ffxBand2Gain", "ffxBand2Q", "ffxBand3Freq", "ffxBand3Gain", "ffxBand3Q", "ffxBand4Freq", "ffxBand4Gain", "ffxBand4Q"}`

**Frequency Shifter**: `{"gain", "pan", "ffxShift"}`

## Meters

All three publish `inputLevel` (peak meter before processing) via `DeviceMeterAtomic`:

```cpp
float inputPeak = stereoBlockPeak(trackLeft, trackRight, framesToProcess);
// store to deviceMeters[node.meterSlot].inputPeak
```