import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../bridge/engine_bridge.dart';

typedef EffectiveParameterKey = ({String deviceId, String parameterId});

typedef MonitoredParameterValue = ({
  double automationBase,
  double effectiveValue,
});

/// Coalesced presentation-only polling for visible automated/modulated knobs.
/// Values never enter project state and can therefore never feed back to DSP.
class EffectiveParameterMonitor extends ChangeNotifier {
  EngineBridge? _bridge;
  Timer? _timer;
  bool _polling = false;
  final Map<EffectiveParameterKey, int> _references = {};
  final Map<EffectiveParameterKey, MonitoredParameterValue> _values = {};

  void start(EngineBridge bridge) {
    _bridge = bridge;
    _timer ??= Timer.periodic(const Duration(milliseconds: 33), (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _bridge = null;
    _references.clear();
    _values.clear();
    _polling = false;
  }

  void register(EffectiveParameterKey key) {
    _references.update(key, (count) => count + 1, ifAbsent: () => 1);
  }

  void unregister(EffectiveParameterKey key) {
    final count = _references[key];
    if (count == null) return;
    if (count <= 1) {
      _references.remove(key);
      _values.remove(key);
    } else {
      _references[key] = count - 1;
    }
  }

  /// Widget position after automation, before modulation.
  double? valueFor(EffectiveParameterKey key) => _values[key]?.automationBase;

  /// Final DSP-observed value, available for meters/diagnostics. Controls do
  /// not use this as their position because modulation is drawn separately.
  double? effectiveValueFor(EffectiveParameterKey key) =>
      _values[key]?.effectiveValue;

  Future<void> _poll() async {
    final bridge = _bridge;
    if (bridge == null || _polling || _references.isEmpty) return;
    _polling = true;
    var changed = false;
    try {
      final keys = List<EffectiveParameterKey>.of(_references.keys);
      final values = await bridge.readEffectiveParameterStates(keys);
      for (var index = 0; index < keys.length; index++) {
        final value = values[index];
        if (value == null || !_references.containsKey(keys[index])) continue;
        final monitored = (
          automationBase: value.automationBase.clamp(0.0, 1.0).toDouble(),
          effectiveValue: value.effectiveValue.clamp(0.0, 1.0).toDouble(),
        );
        if (_values[keys[index]] != monitored) {
          _values[keys[index]] = monitored;
          changed = true;
        }
      }
    } catch (_) {
      // A transient bridge failure must not stop the presentation timer.
    } finally {
      _polling = false;
    }
    if (changed) notifyListeners();
  }
}

final effectiveParameterMonitor = EffectiveParameterMonitor();
