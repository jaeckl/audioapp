import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/bridge/live_meters_dto.dart';
import 'package:audioapp/features/device_strip/analysis_device_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('analysis meter payload parses visualization frames', () {
    final reading = DeviceMeterReading.fromMap({
      'in': .8,
      'lufs': -14.2,
      'corr': .75,
      'wave': [0, .5, -.5],
      'spectrum': [.2, .8],
    }, 'meter-1');
    expect(reading.loudnessLufs, -14.2);
    expect(reading.correlation, .75);
    expect(reading.waveform, [0, .5, -.5]);
    expect(reading.spectrum, [.2, .8]);
  });

  test('all analysis device types parse as dedicated snapshots', () {
    for (final type in const [
      'oscilloscope',
      'spectrum_analyzer',
      'loudness_meter',
      'stereo_imager'
    ]) {
      expect(DeviceSnapshot.fromMap({'id': type, 'type': type}),
          isA<AnalysisDeviceSnapshot>());
    }
  });

  testWidgets('analysis panel reserves most space for visualization',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 280,
              child: AnalysisDevicePanel(
                type: 'loudness_meter',
                reading: DeviceMeterReading(
                  deviceId: 'meter',
                  inputLevel: .7,
                  loudnessLufs: -12.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('LUFS'), findsOneWidget);
    expect(find.text('RESET'), findsOneWidget);
  });
}
