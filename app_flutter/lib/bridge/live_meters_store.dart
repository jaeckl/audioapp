import 'package:flutter/foundation.dart';

import 'live_meters_dto.dart';

/// Live dynamics meter readings decoupled from [ProjectSnapshot].
///
/// Updated from the native meter EventChannel without rebuilding the full
/// project tree during arrangement playback.
class LiveMetersStore extends ChangeNotifier
    implements ValueListenable<Map<String, DeviceMeterReading>> {
  Map<String, DeviceMeterReading> _readings = const {};

  @override
  Map<String, DeviceMeterReading> get value => _readings;

  DeviceMeterReading? operator [](String deviceId) => _readings[deviceId];

  void clear() {
    if (_readings.isEmpty) return;
    _readings = const {};
    notifyListeners();
  }

  void applyBatch(LiveMetersBatch batch) {
    if (batch.meters.isEmpty) return;

    var changed = false;
    final next = Map<String, DeviceMeterReading>.from(_readings);
    for (final reading in batch.meters) {
      final prev = next[reading.deviceId];
      if (prev != null &&
          prev.gainReductionDb == reading.gainReductionDb &&
          prev.inputLevel == reading.inputLevel &&
          prev.leftLevel == reading.leftLevel &&
          prev.rightLevel == reading.rightLevel &&
          prev.loudnessLufs == reading.loudnessLufs &&
          prev.correlation == reading.correlation &&
          identical(prev.waveform, reading.waveform) &&
          identical(prev.spectrum, reading.spectrum)) {
        continue;
      }
      next[reading.deviceId] = reading;
      changed = true;
    }
    if (!changed) return;
    _readings = next;
    notifyListeners();
  }
}
