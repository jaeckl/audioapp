import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/live_automation_value.dart';
import 'package:flutter_test/flutter_test.dart';

AutomationClipSnapshot clip({bool loop = false}) => AutomationClipSnapshot(
      id: 'auto',
      homeTrackId: 'track',
      startBeat: 4,
      lengthBeats: 8,
      naturalLengthBeats: 4,
      loopContent: loop,
      deviceId: 'osc',
      paramId: 'frequency',
      points: const [
        AutomationPointSnapshot(beat: 0, value: 0),
        AutomationPointSnapshot(beat: 4, value: 1),
      ],
    );

void main() {
  test('interpolates automation at the project playhead', () {
    expect(automationValueAtBeat(clip(), 5), .25);
    expect(automationValueAtBeat(clip(), 3.9), isNull);
    expect(automationValueAtBeat(clip(), 8), isNull);
  });

  test('wraps looped automation content', () {
    expect(automationValueAtBeat(clip(loop: true), 9), .25);
  });

  test('applies normalized automation without changing stored snapshot', () {
    const device = OscillatorDeviceSnapshot(
      id: 'osc',
      gain: 1,
      pan: .5,
      bypassed: false,
      meterGainReductionDb: 0,
      meterInputLevel: 0,
      frequencyHz: 440,
    );
    final display =
        applyLiveAutomation(device, [clip()], 5) as OscillatorDeviceSnapshot;
    expect(display.frequencyHz, 515);
    expect(device.frequencyHz, 440);
  });

  test('restores the manual snapshot outside or without automation', () {
    const device = OscillatorDeviceSnapshot(
      id: 'osc',
      gain: 1,
      pan: .5,
      bypassed: false,
      meterGainReductionDb: 0,
      meterInputLevel: 0,
      frequencyHz: 440,
    );
    expect(applyLiveAutomation(device, [clip()], 2), same(device));
    expect(applyLiveAutomation(device, const [], 5), same(device));
  });
}
