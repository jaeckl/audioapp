import '../../bridge/project_snapshot.dart';

/// Returns the project-global modulators that belong in one device panel.
/// Legacy records without ownership remain reachable through their targets.
List<LfoSnapshot> modulatorsForDevicePanel({
  required List<LfoSnapshot> modulators,
  required List<ModulationEdgeSnapshot> edges,
  required String deviceId,
}) {
  final legacyTargetIds = edges
      .where((edge) => edge.deviceId == deviceId)
      .map((edge) => edge.lfoId)
      .toSet();
  return modulators
      .where((modulator) =>
          modulator.ownerDeviceId == deviceId ||
          (modulator.ownerDeviceId.isEmpty &&
              legacyTargetIds.contains(modulator.id)))
      .toList(growable: false);
}
