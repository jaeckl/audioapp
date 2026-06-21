# Library UI Refinements — Test Contract

## New test files

| Test file | Package | Type | Description |
|---|---|---|---|
| `app_flutter/test/library_cache_test.dart` | WP-CACHE | Unit | `ClipPreviewCache` put/get/evict/clear |
| `app_flutter/test/library_click_test.dart` | WP-CLICK | Widget | Tap→preview dispatch for all item types |
| `app_flutter/test/library_preset_bar_test.dart` | WP-PRESET | Widget | `PresetPreviewBar` rendering, scrub, loop toggle |
| `engine_juce/tests/fallback_oscillator_test.cpp` | WP-MIDI | Unit | Polyphonic oscillator voice management |

## Existing test updates

| Test file | Package | Changes |
|---|---|---|
| `app_flutter/test/library_content_pane_test.dart` (if exists) | WP-CLICK | Update for new callbacks (onMidiPreviewTap, onAutomationPreviewTap) |
| `app_flutter/test/library_fly_in_panel_test.dart` (if exists) | WP-CLICK, WP-PRESET | Update for preview state, PresetPreviewBar |

## WP-CACHE tests (`library_cache_test.dart`)

```dart
void main() {
  group('ClipPreviewCache', () {
    test('put and get returns correct data', () { ... });
    test('get returns null for missing key', () { ... });
    test('evicts LRU entry when at capacity', () { ... });
    test('clear removes all entries', () { ... });
    test('remove removes single entry', () { ... });
    test('containsKey returns correct values', () { ... });
    test('access order promotes entry (LRU)', () { ... });
    test('kMaxCacheEntries constant is 50', () { ... });
  });
}
```

### Test data
```dart
final _sampleData1 = ClipPreviewData(
  peaks: [0.1, 0.2, 0.3, 0.4, 0.5],
  length: const Duration(seconds: 2),
);
final _sampleData2 = ClipPreviewData(
  peaks: [0.5, 0.4, 0.3, 0.2, 0.1],
  length: const Duration(seconds: 4),
);
```

## WP-CLICK tests (`library_click_test.dart`)

```dart
void main() {
  group('LibraryContentPane tap behavior', () {
    testWidgets('tap on audio item calls onPreviewAudio', (tester) async { ... });
    testWidgets('tap on MIDI item calls onMidiPreviewTap', (tester) async { ... });
    testWidgets('tap on automation item calls onAutomationPreviewTap', (tester) async { ... });
    testWidgets('tap on preset item calls onPresetTap', (tester) async { ... });
    testWidgets('same-item re-tap restarts preview', (tester) async {
      // Verify callback called twice
    });
    testWidgets('different-item tap stops first preview', (tester) async {
      // Verify first item stopped, second started
    });
    testWidgets('play button triggers preview not insert', (tester) async { ... });
  });
}
```

### Test setup
- Mock `ProjectSnapshot` with at least one track containing devices
- Mock `LibraryManifest` with presets and MIDI clips
- Capture callback invocations via `Callback` matchers or spy variables

## WP-PRESET tests (`library_preset_bar_test.dart`)

```dart
void main() {
  group('PresetPreviewBar', () {
    testWidgets('renders clip blocks from TrackSnapshot', (tester) async { ... });
    testWidgets('scrub drag updates playhead', (tester) async { ... });
    testWidgets('loop toggle calls onLoopToggled', (tester) async { ... });
    testWidgets('hides when preset deselected', (tester) async { ... });
  });

  group('LibraryFlyInPanel preset integration', () {
    testWidgets('preset tap shows PresetPreviewBar', (tester) async { ... });
    testWidgets('category switch hides bar', (tester) async { ... });
    testWidgets('library close hides bar', (tester) async { ... });
  });
}
```

### Test data
- `TrackSnapshot` with 2-3 MIDI/audio clips at various positions
- `LibraryPresetItem` with known deviceType

## WP-MIDI tests (`fallback_oscillator_test.cpp`)

```cpp
TEST_CASE("FallbackPreviewOscillator single note") {
    FallbackPreviewOscillator osc;
    osc.noteOn(60, 100.0f, 0.0, 1.0);
    // Process block at sampleRate=48000, bpm=120
    // Verify output contains correct frequency (261.63 Hz for MIDI 60)
}

TEST_CASE("FallbackPreviewOscillator polyphonic 8 voices") {
    FallbackPreviewOscillator osc;
    for (int i = 0; i < 8; i++) {
        osc.noteOn(60 + i, 100.0f, 0.0, 1.0);
    }
    // Process block, verify all 8 frequencies present in output
}

TEST_CASE("FallbackPreviewOscillator voice stealing") {
    FallbackPreviewOscillator osc;
    for (int i = 0; i < 9; i++) {
        osc.noteOn(60 + i, 100.0f, 0.0, 1.0);
    }
    // Voice 0 should be stolen (oldest)
    // Verify frequencies for voices 1-8
}

TEST_CASE("FallbackPreviewOscillator allNotesOff") {
    FallbackPreviewOscillator osc;
    osc.noteOn(60, 100.0f, 0.0, 1.0);
    osc.allNotesOff();
    // Process block, verify silence
}

TEST_CASE("FallbackPreviewOscillator zero voices produces silence") {
    FallbackPreviewOscillator osc;
    // No notes active
    // Process block, verify silence
}
```

### Test approach
- Generate N samples, run FFT or zero-crossing to verify pitch per voice
- Or sum and compare against expected multi-tone waveform
- Voice management tested by counting active voices and verifying steal index

## Acceptance criteria mapping

| Criteria | Tests |
|---|---|
| C1: Tap→audio feedback for all item types | WP-CLICK tests (all 4 item types) |
| C2: MIDI polyphonic (8+ voices) | WP-MIDI oscillator tests (8 voices, voice stealing) |
| C3: MIDI preview loops | Manual verification (test environment limitation) |
| C4: Automation tap triggers preview | WP-CLICK automation tap test |
| C5: Preset preview bar | WP-PRESET widget tests |
| C6: No spinner flash on cache hit | WP-CACHE unit tests (get returns cached) |
| C7: LRU eviction at 50 | WP-CACHE eviction test |
| C8: Same-item re-tap restarts | WP-CLICK same-item test |