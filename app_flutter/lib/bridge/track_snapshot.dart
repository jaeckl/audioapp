part of 'project_snapshot.dart';

class TrackSnapshot {
  const TrackSnapshot({
    required this.id,
    required this.name,
    this.iconKey = '',
    this.isGroup = false,
    this.muted = false,
    this.soloed = false,
    this.parentGroupId = '',
    required this.devices,
    required this.midiClips,
    required this.sampleClips,
    this.automationClips = const [],
    this.freeze = const TrackFreezeSnapshot(),
  });

  final String id;
  final String name;
  final String iconKey;
  final bool isGroup;
  final bool muted;
  final bool soloed;
  final String parentGroupId;
  final List<DeviceSnapshot> devices;
  final List<MidiClipSnapshot> midiClips;
  final List<SampleClipSnapshot> sampleClips;

  /// Per-track view of automation clips whose `homeTrackId` matches this
  /// track's id. With the move to a global store, the per-track field is
  /// populated from `ProjectSnapshot.automationClips` for backward
  /// compatibility with code that iterates tracks. The clip's `deviceId`
  /// is independent — it can point at a device on any track.
  final List<AutomationClipSnapshot> automationClips;
  final TrackFreezeSnapshot freeze;

  TrackSnapshot copyWith({
    String? id,
    String? name,
    String? iconKey,
    bool? isGroup,
    bool? muted,
    bool? soloed,
    String? parentGroupId,
    List<DeviceSnapshot>? devices,
    List<MidiClipSnapshot>? midiClips,
    List<SampleClipSnapshot>? sampleClips,
    List<AutomationClipSnapshot>? automationClips,
    TrackFreezeSnapshot? freeze,
  }) {
    return TrackSnapshot(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      isGroup: isGroup ?? this.isGroup,
      muted: muted ?? this.muted,
      soloed: soloed ?? this.soloed,
      parentGroupId: parentGroupId ?? this.parentGroupId,
      devices: devices ?? this.devices,
      midiClips: midiClips ?? this.midiClips,
      sampleClips: sampleClips ?? this.sampleClips,
      automationClips: automationClips ?? this.automationClips,
      freeze: freeze ?? this.freeze,
    );
  }

  factory TrackSnapshot.fromMap(
    Map<dynamic, dynamic> map, {
    List<AutomationClipSnapshot> projectAutomationClips = const [],
  }) {
    final trackId = map['id'] as String? ?? '';
    final clipsRaw = map['midiClips'] as List<dynamic>? ?? [];
    final sampleClipsRaw = map['sampleClips'] as List<dynamic>? ?? [];
    final perTrackAutomation = map['automationClips'] as List<dynamic>? ?? [];
    // Project-global clips. The clip's homeTrackId is the layout choice —
    // the track lane it lives in. Unassigned clips (no target yet) are
    // still laid out on the home track the user picked at create time.
    final fromGlobal =
        projectAutomationClips.where((c) => c.homeTrackId == trackId).toList();
    return TrackSnapshot(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      iconKey: map['iconKey'] as String? ?? '',
      isGroup: map['isGroup'] as bool? ?? false,
      muted: map['muted'] as bool? ?? false,
      soloed: map['soloed'] as bool? ?? false,
      parentGroupId: map['parentGroupId'] as String? ?? '',
      devices: parseDeviceList(map, 'devices'),
      midiClips: clipsRaw
          .map((c) => MidiClipSnapshot.fromMap(c as Map<dynamic, dynamic>))
          .toList(),
      sampleClips: sampleClipsRaw
          .map((c) => SampleClipSnapshot.fromMap(c as Map<dynamic, dynamic>))
          .toList(),
      automationClips: perTrackAutomation.isNotEmpty
          ? perTrackAutomation
              .map((c) =>
                  AutomationClipSnapshot.fromMap(c as Map<dynamic, dynamic>))
              .toList()
          : fromGlobal,
      freeze: TrackFreezeSnapshot.fromMap(
        map['freeze'] as Map<dynamic, dynamic>?,
      ),
    );
  }
}
