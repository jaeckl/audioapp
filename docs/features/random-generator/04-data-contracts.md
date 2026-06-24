# Data Contracts: Random Generator Modulator

## C++ Variant Update

```cpp
// Before:
using ModulatorParams = std::variant<LfoParams, EnvelopeParams>;

// After:
using ModulatorParams = std::variant<LfoParams, EnvelopeParams, RandomGeneratorParams>;
```

The `ModulatorRecord` struct needs no changes — it already holds `ModulatorParams` as a variant which will accept the new type.

## Enum Updates

```cpp
// ModulatorType (ModulationTypes.hpp)
enum class ModulatorType : int {
    Lfo = 0,
    Envelope = 1,
    RandomGenerator = 2,  // NEW
};
```

## Flutter Type Constants

```dart
// modulator_types.dart
class ModulatorTypes {
  static const int lfo = 0;
  static const int envelope = 1;
  static const int randomGenerator = 2;  // NEW
  static const int maxCount = 16;
  static String labelFor(int type) => switch (type) {
    0 => 'LFO',
    1 => 'ENV',
    2 => 'RND',       // NEW
    _ => '?',
  };
}
```

## Flutter LfoSnapshot Updates

```dart
// In copyWith() — add smoothing
double? smoothing;

// In fromJson() — parse smoothing
smoothing: json['smoothing'] ?? 0.0,

// In toJson() — serialize smoothing
if (modulatorType == ModulatorTypes.randomGenerator) {
  'smoothing': smoothing,
}

// In applyParamUpdate() — add case for random generator
case ModulatorTypes.randomGenerator:
  switch (param) {
    case 'rate':       rate = value; break;
    case 'smoothing':  smoothing = value; break;
    case 'retrigger':  retrigger = value.toInt(); break;
    case 'polarity':   polarity = value.toInt(); break;
  }
```