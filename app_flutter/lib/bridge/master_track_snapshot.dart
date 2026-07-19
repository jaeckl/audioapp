part of 'project_snapshot.dart';

class MasterTrackSnapshot {
  const MasterTrackSnapshot({
    required this.id,
    required this.name,
    required this.gain,
    this.muted = false,
    this.devices = const [],
    this.midiClips = const [],
    this.sampleClips = const [],
  });

  final String id;
  final String name;
  final double gain;
  final bool muted;
  final List<DeviceSnapshot> devices;
  final List<MidiClipSnapshot> midiClips;
  final List<SampleClipSnapshot> sampleClips;

  /// View master as a track for shared arrangement / strip widgets.
  TrackSnapshot asTrackSnapshot({
    List<AutomationClipSnapshot> projectAutomationClips = const [],
  }) {
    final fromGlobal =
        projectAutomationClips.where((c) => c.homeTrackId == id).toList();
    return TrackSnapshot(
      id: id,
      name: name,
      iconKey: 'speaker',
      muted: muted,
      devices: devices,
      midiClips: midiClips,
      sampleClips: sampleClips,
      automationClips: fromGlobal,
      outputTarget: 'device',
    );
  }

  factory MasterTrackSnapshot.fromMap(Map<dynamic, dynamic>? map) {
    final devicesRaw = map?['devices'] as List<dynamic>? ?? const [];
    final midiRaw = map?['midiClips'] as List<dynamic>? ?? const [];
    final sampleRaw = map?['sampleClips'] as List<dynamic>? ?? const [];
    return MasterTrackSnapshot(
      id: map?['id'] as String? ?? 'master',
      name: map?['name'] as String? ?? 'Master',
      gain: (map?['gain'] as num?)?.toDouble() ?? 1.0,
      muted: map?['muted'] as bool? ?? false,
      devices: devicesRaw
          .whereType<Map>()
          .map((e) => DeviceSnapshot.fromMap(Map<dynamic, dynamic>.from(e)))
          .toList(growable: false),
      midiClips: midiRaw
          .whereType<Map>()
          .map((e) => MidiClipSnapshot.fromMap(Map<dynamic, dynamic>.from(e)))
          .toList(growable: false),
      sampleClips: sampleRaw
          .whereType<Map>()
          .map((e) => SampleClipSnapshot.fromMap(Map<dynamic, dynamic>.from(e)))
          .toList(growable: false),
    );
  }
}
