part of 'clip_snapshots.dart';

class AutomationPointSnapshot {
  const AutomationPointSnapshot({
    required this.beat,
    required this.value,
  });

  final double beat;
  final double value;

  factory AutomationPointSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return AutomationPointSnapshot(
      beat: (map['beat'] as num?)?.toDouble() ?? 0.0,
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'beat': beat,
        'value': value,
      };
}
