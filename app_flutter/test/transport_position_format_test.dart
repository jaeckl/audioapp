import 'package:audioapp/features/transport/transport_position_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('playheadCompact formats bar beat tick', () {
    expect(TransportPositionFormat.playheadCompact(0), '001.01.0');
    expect(TransportPositionFormat.playheadCompact(4.5), '002.01.2');
    expect(TransportPositionFormat.playheadCompact(9.75), '003.02.3');
  });

  test('elapsedClock converts beats at bpm', () {
    expect(TransportPositionFormat.elapsedClock(0, 120), '0:00');
    expect(TransportPositionFormat.elapsedClock(60, 120), '0:30');
    expect(TransportPositionFormat.elapsedClock(120, 120), '1:00');
  });

  test('loopBarRange uses bar numbers', () {
    expect(TransportPositionFormat.loopBarRange(0, 16), '1–4');
    expect(TransportPositionFormat.loopBarRange(4, 8), '2');
  });
}
