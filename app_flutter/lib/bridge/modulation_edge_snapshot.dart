part of 'project_snapshot.dart';

class ModulationEdgeSnapshot {
  const ModulationEdgeSnapshot({
    required this.lfoId,
    required this.deviceId,
    required this.paramId,
    this.amount = 0.0,
  });

  final int lfoId;
  final String deviceId;
  final String paramId;
  final double amount;

  factory ModulationEdgeSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return ModulationEdgeSnapshot(
      lfoId: (map['lfoId'] as num?)?.toInt() ?? 0,
      deviceId: map['deviceId'] as String? ?? '',
      paramId: map['paramId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ModulationEdgeSnapshot copyWith({
    int? lfoId,
    String? deviceId,
    String? paramId,
    double? amount,
  }) {
    return ModulationEdgeSnapshot(
      lfoId: lfoId ?? this.lfoId,
      deviceId: deviceId ?? this.deviceId,
      paramId: paramId ?? this.paramId,
      amount: amount ?? this.amount,
    );
  }
}
