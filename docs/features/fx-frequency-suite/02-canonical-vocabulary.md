# Frequency FX Suite — Canonical Vocabulary

| Concept | Canonical Name | Type/File | Notes |
|---------|---------------|-----------|-------|
| Category | Frequency FX | `DeviceStripChrome._dynamicsTypes` | Uses DynamicsInputPanel + DynamicsOutputPanel |
| Filter type ID | `kFilter = "filter"` | `DeviceTypeIds.hpp` | `audioapp::device_types::kFilter` |
| Filter class | `FilterDeviceType` | `FilterDeviceType.hpp/.cpp` | Subclass of `IDeviceType` |
| Filter instance | `FilterInstance` | `FrequencyFxInstance.hpp` | Control-thread state |
| Filter params | `FilterParams` | `FrequencyFxProcessor.hpp` | Audio-thread snapshot |
| Filter runtime | `FilterRuntime` | `FrequencyFxProcessor.hpp` | Per-channel biquad state |
| Filter kind | `DeviceNodeKind::Filter` | `DeviceChain.hpp` | |
| EQ type ID | `kFourBandEq = "four_band_eq"` | `DeviceTypeIds.hpp` | |
| EQ class | `FourBandEqDeviceType` | `FourBandEqDeviceType.hpp/.cpp` | |
| EQ instance | `FourBandEqInstance` | `FrequencyFxInstance.hpp` | |
| EQ params | `FourBandEqParams` | `FrequencyFxProcessor.hpp` | |
| EQ runtime | `FourBandEqRuntime` | `FrequencyFxProcessor.hpp` | Per-band×channel biquad state |
| EQ kind | `DeviceNodeKind::FourBandEq` | `DeviceChain.hpp` | |
| Freq shifter type ID | `kFrequencyShifter = "frequency_shifter"` | `DeviceTypeIds.hpp` | |
| Freq shifter class | `FrequencyShifterDeviceType` | `FrequencyShifterDeviceType.hpp/.cpp` | |
| Freq shifter instance | `FrequencyShifterInstance` | `FrequencyFxInstance.hpp` | |
| Freq shifter params | `FrequencyShifterParams` | `FrequencyFxProcessor.hpp` | |
| Freq shifter runtime | `FrequencyShifterRuntime` | `FrequencyFxProcessor.hpp` | SSB phase accumulator |
| Freq shifter kind | `DeviceNodeKind::FrequencyShifter` | `DeviceChain.hpp` | |
| Filter cutoff | `ffxCutoff` | Per-device param | Normalized 0-1 → 20-20000 Hz |
| Filter resonance | `ffxResonance` | Per-device param | Normalized 0-1 → Q 0.1-20 |
| Filter mode | `ffxFilterMode` | Per-device param | 0=LP, 0.33=HP, 0.67=BP, 1.0=Notch |
| EQ band 1 freq | `ffxBand1Freq` | Per-device param | Low shelf frequency |
| EQ band 1 gain | `ffxBand1Gain` | Per-device param | Normalized 0-1 → -24 to +24 dB |
| EQ band 1 Q | `ffxBand1Q` | Per-device param | Shelf Q |
| EQ band 2 freq | `ffxBand2Freq` | Per-device param | Low-mid peak frequency |
| EQ band 2 gain | `ffxBand2Gain` | Per-device param | Peak gain |
| EQ band 2 Q | `ffxBand2Q` | Per-device param | Peak Q |
| EQ band 3 freq | `ffxBand3Freq` | Per-device param | High-mid peak frequency |
| EQ band 3 gain | `ffxBand3Gain` | Per-device param | Peak gain |
| EQ band 3 Q | `ffxBand3Q` | Per-device param | Peak Q |
| EQ band 4 freq | `ffxBand4Freq` | Per-device param | High shelf frequency |
| EQ band 4 gain | `ffxBand4Gain` | Per-device param | Shelf gain |
| EQ band 4 Q | `ffxBand4Q` | Per-device param | Shelf Q |
| Shift amount | `ffxShift` | Per-device param | Normalized 0-1 → -2000 to +2000 Hz |
| Filter preview | `FilterPreview` | `filter_preview.dart` | CustomPainter |
| EQ preview | `FourBandEqPreview` | `eq_preview.dart` | CustomPainter |