import 'package:flutter/material.dart';

import 'effective_parameter_monitor.dart';

/// Supplies the containing device id to every parameter control in a strip,
/// including shared chrome and bespoke editors.
class EffectiveParameterScope extends InheritedWidget {
  const EffectiveParameterScope({
    super.key,
    required this.deviceId,
    required super.child,
  });

  final String deviceId;

  static String? maybeDeviceIdOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<EffectiveParameterScope>()
      ?.deviceId;

  @override
  bool updateShouldNotify(EffectiveParameterScope oldWidget) =>
      oldWidget.deviceId != deviceId;
}

/// Rebuilds a non-knob control with its automation-adjusted (pre-modulation)
/// value. The fallback remains authoritative when no live value is available.
class EffectiveParameterValueBuilder extends StatefulWidget {
  const EffectiveParameterValueBuilder({
    super.key,
    required this.parameterId,
    required this.fallbackValue,
    required this.active,
    required this.builder,
    this.deviceId,
  });

  final String parameterId;
  final double fallbackValue;
  final bool active;
  final String? deviceId;
  final Widget Function(BuildContext context, double value) builder;

  @override
  State<EffectiveParameterValueBuilder> createState() =>
      _EffectiveParameterValueBuilderState();
}

class _EffectiveParameterValueBuilderState
    extends State<EffectiveParameterValueBuilder> {
  EffectiveParameterKey? _key;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRegistration();
  }

  @override
  void didUpdateWidget(EffectiveParameterValueBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRegistration();
  }

  EffectiveParameterKey? _resolvedKey() {
    if (!widget.active) return null;
    final deviceId =
        widget.deviceId ?? EffectiveParameterScope.maybeDeviceIdOf(context);
    if (deviceId == null) return null;
    return (deviceId: deviceId, parameterId: widget.parameterId);
  }

  void _syncRegistration() {
    final next = _resolvedKey();
    if (next == _key) return;
    if (_key != null) effectiveParameterMonitor.unregister(_key!);
    _key = next;
    if (_key != null) effectiveParameterMonitor.register(_key!);
  }

  @override
  void dispose() {
    if (_key != null) effectiveParameterMonitor.unregister(_key!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: effectiveParameterMonitor,
      builder: (context, _) {
        final value = _key == null
            ? widget.fallbackValue
            : effectiveParameterMonitor.valueFor(_key!) ?? widget.fallbackValue;
        return widget.builder(context, value.clamp(0.0, 1.0).toDouble());
      },
    );
  }
}

/// Convenience wrapper for custom editors whose geometry depends on several
/// independently automated parameters.
class EffectiveParameterValuesBuilder extends StatelessWidget {
  const EffectiveParameterValuesBuilder({
    super.key,
    required this.fallbackValues,
    required this.activeParameterIds,
    required this.builder,
  });

  final Map<String, double> fallbackValues;
  final Set<String> activeParameterIds;
  final Widget Function(BuildContext context, Map<String, double> values)
      builder;

  @override
  Widget build(BuildContext context) {
    final entries = fallbackValues.entries.toList(growable: false);
    final values = Map<String, double>.of(fallbackValues);

    Widget compose(int index) {
      if (index >= entries.length) return builder(context, values);
      final entry = entries[index];
      return EffectiveParameterValueBuilder(
        parameterId: entry.key,
        fallbackValue: entry.value,
        active: activeParameterIds.contains(entry.key),
        builder: (context, liveValue) {
          values[entry.key] = liveValue;
          return compose(index + 1);
        },
      );
    }

    return compose(0);
  }
}
