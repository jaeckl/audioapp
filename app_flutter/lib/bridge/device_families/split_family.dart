part of '../device_snapshot.dart';

/// LR-split or Mid-Side split device: forks audio into two branches
/// (`branch0`/`branch1`), each with its own gain/solo and a nested device
/// list, then sums back to a single output.
class SplitDeviceSnapshot extends DeviceSnapshot {
  const SplitDeviceSnapshot({
    required super.id,
    required super.type,
    required super.bypassed,
    this.branch0Gain = 1,
    this.branch1Gain = 1,
    this.branch0Solo = false,
    this.branch1Solo = false,
    this.branch0 = const [],
    this.branch1 = const [],
  }) : super(
          gain: 1,
          pan: 0.5,
          meterGainReductionDb: 0,
          meterInputLevel: 0,
        );

  final double branch0Gain;
  final double branch1Gain;
  final bool branch0Solo;
  final bool branch1Solo;
  final List<DeviceSnapshot> branch0;
  final List<DeviceSnapshot> branch1;

  bool get isMidSide => type == 'ms_split';

  List<DeviceSnapshot> branchDevices(int branchIndex) =>
      branchIndex == 0 ? branch0 : branch1;

  factory SplitDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final p = map['parameters'] as Map<dynamic, dynamic>? ?? const {};
    final branches = map['branches'] as List? ?? const [];
    List<DeviceSnapshot> devicesForBranch(int index) {
      if (index >= branches.length) return const [];
      final branch = branches[index];
      if (branch is! Map) return const [];
      return parseDeviceList(branch, 'devices');
    }

    return SplitDeviceSnapshot(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'lr_split',
      bypassed: readBypass(map['bypass']),
      branch0Gain: (p['branch0Gain'] as num?)?.toDouble() ?? 1,
      branch1Gain: (p['branch1Gain'] as num?)?.toDouble() ?? 1,
      branch0Solo: readBypass(p['branch0Solo']),
      branch1Solo: readBypass(p['branch1Solo']),
      branch0: devicesForBranch(0),
      branch1: devicesForBranch(1),
    );
  }

  @override
  SplitDeviceSnapshot withParameter(String id, double value) => switch (id) {
        'branch0Gain' => copyWith(branch0Gain: value),
        'branch1Gain' => copyWith(branch1Gain: value),
        // Exclusive: enabling one solo clears the other. Neither = both paths out.
        'branch0Solo' => value >= 0.5
            ? copyWith(branch0Solo: true, branch1Solo: false)
            : copyWith(branch0Solo: false),
        'branch1Solo' => value >= 0.5
            ? copyWith(branch1Solo: true, branch0Solo: false)
            : copyWith(branch1Solo: false),
        'bypass' => copyWith(bypassed: value >= 0.5),
        _ => this,
      };

  @override
  SplitDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? branch0Gain,
    double? branch1Gain,
    bool? branch0Solo,
    bool? branch1Solo,
    List<DeviceSnapshot>? branch0,
    List<DeviceSnapshot>? branch1,
  }) =>
      SplitDeviceSnapshot(
        id: id ?? this.id,
        type: type ?? this.type,
        bypassed: bypassed ?? this.bypassed,
        branch0Gain: branch0Gain ?? this.branch0Gain,
        branch1Gain: branch1Gain ?? this.branch1Gain,
        branch0Solo: branch0Solo ?? this.branch0Solo,
        branch1Solo: branch1Solo ?? this.branch1Solo,
        branch0: branch0 ?? this.branch0,
        branch1: branch1 ?? this.branch1,
      );

  SplitDeviceSnapshot withBranchDevices(
    int branchIndex,
    List<DeviceSnapshot> devices,
  ) =>
      branchIndex == 0 ? copyWith(branch0: devices) : copyWith(branch1: devices);
}
