import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bridge/live_meters_dto.dart';
import '../bridge/live_meters_store.dart';
import '../features/arrangement/arrangement_timeline_metrics.dart';
import 'daw_shell_nav.dart';
import 'daw_transport_controller.dart';
import '../bridge/engine_bridge.dart';
import '../bridge/project_snapshot.dart';
import '../bridge/transport_state.dart';
import '../bridge/snapshot_store.dart';
import '../features/automation/automation_editor_screen.dart';
import '../features/arrangement/arrangement_view.dart';
import '../features/arrangement/snap_grid_resolution.dart';
import '../features/clip_drag/sample_clip_drag_data.dart';
import '../features/editor/timeline_marker_layer.dart';
import '../features/content_library/library_catalog.dart';
import '../features/content_library/library_category.dart';
import '../features/content_library/library_fly_in_panel.dart';
import '../features/device_strip/device_strip.dart';
import '../features/device_strip/device_strip_device_kind.dart';
import '../features/device_strip/device_strip_theme.dart';
import '../features/device_strip/device_preset_store.dart';
import '../features/device_strip/subtractive_synth_editor_screen.dart';
import '../features/device_strip/subtractive_synth_presets.dart';
import '../features/mixer/mixer_view.dart';
import '../features/play/live_instrument_panel.dart';
import '../features/piano_roll/piano_roll_screen.dart';
import '../features/piano_roll/midi_lane_layout.dart';
import '../features/sample_library/sample_library_screen.dart';
import '../features/sample_editor/sample_editor_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/welcome/example_projects.dart';
import '../features/welcome/welcome_hub.dart';
import '../features/transport/transport_bar.dart';
import 'automation_recording_merge.dart';
import 'automation_recording_session.dart';
import 'midi_recording_merge.dart';
import 'recording_session_decision.dart';
import 'record_write_mode.dart';

enum _ShellTab { devices, keys, mixer, library, settings }

class _MidiRecordingPreviewNote {
  const _MidiRecordingPreviewNote({
    required this.pitch,
    required this.startBeat,
    required this.velocity,
  });

  final int pitch;
  final double startBeat;
  final double velocity;
}

class _PendingMidiRecordingTake {
  const _PendingMidiRecordingTake({
    required this.startBeat,
    required this.endBeat,
    required this.notes,
  });

  final double startBeat;
  final double endBeat;
  final List<MidiNoteSnapshot> notes;

  double get lengthBeats =>
      (endBeat - startBeat).clamp(0.25, 1024.0).toDouble();
}

const _demoSamples = <(String, String, String)>[
  ('demo_form_basic_e', 'Basic E', 'form_basic_e.wav'),
  ('demo_form_evolving_sines', 'Evolving Sines', 'form_evolving_sines.wav'),
  ('demo_form_vowel_sustain', 'Vowel Sustain', 'form_vowel_sustain.wav'),
  ('demo_form_lost_choir', 'Lost Choir', 'form_lost_choir.wav'),
  ('demo_form_metal_hollow', 'Metal Hollow', 'form_metal_hollow.wav'),
  ('demo_form_vox_riders', 'Vox Riders', 'form_vox_riders.wav'),
  ('demo_form_liquid_air', 'Liquid Air', 'form_liquid_air.wav'),
];

class DawShell extends StatefulWidget {
  const DawShell({
    super.key,
    required this.bridge,
    this.showWelcomeOnLaunch = false,
  });

  final EngineBridge bridge;
  final bool showWelcomeOnLaunch;

  @override
  State<DawShell> createState() => _DawShellState();
}

class _DawShellState extends State<DawShell> with TickerProviderStateMixin {
  late final DawTransportController _transport;
  late final SnapshotStore _store;
  late final LiveMetersStore _liveMeters;
  ProjectSnapshot? get _snapshot => _store.state;
  String? _saveStatus;
  String? _projectError;
  _ShellTab _tab = _ShellTab.devices;
  bool _libraryOpen = false;
  LibraryCategory _libraryCategory = LibraryCategory.audioClips;
  String? _librarySamplerDeviceId;
  String? _libraryDrumMachineId;
  int? _libraryDrumNote;
  String? _automationLinkClipId;
  String? _libraryWavetableDeviceId;
  String? _libraryPresetDeviceId;
  String? _libraryPresetDeviceType;
  final GlobalKey<LibraryFlyInPanelState> _libraryPanelKey = GlobalKey();
  final TimelineViewportScrollController _arrangementScrollController =
      TimelineViewportScrollController();
  double? _frozenArrangementPlayhead;
  StreamSubscription<LiveMetersBatch>? _meterSubscription;
  StreamSubscription<LiveMidiNoteEvent>? _midiNoteSubscription;
  Timer? _pendingWtPositionTimer;
  String? _pendingWtPositionDeviceId;
  double? _pendingWtPositionValue;
  bool _wtPositionSendInFlight = false;
  bool _bootstrapReady = false;
  List<RecentProjectEntry> _recentProjects = const [];
  bool _snapClipsEnabled = true;
  RecordWriteMode _recordWriteMode = RecordWriteMode.take;
  bool _metronomeEnabled = false;
  double _metronomeLevel = 0.65;
  int _countInBars = 1;
  SnapGridResolution _snapGridResolution = SnapGridResolution.adaptive;
  bool _snapGridTriplet = false;
  List<String> _meterSubscriptionIds = const [];
  String? _audioRecordingTrackId;
  String? _audioRecordingSampleId;
  String? _audioRecordingClipId;
  double _audioRecordingStartBeat = 0.0;
  double _audioRecordingInputLevel = 0.0;
  final List<AudioRecordingSession> _audioRecordingSessions = [];
  double? _lastAudioRecordingPlayhead;
  bool _audioRecordingRollBusy = false;
  String? _midiRecordingTrackId;
  String? _midiRecordingPreviewClipId;
  MidiClipSnapshot? _midiRecordingTargetClip;
  double _midiRecordingStartBeat = 0.0;
  final Map<int, _MidiRecordingPreviewNote> _midiRecordingOpenNotes = {};
  final List<MidiNoteSnapshot> _midiRecordingPreviewNotes = [];
  final List<_PendingMidiRecordingTake> _pendingMidiRecordingTakes = [];
  final AutomationRecordingSessionBuffer _automationRecording =
      AutomationRecordingSessionBuffer();
  final Map<String, String> _automationRecordingClipIds = {};
  final Map<String, AutomationClipSnapshot> _automationRecordingOriginalClips =
      {};
  final Map<String, double> _liveClipStartBeats = {};
  String? _highlightedClipId;
  Timer? _audioRecordingSnapshotTimer;

  bool get _audioRecordingActive => _audioRecordingTrackId != null;
  bool get _midiRecordingActive => _midiRecordingTrackId != null;
  bool get _automationRecordingActive => _automationRecording.isActive;
  bool get _anyRecordingActive =>
      _audioRecordingActive ||
      _midiRecordingActive ||
      _automationRecordingActive;
  double get _recordingStartBeat {
    if (_audioRecordingActive) return _audioRecordingStartBeat;
    if (_midiRecordingActive) return _midiRecordingStartBeat;
    if (_automationRecordingActive) return _automationRecording.startBeat;
    return 0.0;
  }

  String? get _recordingModeLabel {
    final modes = <String>[
      if (_audioRecordingActive) 'AUDIO',
      if (_midiRecordingActive) 'MIDI',
    ];
    return modes.isEmpty ? null : 'REC ${modes.join(' + ')}';
  }

  Map<String, List<MidiNoteSnapshot>> get _liveMidiPreviewNotes {
    final clipId = _midiRecordingPreviewClipId;
    if (clipId == null) return const {};
    final target = _midiRecordingTargetClip;
    if (target != null) {
      return {
        clipId: mergeMidiRecordingNotes(
          existingNotes: target.notes,
          recordedNotes:
              _currentMidiRecordingPreviewNotes(_effectivePlayheadBeats),
          targetClipStartBeat: target.startBeat,
          recordingStartBeat: _midiRecordingStartBeat,
          recordingEndBeat: _effectivePlayheadBeats,
          mode: _recordWriteMode == RecordWriteMode.take
              ? RecordWriteMode.replace
              : _recordWriteMode,
        ),
      };
    }
    return {
      clipId: _currentMidiRecordingPreviewNotes(_effectivePlayheadBeats),
    };
  }

  Map<String, List<MidiClipSnapshot>> get _liveMidiPreviewClips {
    final clipId = _midiRecordingPreviewClipId;
    final trackId = _midiRecordingTrackId;
    if (clipId == null || trackId == null || _midiRecordingTargetClip != null) {
      return const {};
    }
    final length =
        (_effectivePlayheadBeats - _midiRecordingStartBeat).clamp(0.25, 1024.0);
    return {
      trackId: [
        MidiClipSnapshot(
          id: clipId,
          startBeat: _midiRecordingStartBeat,
          lengthBeats: length.toDouble(),
          naturalLengthBeats: length.toDouble(),
          notes: _currentMidiRecordingPreviewNotes(_effectivePlayheadBeats),
        ),
      ],
    };
  }

  @override
  void initState() {
    super.initState();
    _store = SnapshotStore(widget.bridge)..addListener(_onStoreChanged);
    _liveMeters = LiveMetersStore();
    _transport = DawTransportController(
      bridge: widget.bridge,
      vsync: this,
    );
    _meterSubscription = widget.bridge.meterStream.listen(_onMetersBatch);
    _midiNoteSubscription = widget.bridge.noteEvents.listen(_onLiveMidiNote);
    _bootstrap();
  }

  @override
  void dispose() {
    _pendingWtPositionTimer?.cancel();
    _audioRecordingSnapshotTimer?.cancel();
    _store.removeListener(_onStoreChanged);
    _store.dispose();
    _liveMeters.dispose();
    _meterSubscription?.cancel();
    _midiNoteSubscription?.cancel();
    _transport.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
    if (_tab == _ShellTab.mixer) {
      unawaited(_updateMeterSubscriptions(const []));
    }
  }

  void _onMetersBatch(LiveMetersBatch batch) {
    if (!mounted) return;
    _liveMeters.applyBatch(batch);
  }

  Future<void> _updateMeterSubscriptions(List<String> deviceIds) async {
    if (_tab == _ShellTab.mixer) {
      deviceIds = [
        for (final track in _snapshot?.tracks ?? const <TrackSnapshot>[])
          if (track.trackGainDevice != null) track.trackGainDevice!.id,
      ];
    } else if (_tab != _ShellTab.devices) {
      deviceIds = const [];
    }
    if (listEquals(deviceIds, _meterSubscriptionIds)) return;
    _meterSubscriptionIds = deviceIds;
    try {
      await widget.bridge.setMeterSubscriptions(deviceIds);
    } catch (_) {}
  }

  double get _effectivePlayheadBeats {
    if (_frozenArrangementPlayhead != null) {
      return _frozenArrangementPlayhead!;
    }
    return _transport.effectivePlayheadBeats;
  }

  Future<double> _beginClipEditorSession() async {
    if (_transport.playing) {
      await _transport.stopPlay();
    }
    final saved = _effectivePlayheadBeats;
    if (mounted) {
      setState(() => _frozenArrangementPlayhead = saved);
    }
    return saved;
  }

  Future<void> _endClipEditorSession() async {
    if (mounted) {
      setState(() => _frozenArrangementPlayhead = null);
    }
    await _transport.syncTransportState();
  }

  Future<void> _bootstrap() async {
    try {
      await widget.bridge.ping();
      await _refreshRecentProjects();
      if (!widget.showWelcomeOnLaunch) {
        await _createNewProject();
      }
      if (!mounted) return;
      setState(() => _bootstrapReady = true);
      if (widget.showWelcomeOnLaunch) {
        await _presentWelcomeHub();
      }
    } on MissingPluginException {
      if (!mounted) return;
      setState(() => _projectError = 'Engine: native bridge unavailable');
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _refreshRecentProjects() async {
    try {
      final projects = await widget.bridge.getRecentProjects();
      if (mounted) setState(() => _recentProjects = projects);
    } catch (_) {}
  }

  /// Pushes the welcome/project-picker as a stacked full-screen route on top
  /// of the shell. It is not reachable from the bottom nav; it pops itself
  /// once a project becomes active (see [WelcomeHub]).
  Future<void> _presentWelcomeHub() async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => WelcomeHub(
          recentProjects: _recentProjects,
          hasActiveProject: () => _snapshot != null,
          onNewProject: _requestNewProject,
          onContinue: (_snapshot != null || _recentProjects.isNotEmpty)
              ? _continueProject
              : null,
          onOpenProject: _loadProject,
          onOpenRecent: _loadRecentProject,
          onOpenExample: _loadExampleProject,
        ),
      ),
    );
  }

  Future<void> _activateProject(ProjectSnapshot snapshot) async {
    snapshot = await _registerDemoSamples(snapshot);
    await widget.bridge.enterPlayMode();
    await _refreshSnapshot(snapshot);
    _transport.syncTransportAnchorFromSnapshot(
      snapshot.bpm,
      snapshot.loopEnabled,
      snapshot.loopRegionStartBeat,
      snapshot.loopRegionEndBeat,
      snapshot.playheadBeats,
    );
    if (!mounted) return;
    setState(() {
      _tab = _ShellTab.devices;
      _projectError = null;
    });
  }

  Future<ProjectSnapshot> _registerDemoSamples(ProjectSnapshot snapshot) async {
    try {
      var current = snapshot;
      for (final (id, name, file) in _demoSamples) {
        final data = await rootBundle.load('assets/demo_samples/$file');
        current = await widget.bridge.registerDemoSample(
          id: id,
          name: name,
          bytes:
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }
      return current;
    } on MissingPluginException {
      return snapshot;
    } catch (_) {
      return snapshot;
    }
  }

  Future<void> _createNewProject() async {
    try {
      await widget.bridge.createProject();
      final snapshot = await widget.bridge.addTrack(name: 'Track 1');
      await _activateProject(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _requestNewProject() async {
    if (_snapshot == null) {
      await _createNewProject();
      return;
    }
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create a new project?'),
        content: const Text(
          'Unsaved changes in the current project will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('New Project'),
          ),
        ],
      ),
    );
    if (replace == true) await _createNewProject();
  }

  Future<void> _continueProject() async {
    if (_snapshot != null) {
      setState(() => _tab = _ShellTab.devices);
      return;
    }
    if (_recentProjects.isNotEmpty) {
      await _loadRecentProject(_recentProjects.first);
    }
  }

  Future<void> _loadRecentProject(RecentProjectEntry project) async {
    try {
      final snapshot = await widget.bridge.loadRecentProject(project.uri);
      await _activateProject(snapshot);
      await _refreshRecentProjects();
      if (mounted) setState(() => _saveStatus = 'Loaded ${project.name}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _loadExampleProject(ExampleProject example) async {
    try {
      final projectJson = await rootBundle.loadString(example.assetPath);
      final snapshot = await widget.bridge.loadExampleProject(projectJson);
      await _activateProject(snapshot);
      if (mounted) setState(() => _saveStatus = 'Loaded ${example.name}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _refreshSnapshot(ProjectSnapshot snapshot) async {
    _store.replaceSnapshot(snapshot);
  }

  /// Call a mutation via [invokeRaw], merge the delta into store.
  Future<void> _applyDeltaMutation(
    String method, [
    Map<String, dynamic>? args,
  ]) async {
    await _store.invokeRaw(method, args);
  }

  Future<void> _addTrack() async {
    try {
      final snapshot = await widget.bridge.addTrack();
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _addGroupTrack() async {
    try {
      final snapshot = await widget.bridge.addGroupTrack();
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setTrackGroup(String trackId, String? groupTrackId) async {
    try {
      final snapshot = await widget.bridge.setTrackGroup(
        trackId: trackId,
        groupTrackId: groupTrackId ?? '',
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _moveTrack({
    required String trackId,
    required String parentGroupId,
    required String beforeTrackId,
  }) async {
    try {
      final snapshot = await widget.bridge.moveTrack(
        trackId: trackId,
        parentGroupId: parentGroupId,
        beforeTrackId: beforeTrackId,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setTrackMuted({
    required String trackId,
    required bool muted,
  }) async {
    _store.replaceSnapshot(
      _snapshot!.withTrackMix(trackId: trackId, muted: muted),
    );
    try {
      final snapshot = await widget.bridge.setTrackMuted(
        trackId: trackId,
        muted: muted,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setTrackSoloed({
    required String trackId,
    required bool soloed,
  }) async {
    _store.replaceSnapshot(
      _snapshot!.withTrackMix(trackId: trackId, soloed: soloed),
    );
    try {
      final snapshot = await widget.bridge.setTrackSoloed(
        trackId: trackId,
        soloed: soloed,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _toggleTrackFreeze({
    required String trackId,
    required bool enabled,
    required bool stale,
  }) async {
    final wasPlaying = _snapshot?.playing ?? false;
    if (wasPlaying) {
      await widget.bridge.stop();
    }
    try {
      final ProjectSnapshot snapshot;
      if (enabled && stale) {
        snapshot = await widget.bridge.refreshTrackFreeze(trackId);
      } else if (enabled) {
        snapshot = await widget.bridge.unfreezeTrack(trackId);
      } else {
        snapshot = await widget.bridge.freezeTrack(trackId);
      }
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    } finally {
      if (wasPlaying && mounted) {
        await widget.bridge.play();
      }
    }
  }

  bool _trackFrozen(String trackId) {
    return _trackById(trackId)?.freeze.enabled ?? false;
  }

  void _showFrozenTrackSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unfreeze track to add clips')),
    );
  }

  Future<void> _selectTrack(String trackId) async {
    try {
      await _applyDeltaMutation('selectTrack', {'trackId': trackId});
      await _syncArmWithSelection();
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _syncArmWithSelection() async {
    final snap = _snapshot;
    if (snap == null) return;
    final track = _trackById(snap.selectedTrackId);
    final hasTrack = snap.selectedTrackId.isNotEmpty;
    final frozen = track?.freeze.enabled ?? false;
    if (_tab == _ShellTab.keys && hasTrack && !snap.recordArmed && !frozen) {
      await _store.invokeRaw('setRecordArmed', {'armed': true});
    } else if ((_tab == _ShellTab.devices || frozen) && snap.recordArmed) {
      await _store.invokeRaw('setRecordArmed', {'armed': false});
    }
  }

  Future<void> _syncLiveInputForTab(_ShellTab tab) async {
    try {
      if (tab == _ShellTab.keys) {
        await widget.bridge.enterPlayMode();
        if (_snapshot != null) {
          await _syncArmWithSelection();
        }
      } else {
        await widget.bridge.allNotesOff();
        if (_snapshot?.recordArmed == true) {
          await _store.invokeRaw('setRecordArmed', {'armed': false});
        }
      }
    } catch (_) {}
  }

  Future<void> _setRecordArmed(bool armed) async {
    try {
      if (armed) {
        await widget.bridge.ensureRecordAudioPermission();
      }
      await _store.invokeRaw('setRecordArmed', {'armed': armed});
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  void _setRecordWriteMode(RecordWriteMode mode) {
    if (_recordWriteMode == mode) return;
    setState(() => _recordWriteMode = mode);
  }

  Future<void> _setTrackRecordArmed({
    required String trackId,
    required bool armed,
  }) async {
    try {
      if (armed) {
        await widget.bridge.ensureRecordAudioPermission();
      }
      if (_snapshot?.selectedTrackId != trackId) {
        await _applyDeltaMutation('selectTrack', {'trackId': trackId});
      }
      await _store.invokeRaw('setRecordArmed', {'armed': armed});
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _addMidiClip(String trackId, double startBeat) async {
    if (_trackFrozen(trackId)) {
      _showFrozenTrackSnack();
      return;
    }
    try {
      await widget.bridge.selectTrack(trackId);
      final before = _trackById(trackId);
      final beforeClipCount = before?.midiClips.length ?? 0;
      var snapshot = await widget.bridge.createMidiClip(
        trackId: trackId,
        startBeat: startBeat,
      );
      final track = snapshot.tracks.firstWhere((t) => t.id == trackId);
      if (track.midiClips.length <= beforeClipCount) return;
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  TrackSnapshot? _trackById(String trackId) {
    for (final track in _snapshot?.tracks ?? const <TrackSnapshot>[]) {
      if (track.id == trackId) {
        return track;
      }
    }
    return null;
  }

  Future<void> _addAutomationClip(
    String trackId,
    double startBeat, {
    String? deviceId,
    String? paramId,
  }) async {
    if (_trackFrozen(trackId)) {
      _showFrozenTrackSnack();
      return;
    }
    try {
      await widget.bridge.selectTrack(trackId);
      final beforeIds =
          _snapshot?.automationClips.map((c) => c.id).toSet() ?? <String>{};
      var snapshot = await widget.bridge.createAutomationClip(
        trackId: trackId,
        startBeat: startBeat,
      );
      // Automation clips are project-global; the new one is the last entry
      // in the top-level array (regardless of which track it ended up on).
      final newClips = snapshot.automationClips
          .where((c) => !beforeIds.contains(c.id))
          .toList();
      if (newClips.isEmpty) {
        await _refreshSnapshot(snapshot);
        return;
      }
      final created = newClips.last;
      if (deviceId != null && paramId != null) {
        snapshot = await widget.bridge.assignAutomationTarget(
          clipId: created.id,
          deviceId: deviceId,
          paramId: paramId,
        );
      }
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  void _toggleAutomationLink(String clipId) {
    setState(() {
      _automationLinkClipId = _automationLinkClipId == clipId ? null : clipId;
    });
  }

  Future<bool> _assignAutomationParam(String deviceId, String paramId) async {
    final clipId = _automationLinkClipId;
    final snapshot = _snapshot;
    if (clipId == null || snapshot == null) {
      return false;
    }

    if (snapshot.deviceById(deviceId) == null) {
      return false;
    }
    if (snapshot.automationClipById(clipId) == null) {
      return false;
    }

    try {
      final updated = await widget.bridge.assignAutomationTarget(
        clipId: clipId,
        deviceId: deviceId,
        paramId: paramId,
      );
      if (!mounted) return false;
      setState(() => _automationLinkClipId = null);
      await _refreshSnapshot(updated);
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() => _projectError = e.toString());
      return false;
    }
  }

  double _automationValueForDevice(DeviceSnapshot device, String paramId) {
    return switch (paramId) {
      'gain' => device.gain.clamp(0.0, 1.0),
      'pan' => device.pan.clamp(0.0, 1.0),
      'filterCutoff' => (switch (device) {
          SubtractiveSynthDeviceSnapshot d => d.filterCutoff,
          PhaseModSynthDeviceSnapshot d => d.filterCutoff,
          SamplerDeviceSnapshot d => d.filterCutoff,
          BassSynthDeviceSnapshot d => d.filterCutoff,
          _ => 1.0,
        })
            .clamp(0.0, 1.0),
      'filterQ' => (switch (device) {
          SubtractiveSynthDeviceSnapshot d => d.filterQ,
          PhaseModSynthDeviceSnapshot d => d.filterQ,
          SamplerDeviceSnapshot d => d.filterQ,
          _ => 0.5,
        })
            .clamp(0.0, 1.0),
      'attack' => (switch (device) {
          SubtractiveSynthDeviceSnapshot d => d.attack,
          PhaseModSynthDeviceSnapshot d => d.attack,
          SamplerDeviceSnapshot d => d.attack,
          BassSynthDeviceSnapshot d => d.attack,
          _ => 0.01,
        })
            .clamp(0.0, 1.0),
      'decay' => (switch (device) {
          SubtractiveSynthDeviceSnapshot d => d.decay,
          PhaseModSynthDeviceSnapshot d => d.decay,
          SamplerDeviceSnapshot d => d.decay,
          _ => 0.3,
        })
            .clamp(0.0, 1.0),
      'sustain' => (switch (device) {
          SubtractiveSynthDeviceSnapshot d => d.sustain,
          PhaseModSynthDeviceSnapshot d => d.sustain,
          SamplerDeviceSnapshot d => d.sustain,
          BassSynthDeviceSnapshot d => d.sustain,
          _ => 0.7,
        })
            .clamp(0.0, 1.0),
      'release' => (switch (device) {
          SubtractiveSynthDeviceSnapshot d => d.release,
          PhaseModSynthDeviceSnapshot d => d.release,
          SamplerDeviceSnapshot d => d.release,
          BassSynthDeviceSnapshot d => d.release,
          _ => 0.4,
        })
            .clamp(0.0, 1.0),
      'frequency' => (switch (device) {
          OscillatorDeviceSnapshot d => ((d.frequencyHz - 110.0) / 770.0),
          _ => 0.5,
        })
            .clamp(0.0, 1.0),
      _ => 0.5,
    };
  }

  Future<void> _automateParameter(String deviceId, String paramId) async {
    final linkedClips = _snapshot?.automationClips
            .where(
                (clip) => clip.deviceId == deviceId && clip.paramId == paramId)
            .toList() ??
        const <AutomationClipSnapshot>[];
    if (linkedClips.isNotEmpty) {
      try {
        ProjectSnapshot? updated;
        for (final clip in linkedClips) {
          updated = await widget.bridge.unlinkAutomationTarget(clipId: clip.id);
        }
        if (updated != null) await _refreshSnapshot(updated);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Automation unlinked from ${AutomationClipSnapshot.linkLabelForParam(paramId)}',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _projectError = e.toString());
      }
      return;
    }

    final track = _snapshot?.selectedTrack;
    if (track == null) return;

    DeviceSnapshot? device;
    for (final candidate in track.devices) {
      if (candidate.id == deviceId) {
        device = candidate;
        break;
      }
    }
    if (device == null) return;

    const lengthBeats = ArrangementTimelineMetrics.defaultMidiClipLengthBeats;
    final startBeat = ArrangementTimelineMetrics.placementStartBeat(
      desiredStartBeat: _effectivePlayheadBeats,
      clipLengthBeats: lengthBeats,
      existingClips: ArrangementTimelineMetrics.clipIntervalsForTrack(track),
    );
    final value = _automationValueForDevice(device, paramId);

    try {
      await widget.bridge.selectTrack(track.id);
      final beforeIds =
          _snapshot?.automationClips.map((c) => c.id).toSet() ?? <String>{};
      var snapshot = await widget.bridge.createAutomationClip(
        trackId: track.id,
        startBeat: startBeat,
        lengthBeats: lengthBeats,
      );
      final newClips = snapshot.automationClips
          .where((c) => !beforeIds.contains(c.id))
          .toList();
      if (newClips.isEmpty) {
        await _refreshSnapshot(snapshot);
        return;
      }
      final created = newClips.last;
      snapshot = await widget.bridge.assignAutomationTarget(
        clipId: created.id,
        deviceId: deviceId,
        paramId: paramId,
      );
      snapshot = await widget.bridge.setAutomationPoints(
        clipId: created.id,
        points: [
          AutomationPointSnapshot(beat: 0, value: value),
          AutomationPointSnapshot(beat: lengthBeats, value: value),
        ],
      );
      await _refreshSnapshot(snapshot);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Automation clip for ${AutomationClipSnapshot.linkLabelForParam(paramId)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _openAutomationCurveEditor(
    String trackId,
    AutomationClipSnapshot clip,
  ) async {
    final track = _trackById(trackId);
    if (track == null) return;

    // Always open with engine-backed points (arrangement [clip] may be stale).
    AutomationClipSnapshot editorClip = clip;
    try {
      final fresh = await widget.bridge.getProjectSnapshot();
      for (final candidate in fresh.automationClips) {
        if (candidate.id == clip.id) {
          editorClip = candidate;
          break;
        }
      }
    } catch (_) {
      // Fall back to the clip snapshot we already have.
    }

    if (!mounted) return;
    final savedPlayhead = await _beginClipEditorSession();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AutomationEditorScreen(
          trackName: track.name,
          clip: editorClip,
          bridge: widget.bridge,
          onSaved: _refreshSnapshot,
          savedArrangementPlayhead: savedPlayhead,
          bpm: _snapshot?.bpm ?? 120,
        ),
      ),
    );
    await _endClipEditorSession();
  }

  Future<void> _addAudioClip(String trackId, double desiredStartBeat) async {
    await _selectTrack(trackId);
    if (!mounted) return;

    final sample = await showModalBottomSheet<SampleLibraryEntrySnapshot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E0E14),
      showDragHandle: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: SampleLibraryPickerSheet(
          initialSamples: _snapshot?.samples ?? const [],
          onPreview: _previewSample,
          onImportSamples: () async {
            final updated = await widget.bridge.importSample();
            if (updated != null) {
              await _refreshSnapshot(updated);
              return updated.samples;
            }
            return _snapshot?.samples ?? const [];
          },
          onSampleSelected: (entry) => Navigator.pop(context, entry),
        ),
      ),
    );
    if (sample == null) return;

    final track = _trackById(trackId);
    if (track == null) return;
    if (track.freeze.enabled) {
      _showFrozenTrackSnack();
      return;
    }

    final startBeat = ArrangementTimelineMetrics.placementStartBeat(
      desiredStartBeat: desiredStartBeat,
      clipLengthBeats: sample.durationBeats,
      existingClips: ArrangementTimelineMetrics.clipIntervalsForTrack(track),
    );

    try {
      final updated = await widget.bridge.createSampleClip(
        trackId: trackId,
        sampleId: sample.id,
        startBeat: startBeat,
        lengthBeats: sample.durationBeats,
      );
      await _refreshSnapshot(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  void _optimisticParamUpdate(
      String deviceId, String parameterId, double value) {
    _store.replaceSnapshot(
        _snapshot!.withDeviceParam(deviceId, parameterId, value));
  }

  TrackSnapshot? _trackOwningDevice(String deviceId) {
    final snapshot = _snapshot;
    if (snapshot == null) return null;
    bool containsDevice(Iterable<DeviceSnapshot> devices) {
      for (final device in devices) {
        if (device.id == deviceId) return true;
        if (device is ChainDeviceSnapshot && containsDevice(device.devices)) {
          return true;
        }
        if (device is DrumMachineDeviceSnapshot) {
          for (final pad in device.pads) {
            if (containsDevice(pad.devices)) return true;
          }
        }
      }
      return false;
    }

    for (final track in snapshot.tracks) {
      if (containsDevice(track.devices)) return track;
    }
    return null;
  }

  void _captureAutomationForDeviceParam(
    String deviceId,
    String parameterId,
    double value,
  ) {
    final track = _trackOwningDevice(deviceId);
    if (track == null) return;
    _recordAutomationPoint(track.id, deviceId, parameterId, value);
  }

  Future<void> _setSamplerParameter(
      String deviceId, String parameterId, double value) async {
    _optimisticParamUpdate(deviceId, parameterId, value);
    _captureAutomationForDeviceParam(deviceId, parameterId, value);

    // Wavetable position can emit dozens/hundreds of drag updates per second.
    // Coalesce those MethodChannel calls so the control thread does not keep
    // touching native playback state faster than the audio callback can consume it.
    if (parameterId == 'wtPosition') {
      _queueWtPositionParameter(deviceId, value);
      return;
    }

    try {
      await widget.bridge.setDeviceParameter(
        deviceId: deviceId,
        parameterId: parameterId,
        value: value,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  void _queueWtPositionParameter(String deviceId, double value) {
    _pendingWtPositionDeviceId = deviceId;
    _pendingWtPositionValue = value.clamp(0.0, 1.0).toDouble();
    _pendingWtPositionTimer ??= Timer(
      const Duration(milliseconds: 16),
      _flushQueuedWtPositionParameter,
    );
  }

  Future<void> _flushQueuedWtPositionParameter() async {
    _pendingWtPositionTimer = null;
    if (_wtPositionSendInFlight) {
      _pendingWtPositionTimer = Timer(
        const Duration(milliseconds: 16),
        _flushQueuedWtPositionParameter,
      );
      return;
    }

    final deviceId = _pendingWtPositionDeviceId;
    final value = _pendingWtPositionValue;
    _pendingWtPositionDeviceId = null;
    _pendingWtPositionValue = null;
    if (deviceId == null || value == null) return;

    _wtPositionSendInFlight = true;
    try {
      await widget.bridge.setDeviceParameter(
        deviceId: deviceId,
        parameterId: 'wtPosition',
        value: value,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _projectError = e.toString());
      }
    } finally {
      _wtPositionSendInFlight = false;
      if (mounted &&
          _pendingWtPositionDeviceId != null &&
          _pendingWtPositionTimer == null) {
        _pendingWtPositionTimer = Timer(
          const Duration(milliseconds: 16),
          _flushQueuedWtPositionParameter,
        );
      }
    }
  }

  Future<void> _setDeviceBypass(String deviceId, bool bypassed) async {
    await _setSamplerParameter(deviceId, 'bypass', bypassed ? 1.0 : 0.0);
  }

  Future<ProjectSnapshot> _modulationBridgeCall(
    String method,
    Map<String, dynamic> args,
  ) async {
    try {
      switch (method) {
        case 'updateLfoParam':
        case 'batchUpdateLfoParams':
          await _store.invokeRaw(method, args);
          return _snapshot!;
        default:
          await _store.invokeRaw(method, args);
          return _snapshot!;
      }
    } catch (e) {
      if (!mounted) {
        return _snapshot ??
            const ProjectSnapshot(
              bpm: 120,
              selectedTrackId: '',
              playheadBeats: 0,
              playing: false,
              loopEnabled: true,
              recordArmed: false,
              master:
                  MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1.0),
              samples: [],
              tracks: [],
              lfos: [],
              modEdges: [],
            );
      }
      rethrow;
    }
  }

  Future<void> _openDeviceLibrary(DeviceSnapshot device) async {
    setState(() {
      _libraryOpen = true;
      _libraryCategory = LibraryCategory.devicePresets;
      _libraryPresetDeviceId = device.id;
      _libraryPresetDeviceType = device.type;
      _librarySamplerDeviceId = device.type == 'simple_sampler' ||
              device.type == 'granular_formant_synth'
          ? device.id
          : null;
      _libraryWavetableDeviceId = null;
    });
  }

  void _openDrumPadLibrary(DrumMachineDeviceSnapshot device, int note) {
    setState(() {
      _libraryOpen = true;
      _libraryCategory = LibraryCategory.audioClips;
      _librarySamplerDeviceId = null;
      _libraryDrumMachineId = device.id;
      _libraryDrumNote = note;
    });
  }

  void _closeLibrary() {
    setState(() {
      _libraryOpen = false;
      _librarySamplerDeviceId = null;
      _libraryWavetableDeviceId = null;
      _libraryDrumMachineId = null;
      _libraryDrumNote = null;
      _libraryPresetDeviceId = null;
      _libraryPresetDeviceType = null;
    });
    // Stop any active preview (preset/midi/sampler) so closing the library
    // also halts the audio and the visual playhead ticker — not just the
    // panel UI.
    widget.bridge.stopPreview().catchError((Object _) {});
  }

  Future<void> _openLibrary(
      {LibraryCategory category = LibraryCategory.audioClips}) async {
    setState(() {
      _libraryOpen = true;
      _libraryCategory = category;
      _librarySamplerDeviceId = null;
    });
  }

  Future<void> _onLibraryInsertAudio(SampleLibraryEntrySnapshot sample) async {
    final drumMachineId = _libraryDrumMachineId;
    final drumNote = _libraryDrumNote;
    if (drumMachineId != null && drumNote != null) {
      final updated = await widget.bridge.addDeviceToDrumPad(
        drumMachineId: drumMachineId,
        note: drumNote,
        deviceType: 'simple_sampler',
        padName: sample.name,
      );
      final machine = updated.deviceById(drumMachineId);
      if (machine is DrumMachineDeviceSnapshot) {
        final samplers = machine
            .padForNote(drumNote)
            .devices
            .whereType<SamplerDeviceSnapshot>()
            .toList();
        if (samplers.isNotEmpty) {
          await _refreshSnapshot(updated);
          await _assignSamplerSample(samplers.last.id, sample.id);
        }
      }
      await _libraryPanelKey.currentState?.close();
      return;
    }
    final deviceId = _librarySamplerDeviceId;
    if (deviceId != null) {
      await _assignSamplerSample(deviceId, sample.id);
      await _libraryPanelKey.currentState?.close();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${sample.name}')),
        );
      }
      return;
    }
    await _insertSample(sample);
  }

  Future<void> _onLibraryMidiTap(LibraryMidiItem item) async {
    if (item.isFactory) {
      final track = _snapshot?.selectedTrack;
      if (track == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a track first')),
        );
        return;
      }
      if (track.freeze.enabled) {
        _showFrozenTrackSnack();
        return;
      }
      final startBeat = ArrangementTimelineMetrics.placementStartBeat(
        desiredStartBeat: _effectivePlayheadBeats,
        clipLengthBeats: item.clip.lengthBeats,
        existingClips: ArrangementTimelineMetrics.clipIntervalsForTrack(track),
      );
      try {
        await widget.bridge.selectTrack(track.id);
        final beforeClipCount = track.midiClips.length;
        var snapshot = await widget.bridge.createMidiClip(
          trackId: track.id,
          startBeat: startBeat,
          lengthBeats: item.clip.lengthBeats,
        );
        final updatedTrack =
            snapshot.tracks.firstWhere((t) => t.id == track.id);
        if (updatedTrack.midiClips.length > beforeClipCount) {
          final clip = updatedTrack.midiClips.last;
          snapshot = await widget.bridge.setMidiClipNotes(
            clipId: clip.id,
            notes: item.clip.notes,
          );
        }
        await _refreshSnapshot(snapshot);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inserted "${item.title}"')),
        );
        await _libraryPanelKey.currentState?.close();
      } catch (e) {
        if (!mounted) return;
        setState(() => _projectError = e.toString());
      }
      return;
    }
    if (item.trackId == null) {
      return;
    }
    await _openPianoRoll(item.trackId!, item.clip);
    await _libraryPanelKey.currentState?.close();
  }

  Future<void> _onLibraryMidiPreviewTap(LibraryMidiItem item) async {
    final bpm = _snapshot?.bpm ?? 120;
    try {
      await widget.bridge.previewMidi(
        notes: item.clip.notes,
        lengthBeats: item.clip.lengthBeats,
        bpm: bpm,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _onLibraryAutomationPreviewTap(
      LibraryAutomationItem item) async {
    // Automation has no audio preview — no-op.
  }

  Future<void> _onLibraryAutomationTap(LibraryAutomationItem item) async {
    final track = _snapshot?.selectedTrack;
    if (track == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a track first')),
      );
      return;
    }

    if (item.trackId != null && item.clip != null) {
      await _openAutomationCurveEditor(item.trackId!, item.clip!);
      await _libraryPanelKey.currentState?.close();
      return;
    }

    final startBeat = ArrangementTimelineMetrics.placementStartBeat(
      desiredStartBeat: _effectivePlayheadBeats,
      clipLengthBeats: ArrangementTimelineMetrics.defaultMidiClipLengthBeats,
      existingClips: ArrangementTimelineMetrics.clipIntervalsForTrack(track),
    );

    String? deviceId;
    String? paramId;
    if (item.suggestedParamId != null) {
      final synth = track.subtractiveSynthDevice ?? track.samplerDevice;
      if (synth != null) {
        deviceId = synth.id;
        paramId = item.suggestedParamId;
      }
    }

    await _addAutomationClip(
      track.id,
      startBeat,
      deviceId: deviceId,
      paramId: paramId,
    );
    await _libraryPanelKey.currentState?.close();
  }

  Future<void> _onLibraryPresetTap(LibraryPresetItem item) async {
    final presetTarget = _libraryPresetDeviceId;
    if (item.isUser && item.presetJson != null && presetTarget != null) {
      try {
        final updated = await widget.bridge.applyDevicePreset(
          deviceId: presetTarget,
          presetJson: item.presetJson!,
        );
        await _refreshSnapshot(updated);
        await _libraryPanelKey.currentState?.close();
      } catch (e) {
        if (mounted) setState(() => _projectError = e.toString());
      }
      return;
    }
    if (presetTarget != null && item.deviceType != 'subtractive_synth') {
      final preset = DevicePresetStore.find(item.deviceType, item.id);
      if (preset == null) return;
      for (final entry in preset.params.entries) {
        await widget.bridge.setDeviceParameter(
          deviceId: presetTarget,
          parameterId: entry.key,
          value: entry.value,
        );
      }
      for (final entry in preset.stringParams.entries) {
        await widget.bridge.setDeviceStringParameter(
          deviceId: presetTarget,
          parameterId: entry.key,
          value: entry.value,
        );
      }
      await _refreshSnapshot(await widget.bridge.getProjectSnapshot());
      await _libraryPanelKey.currentState?.close();
      return;
    }
    final drumMachineId = _libraryDrumMachineId;
    final drumNote = _libraryDrumNote;
    if (drumMachineId != null && drumNote != null) {
      const allowed = {
        'simple_sampler',
        'kick_generator',
        'snare_generator',
        'clap_generator',
        'cymbal_generator',
        'crash_generator',
      };
      if (!allowed.contains(item.deviceType)) return;
      final updated = await widget.bridge.addDeviceToDrumPad(
        drumMachineId: drumMachineId,
        note: drumNote,
        deviceType: item.deviceType,
        padName: item.title,
      );
      final machine = updated.deviceById(drumMachineId);
      final children = machine is DrumMachineDeviceSnapshot
          ? machine.padForNote(drumNote).devices
          : const <DeviceSnapshot>[];
      if (children.isNotEmpty) {
        final child = children.last;
        final preset = DevicePresetStore.find(item.deviceType, item.id);
        if (preset != null) {
          for (final entry in preset.params.entries) {
            await widget.bridge.setDeviceParameter(
              deviceId: child.id,
              parameterId: entry.key,
              value: entry.value,
            );
          }
          for (final entry in preset.stringParams.entries) {
            await widget.bridge.setDeviceStringParameter(
              deviceId: child.id,
              parameterId: entry.key,
              value: entry.value,
            );
          }
        }
      }
      await _refreshSnapshot(await widget.bridge.getProjectSnapshot());
      await _libraryPanelKey.currentState?.close();
      return;
    }
    final track = _snapshot?.selectedTrack;
    if (track == null) return;

    var synth = track.subtractiveSynthDevice;
    if (item.deviceType == 'subtractive_synth') {
      if (synth == null) {
        // Automatically add a Subtractive Synth device to the track on insert
        try {
          final snapshot = await widget.bridge.addDeviceToTrack(
            trackId: track.id,
            deviceType: 'subtractive_synth',
          );
          // Find the newly added subtractive synth device
          final updatedTrack =
              snapshot.tracks.firstWhere((t) => t.id == track.id);
          synth = updatedTrack.subtractiveSynthDevice;
          await _refreshSnapshot(snapshot);
        } catch (e) {
          if (!mounted) return;
          setState(() => _projectError = e.toString());
          return;
        }
      }

      if (synth == null) return;

      final preset = SubtractiveSynthPresets.presets[item.id];
      if (preset == null) return;

      try {
        final snapshot = await widget.bridge.applySubtractiveSynthPreset(
          deviceId: synth.id,
          params: preset.params,
          lfos: preset.lfos.map((l) => l.toJson()).toList(),
          mods: preset.mods.map((m) => m.toJson()).toList(),
        );
        await _refreshSnapshot(snapshot);
      } catch (e) {
        if (!mounted) return;
        setState(() => _projectError = e.toString());
        return;
      }

      if (!mounted) return;
      await _libraryPanelKey.currentState?.close();
      return;
    }
  }

  Future<void> _onLibraryPresetPreviewTap(LibraryPresetItem item,
      {double startBeat = 0.0, bool loop = true}) async {
    final preset = DevicePresetStore.find(item.deviceType, item.id);
    debugPrint(
        '[library preset] item.id=${item.id} deviceType=${item.deviceType} startBeat=$startBeat loop=$loop presetFound=${preset != null}');
    if (preset == null) {
      return;
    }

    // Gather selected track's MIDI clip notes in timeline coordinates
    final track = _snapshot?.selectedTrack;
    final notes = <MidiNoteSnapshot>[];
    double maxBeat = 8.0;

    if (track != null) {
      for (final clip in track.midiClips) {
        final clipEnd = clip.startBeat + clip.lengthBeats;
        if (clipEnd > maxBeat) {
          maxBeat = clipEnd;
        }
        for (final note in clip.notes) {
          notes.add(MidiNoteSnapshot(
            pitch: note.pitch,
            startBeat: clip.startBeat + note.startBeat,
            durationBeats: note.durationBeats,
            velocity: note.velocity,
          ));
        }
      }
    }

    // Fallback C arpeggio pattern if there are no notes on the selected track
    if (notes.isEmpty) {
      notes.add(const MidiNoteSnapshot(
          pitch: 48, startBeat: 0.0, durationBeats: 1.0, velocity: 90.0));
      notes.add(const MidiNoteSnapshot(
          pitch: 52, startBeat: 1.0, durationBeats: 1.0, velocity: 90.0));
      notes.add(const MidiNoteSnapshot(
          pitch: 55, startBeat: 2.0, durationBeats: 1.0, velocity: 90.0));
      notes.add(const MidiNoteSnapshot(
          pitch: 60, startBeat: 3.0, durationBeats: 1.0, velocity: 90.0));
      maxBeat = 4.0;
    }

    // Preview preset virtually via bridge. The preset's own deviceType is forwarded as-is;
    // the engine's DeviceRegistry builds the matching virtual slot.
    final bpm = _snapshot?.bpm ?? 120;
    try {
      await widget.bridge.previewPreset(
        deviceType: item.deviceType,
        params: preset.params,
        notes: notes,
        lengthBeats: maxBeat,
        bpm: bpm,
        startBeat: startBeat,
        loop: loop,
      );
    } catch (e) {
      debugPrint('[library preset] previewPreset FAILED for ${item.id}: $e');
    }
  }

  Future<void> _assignSamplerSample(String deviceId, String sampleId) async {
    try {
      await widget.bridge.setDeviceStringParameter(
        deviceId: deviceId,
        parameterId: 'sampleId',
        value: sampleId,
      );
      await _refreshSnapshot(await widget.bridge.getProjectSnapshot());
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _createSamplerFromDroppedSample(
    TrackSnapshot track,
    SampleClipDragData sample,
    int insertIndex,
  ) async {
    try {
      final beforeIds = track.devices.map((device) => device.id).toSet();
      final snapshot = await widget.bridge.addDeviceToTrack(
        trackId: track.id,
        deviceType: 'simple_sampler',
        insertIndex: insertIndex,
      );
      final updatedTrack = snapshot.tracks.firstWhere((t) => t.id == track.id);
      SamplerDeviceSnapshot? sampler;
      for (final device in updatedTrack.devices) {
        if (device is SamplerDeviceSnapshot && !beforeIds.contains(device.id)) {
          sampler = device;
          break;
        }
      }
      await _refreshSnapshot(snapshot);
      if (sampler == null) return;
      await _setDeviceStringParameter(sampler.id, 'sampleId', sample.sampleId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _assignDroppedSampleToDevice(
    DeviceSnapshot device,
    SampleClipDragData sample,
  ) async {
    if (device is! SamplerDeviceSnapshot && device is! GranularDeviceSnapshot) {
      return;
    }
    await _setDeviceStringParameter(device.id, 'sampleId', sample.sampleId);
  }

  Future<void> _setDeviceStringParameter(
      String deviceId, String parameterId, String value) async {
    try {
      await widget.bridge.setDeviceStringParameter(
        deviceId: deviceId,
        parameterId: parameterId,
        value: value,
      );
      await _refreshSnapshot(await widget.bridge.getProjectSnapshot());
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _onLibraryWavetableTap(LibraryWavetableItem item) async {
    final deviceId = _libraryWavetableDeviceId;
    if (deviceId == null) return;
    try {
      await widget.bridge.selectWavetable(deviceId, item.wavetableName);
      await _libraryPanelKey.currentState?.close();
      final snapshot = await widget.bridge.getProjectSnapshot();
      await _refreshSnapshot(snapshot);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${item.title}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _openSamplerEditor(
      TrackSnapshot track, DeviceSnapshot device) async {
    if (device is! SubtractiveSynthDeviceSnapshot) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => SubtractiveSynthEditorScreen(
          trackName: track.name,
          device: device,
          bridge: widget.bridge,
          onParameterChanged: (parameterId, value) =>
              _setSamplerParameter(device.id, parameterId, value),
        ),
      ),
    );

    try {
      final snapshot = await widget.bridge.getProjectSnapshot();
      await _refreshSnapshot(snapshot);
    } catch (_) {}
  }

  Future<void> _setFrequency(String deviceId, double value) async {
    _optimisticParamUpdate(deviceId, 'frequency', value);
    _captureAutomationForDeviceParam(deviceId, 'frequency', value);
    try {
      await widget.bridge.setDeviceParameter(
        deviceId: deviceId,
        parameterId: 'frequency',
        value: value,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _addDeviceToTrack(
    String trackId,
    String deviceType,
    int insertIndex,
  ) async {
    try {
      final snapshot = await widget.bridge.addDeviceToTrack(
        trackId: trackId,
        deviceType: deviceType,
        insertIndex: insertIndex,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setTrackGain(String deviceId, double value) async {
    _optimisticParamUpdate(deviceId, 'gain', value);
    _captureAutomationForDeviceParam(deviceId, 'gain', value);
    try {
      await widget.bridge.setDeviceParameter(
        deviceId: deviceId,
        parameterId: 'gain',
        value: value,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setTrackPan(String deviceId, double value) async {
    _optimisticParamUpdate(deviceId, 'pan', value);
    _captureAutomationForDeviceParam(deviceId, 'pan', value);
    try {
      await widget.bridge.setDeviceParameter(
        deviceId: deviceId,
        parameterId: 'pan',
        value: value,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setMasterGain(double value) async {
    try {
      await widget.bridge.setMasterGain(value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _saveProject() async {
    try {
      final location = await widget.bridge.saveProject();
      if (!mounted) return;
      if (location == null) {
        return;
      }
      setState(() {
        _saveStatus = 'Saved project';
        _projectError = null;
      });
      await _refreshRecentProjects();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(
          () => _projectError = '${e.code}: ${e.message ?? "save failed"}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _loadProject() async {
    try {
      final snapshot = await widget.bridge.loadProject();
      if (!mounted) return;
      if (snapshot == null) {
        return;
      }
      await _activateProject(snapshot);
      setState(() {
        _saveStatus = 'Loaded project';
        _projectError = null;
      });
      await _refreshRecentProjects();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(
          () => _projectError = '${e.code}: ${e.message ?? "load failed"}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _importSample() async {
    try {
      final updated = await widget.bridge.importSample();
      if (!mounted) return;
      if (updated != null) {
        await _refreshSnapshot(updated);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _insertSample(SampleLibraryEntrySnapshot sample) async {
    final trackId = _snapshot?.selectedTrackId;
    if (trackId == null || trackId.isEmpty) return;
    if (_trackFrozen(trackId)) {
      _showFrozenTrackSnack();
      return;
    }
    try {
      final updated = await widget.bridge.createSampleClip(
        trackId: trackId,
        sampleId: sample.id,
      );
      await _refreshSnapshot(updated);
      if (!mounted) return;
      setState(() => _tab = _ShellTab.devices);
      await _libraryPanelKey.currentState?.close();
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _previewSample(SampleLibraryEntrySnapshot sample) async {
    try {
      await widget.bridge.previewSample(sample.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _previewSamplerNote(int rootPitch) async {
    try {
      await widget.bridge.noteOn(pitch: rootPitch, velocity: 100);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await widget.bridge.noteOff(pitch: rootPitch);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _openPianoRoll(String trackId, MidiClipSnapshot clip) async {
    TrackSnapshot? track;
    for (final t in _snapshot?.tracks ?? const <TrackSnapshot>[]) {
      if (t.id == trackId) {
        track = t;
        break;
      }
    }
    if (track == null) return;

    DrumMachineDeviceSnapshot? drumMachine;
    for (final device in track.visibleDevices) {
      if (device is DrumMachineDeviceSnapshot) {
        drumMachine = device;
        break;
      }
    }
    final drumLaneLayout = drumMachine == null
        ? null
        : MidiLaneLayout(
            drumMachine.pads
                .where((pad) => pad.devices.isNotEmpty)
                .map((pad) => MidiLaneDefinition(
                      pitch: pad.note,
                      name: pad.name.isNotEmpty
                          ? pad.name
                          : MidiLaneLayout.defaultName(pad.note),
                    )),
          );

    final savedPlayhead = await _beginClipEditorSession();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => PianoRollScreen(
          bridge: widget.bridge,
          clip: clip,
          trackName: track!.name,
          bpm: _snapshot?.bpm ?? 120,
          drumAnchorPitch: track.drumAnchorPitch,
          drumLaneLayout:
              drumLaneLayout?.isNotEmpty == true ? drumLaneLayout : null,
          onSnapshot: _refreshSnapshot,
          savedArrangementPlayhead: savedPlayhead,
        ),
      ),
    );
    await _endClipEditorSession();

    try {
      final snapshot = await widget.bridge.getProjectSnapshot();
      await _refreshSnapshot(snapshot);
    } catch (_) {}
  }

  Future<void> _openSampleEditor(
      String trackId, SampleClipSnapshot clip) async {
    TrackSnapshot? track;
    for (final candidate in _snapshot?.tracks ?? const <TrackSnapshot>[]) {
      if (candidate.id == trackId) {
        track = candidate;
        break;
      }
    }
    if (track == null) return;
    final savedPlayhead = await _beginClipEditorSession();
    if (!mounted) return;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => SampleEditorScreen(
        bridge: widget.bridge,
        clip: clip,
        trackName: track!.name,
        samples: _snapshot?.samples ?? const [],
        onSnapshot: _refreshSnapshot,
        bpm: _snapshot?.bpm ?? 120,
        savedArrangementPlayhead: savedPlayhead,
      ),
    ));
    await _endClipEditorSession();
    try {
      await _refreshSnapshot(await widget.bridge.getProjectSnapshot());
    } catch (_) {}
  }

  // ── Transport methods (delegated to controller) ──────────

  Future<void> _setBpm(int bpm) async {
    try {
      await _applyDeltaMutation('setBpm', {'bpm': bpm});
      if (_transport.playing) {
        await _transport.syncTransportState();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setLoopEnabled(bool enabled) async {
    try {
      await _applyDeltaMutation('setLoopEnabled', {'enabled': enabled});
      _transport.syncTransportAnchorFromSnapshot(
        _snapshot!.bpm,
        _snapshot!.loopEnabled,
        _snapshot!.loopRegionStartBeat,
        _snapshot!.loopRegionEndBeat,
        _snapshot!.playheadBeats,
      );
      if (_transport.playing) {
        await _transport.syncTransportState();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setLoopRegion({
    required double startBeat,
    required double endBeat,
  }) async {
    try {
      await _applyDeltaMutation('setLoopRegion', {
        'startBeat': startBeat,
        'endBeat': endBeat,
      });
      _transport.syncTransportAnchorFromSnapshot(
        _snapshot!.bpm,
        _snapshot!.loopEnabled,
        _snapshot!.loopRegionStartBeat,
        _snapshot!.loopRegionEndBeat,
        _snapshot!.playheadBeats,
      );
      if (_transport.playing) {
        await _transport.syncTransportState();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _duplicateClip(String clipId) async {
    try {
      final snapshot = await widget.bridge.duplicateClip(clipId);
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _confirmDeleteTrack(String trackId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete track?'),
        content: const Text('Clips on this track will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final snapshot = await widget.bridge.deleteTrack(trackId);
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _confirmRemoveDevice(
    TrackSnapshot track,
    DeviceSnapshot device,
  ) async {
    final label = DeviceStripTheme.labelForDeviceType(device.type);
    final isLastInstrument =
        device.isInstrumentDevice && track.visibleInstrumentCount <= 1;
    final hasAutomation = track.hasLinkedAutomationFor(device.id);

    final message = StringBuffer('Remove $label from this track?');
    if (hasAutomation) {
      message.write('\n\nAutomation linked to this device will be unlinked.');
    }
    if (isLastInstrument) {
      message.write(
        '\n\nThis is the only instrument on the track. MIDI clips will be silent until you add a new device.',
      );
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete device?'),
        content: Text(message.toString()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final snapshot =
          await widget.bridge.removeDeviceFromTrack(deviceId: device.id);
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _confirmDeleteClip(String clipId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete clip?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final snapshot = await widget.bridge.deleteClip(clipId);
      await _refreshSnapshot(snapshot);
      // If the deleted clip was in link mode, clear it
      if (_automationLinkClipId == clipId) {
        setState(() => _automationLinkClipId = null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _exportMix() async {
    try {
      setState(() => _saveStatus = 'Rendering…');
      final length = _snapshot?.loopRegionEndBeat ?? 16.0;
      final uri = await widget.bridge.exportMix(lengthBeats: length);
      if (!mounted) return;
      setState(() => _saveStatus = uri == null ? null : 'Exported mix');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _projectError = e.toString();
        _saveStatus = null;
      });
    }
  }

  Future<void> _moveClip({
    required String clipId,
    required String trackId,
    required double startBeat,
  }) async {
    try {
      final snapshot = await widget.bridge.moveClip(
        clipId: clipId,
        trackId: trackId,
        startBeat: startBeat,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _resizeClip({
    required String clipId,
    required double lengthBeats,
  }) async {
    try {
      final snapshot = await widget.bridge.setClipLength(
        clipId: clipId,
        lengthBeats: lengthBeats,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setClipLoopContent({
    required String clipId,
    required bool loopContent,
  }) async {
    try {
      final snapshot = await widget.bridge.setClipLoopContent(
        clipId: clipId,
        loopContent: loopContent,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setPlayheadBeats(double beats) async {
    try {
      await _transport.setPlayheadBeats(beats);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _jumpToStart() async {
    await _setPlayheadBeats(0);
    _arrangementScrollController.revealPlayheadAtViewportOrigin(0);
  }

  Future<void> _startPlay() async {
    final beats = _effectivePlayheadBeats;
    final snap = _snapshot;
    final recordingDecision = decideRecordingSession(snap);
    try {
      await _transport.startPlay(
        beats,
        holdForCountIn: snap?.recordArmed == true && _countInBars > 0,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _projectError = e.toString());
      }
      return;
    }
    if (recordingDecision != null) {
      unawaited(_beginRecordingAfterCountIn(
        recordingDecision.trackId,
        beats,
        recordAudio: recordingDecision.recordAudio,
        recordMidi: recordingDecision.recordMidi,
        recordAutomation: recordingDecision.recordAutomation,
      ));
    }
    _arrangementScrollController.catchUpPlayheadOnPlay(beats);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _beginRecordingAfterCountIn(
    String trackId,
    double requestedStartBeat, {
    required bool recordAudio,
    required bool recordMidi,
    required bool recordAutomation,
  }) async {
    try {
      var startBeat = requestedStartBeat;
      if (_countInBars > 0) {
        startBeat = await _waitForCountInToFinish(requestedStartBeat);
      }
      if (!_transport.playing || _snapshot?.selectedTrackId != trackId) return;

      if (recordMidi) {
        _pendingMidiRecordingTakes.clear();
        await _beginMidiRecordingPass(trackId: trackId, startBeat: startBeat);
      }

      if (recordAutomation) {
        _automationRecording.begin(trackId: trackId, startBeat: startBeat);
        _automationRecordingClipIds.clear();
        _automationRecordingOriginalClips.clear();
      }

      if (recordAudio) {
        final displayName =
            'Recorded take ${DateTime.now().millisecondsSinceEpoch}';
        final targetClipId = _recordingTargetClipId(trackId, startBeat);
        final session = await widget.bridge.beginAudioRecordingSession(
          trackId: trackId,
          startBeat: startBeat,
          sampleRate: 48000,
          displayName: displayName,
          targetClipId: targetClipId,
        );
        if (session.sampleId.isEmpty || session.clipId.isEmpty) {
          throw Exception('Recording session did not return ids');
        }
        await _refreshSnapshot(session.snapshot);
        try {
          await widget.bridge.startTrackAudioRecording(
            sampleId: session.sampleId,
            clipId: session.clipId,
          );
        } catch (_) {
          final snapshot = await widget.bridge.cancelAudioRecordingSession(
            sampleId: session.sampleId,
            clipId: session.clipId,
          );
          await _refreshSnapshot(snapshot);
          rethrow;
        }
        _audioRecordingTrackId = trackId;
        _audioRecordingSampleId = session.sampleId;
        _audioRecordingClipId = session.clipId;
        _audioRecordingStartBeat = startBeat;
        _audioRecordingSessions
          ..clear()
          ..add(session);
        _highlightedClipId = session.clipId;
        _liveClipStartBeats[session.clipId] = startBeat;
      }

      if (_anyRecordingActive) {
        _lastAudioRecordingPlayhead = startBeat;
        _arrangementScrollController.revealPlayheadAtViewportOrigin(startBeat);
        _startAudioRecordingSnapshotRefresh();
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (recordMidi) {
        try {
          await widget.bridge.cancelMidiRecordingSession();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  String? _recordingTargetClipId(String trackId, double startBeat) {
    final snap = _snapshot;
    if (snap == null) return null;
    if (_recordWriteMode != RecordWriteMode.take) return null;
    for (final track in snap.tracks) {
      if (track.id != trackId) continue;
      for (final clip in track.sampleClips) {
        if (startBeat >= clip.startBeat && startBeat < clip.endBeat) {
          return clip.id;
        }
      }
    }
    return null;
  }

  MidiClipSnapshot? _midiRecordingTargetForMode(
    String trackId,
    double startBeat, {
    ProjectSnapshot? snapshot,
  }) {
    if (_recordWriteMode == RecordWriteMode.fresh) return null;
    TrackSnapshot? track;
    for (final candidate in snapshot?.tracks ?? _snapshot?.tracks ?? const []) {
      if (candidate.id == trackId) {
        track = candidate;
        break;
      }
    }
    if (track == null) return null;
    for (final clip in track.midiClips) {
      if (startBeat >= clip.startBeat && startBeat < clip.endBeat) {
        return clip;
      }
    }
    return null;
  }

  Future<void> _beginMidiRecordingPass({
    required String trackId,
    required double startBeat,
    ProjectSnapshot? snapshot,
  }) async {
    await widget.bridge.beginMidiRecordingSession(
      trackId: trackId,
      startBeat: startBeat,
      quantizeStep: 0.25,
    );
    _midiRecordingTrackId = trackId;
    _midiRecordingStartBeat = startBeat;
    _midiRecordingOpenNotes.clear();
    _midiRecordingPreviewNotes.clear();
    _midiRecordingTargetClip = _midiRecordingTargetForMode(
      trackId,
      startBeat,
      snapshot: snapshot,
    );
    if (_midiRecordingTargetClip case final target?) {
      _midiRecordingPreviewClipId = target.id;
      _highlightedClipId = target.id;
    } else {
      await _createMidiRecordingPreviewClip(trackId, startBeat);
    }
  }

  Future<double> _waitForCountInToFinish(double requestedStartBeat) async {
    for (var i = 0; i < 80; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final transport = await widget.bridge.getTransportState();
      if (!transport.playing) break;
      if (transport.playheadBeats > requestedStartBeat + 0.001) {
        _transport.anchorTransport(transport);
        _transport.publishPlayhead(transport.playheadBeats);
        return transport.playheadBeats;
      }
      if (!_transport.playing) break;
    }
    return _transport.effectivePlayheadBeats;
  }

  Future<void> _createMidiRecordingPreviewClip(
    String trackId,
    double startBeat,
  ) async {
    _midiRecordingPreviewClipId =
        'midi-record-preview-${DateTime.now().microsecondsSinceEpoch}';
    _highlightedClipId = _midiRecordingPreviewClipId;
    _liveClipStartBeats[_midiRecordingPreviewClipId!] = startBeat;
    if (mounted) setState(() {});
  }

  Future<void> _updateLiveRecordingPreviews(TransportState transport) async {
    if (_midiRecordingActive) {
      await _updateMidiRecordingPreview(transport.playheadBeats);
    }
    if (_automationRecordingActive) {
      await _updateAutomationRecordingPreviews(transport.playheadBeats);
    }
  }

  Future<void> _updateMidiRecordingPreview(double endBeat) async {
    final clipId = _midiRecordingPreviewClipId;
    if (clipId == null) return;
    if (mounted) setState(() {});
  }

  List<MidiNoteSnapshot> _currentMidiRecordingPreviewNotes(double endBeat) {
    final notes = List<MidiNoteSnapshot>.of(_midiRecordingPreviewNotes);
    final localEnd = (endBeat - _midiRecordingStartBeat).clamp(0.0, 1024.0);
    for (final open in _midiRecordingOpenNotes.values) {
      final duration = (localEnd - open.startBeat).clamp(0.05, 1024.0);
      notes.add(MidiNoteSnapshot(
        pitch: open.pitch,
        startBeat: open.startBeat,
        durationBeats: duration.toDouble(),
        velocity: open.velocity,
      ));
    }
    notes.sort((a, b) => a.startBeat.compareTo(b.startBeat));
    return notes;
  }

  Future<void> _updateAutomationRecordingPreviews(double endBeat) async {
    final commits = _automationRecording.previewSegments(endBeat: endBeat);
    ProjectSnapshot? snapshot;
    for (final commit in commits) {
      final clipId = await _ensureAutomationRecordingClip(commit);
      if (clipId == null) continue;
      snapshot = await widget.bridge.setClipLength(
        clipId: clipId,
        lengthBeats: _automationPreviewLength(clipId, commit),
      );
      snapshot = await widget.bridge.setAutomationPoints(
        clipId: clipId,
        points: _automationPreviewPoints(clipId, commit),
      );
    }
    if (snapshot != null) {
      await _refreshSnapshot(snapshot);
    }
  }

  Future<String?> _ensureAutomationRecordingClip(
    AutomationSegmentCommit commit,
  ) async {
    final existing = _automationRecordingClipIds[commit.laneKey];
    if (existing != null) return existing;
    final target = _automationRecordingTargetForMode(commit);
    if (target != null) {
      _automationRecordingClipIds[commit.laneKey] = target.id;
      _automationRecordingOriginalClips[target.id] = target;
      _highlightedClipId = target.id;
      return target.id;
    }
    final beforeIds =
        _snapshot?.automationClips.map((clip) => clip.id).toSet() ?? <String>{};
    var snapshot = await widget.bridge.createAutomationClip(
      trackId: commit.trackId,
      startBeat: commit.startBeat,
      lengthBeats: commit.lengthBeats,
    );
    final created = snapshot.automationClips.lastWhere(
      (clip) => !beforeIds.contains(clip.id),
      orElse: () => snapshot.automationClips.last,
    );
    snapshot = await widget.bridge.assignAutomationTarget(
      clipId: created.id,
      deviceId: commit.deviceId,
      paramId: commit.paramId,
    );
    _automationRecordingClipIds[commit.laneKey] = created.id;
    _highlightedClipId = created.id;
    _liveClipStartBeats[created.id] = commit.startBeat;
    await _refreshSnapshot(snapshot);
    return created.id;
  }

  AutomationClipSnapshot? _automationRecordingTargetForMode(
    AutomationSegmentCommit commit,
  ) {
    if (!_recordWriteMode.targetsExisting) return null;
    final clips =
        _snapshot?.automationClips ?? const <AutomationClipSnapshot>[];
    for (final clip in clips) {
      if (clip.homeTrackId != commit.trackId ||
          clip.deviceId != commit.deviceId ||
          clip.paramId != commit.paramId) {
        continue;
      }
      if (commit.startBeat >= clip.startBeat &&
          commit.startBeat < clip.endBeat) {
        return clip;
      }
    }
    return null;
  }

  void _startAudioRecordingSnapshotRefresh() {
    _audioRecordingSnapshotTimer?.cancel();
    _audioRecordingSnapshotTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) async {
        if (!_anyRecordingActive) return;
        try {
          final transport = await widget.bridge.getTransportState();
          await _rollLoopRecordingIfNeeded(transport);
          await _updateLiveRecordingPreviews(transport);
          await _refreshSnapshot(await widget.bridge.getProjectSnapshot());
          if (_audioRecordingActive) {
            final level = await widget.bridge.getTrackAudioRecordingLevel();
            if (mounted) {
              setState(() => _audioRecordingInputLevel = level);
            }
          }
        } catch (_) {}
      },
    );
  }

  Future<void> _rollLoopRecordingIfNeeded(TransportState transport) async {
    if (_audioRecordingRollBusy ||
        !_anyRecordingActive ||
        transport.loopEnabled != true ||
        transport.loopRegionEndBeat <= transport.loopRegionStartBeat) {
      _lastAudioRecordingPlayhead = transport.playheadBeats;
      return;
    }
    final last = _lastAudioRecordingPlayhead;
    final current = transport.playheadBeats;
    final didWrap = last != null && current + 0.25 < last;
    _lastAudioRecordingPlayhead = current;
    if (!didWrap) return;

    final loopStart = transport.loopRegionStartBeat;
    if (_midiRecordingActive) {
      final trackId = _midiRecordingTrackId;
      final targetSnapshot = _snapshot;
      if (trackId != null) {
        try {
          if (_recordWriteMode == RecordWriteMode.take) {
            _stashCurrentMidiRecordingTake(
                endBeat: transport.loopRegionEndBeat);
            await widget.bridge.cancelMidiRecordingSession();
          } else {
            final committedSnapshot = await _finishMidiRecordingSession(
                endBeat: transport.loopRegionEndBeat);
            if (committedSnapshot != null) {
              await _refreshSnapshot(committedSnapshot);
            }
          }
          await _beginMidiRecordingPass(
            trackId: trackId,
            startBeat: loopStart,
            snapshot: targetSnapshot,
          );
        } catch (e) {
          _midiRecordingTrackId = null;
          if (mounted) {
            setState(() => _projectError = 'MIDI take restart failed: $e');
          }
        }
      }
    }
    if (_automationRecordingActive) {
      await _finishAutomationRecordingSegment(
        endBeat: transport.loopRegionEndBeat,
        keepSessionActive: true,
        nextStartBeat: loopStart,
      );
      for (final clipId in _automationRecordingClipIds.values) {
        _liveClipStartBeats.remove(clipId);
      }
      _automationRecordingClipIds.clear();
    }

    final trackId = _audioRecordingTrackId;
    final oldSampleId = _audioRecordingSampleId;
    final clipId = _audioRecordingClipId;
    if (trackId == null || oldSampleId == null || clipId == null) return;

    _audioRecordingRollBusy = true;
    try {
      final displayName =
          'Recorded take ${DateTime.now().millisecondsSinceEpoch}';
      final nextSession = await widget.bridge.beginAudioRecordingSession(
        trackId: trackId,
        startBeat: loopStart,
        sampleRate: 48000,
        displayName: displayName,
        targetClipId: clipId,
      );
      if (nextSession.sampleId.isEmpty || nextSession.clipId.isEmpty) return;
      await widget.bridge.retargetTrackAudioRecording(
        sampleId: nextSession.sampleId,
        clipId: nextSession.clipId,
      );
      final snapshot = await widget.bridge.finishAudioRecordingSession(
        sampleId: oldSampleId,
        clipId: clipId,
      );
      await _refreshSnapshot(snapshot);
      _audioRecordingSampleId = nextSession.sampleId;
      _audioRecordingClipId = nextSession.clipId;
      _audioRecordingStartBeat = loopStart;
      _audioRecordingSessions.add(nextSession);
      _highlightedClipId = nextSession.clipId;
      _liveClipStartBeats[nextSession.clipId] = loopStart;
      if (mounted) setState(() {});
    } finally {
      _audioRecordingRollBusy = false;
    }
  }

  void _recordAutomationPoint(
    String trackId,
    String deviceId,
    String paramId,
    double value,
  ) {
    if (!_transport.playing) return;
    _automationRecording.recordPoint(
      trackId: trackId,
      deviceId: deviceId,
      paramId: paramId,
      value: value,
      beat: _effectivePlayheadBeats,
    );
  }

  void _onLiveMidiNote(LiveMidiNoteEvent event) {
    if (!_midiRecordingActive) return;
    final localBeat =
        (_effectivePlayheadBeats - _midiRecordingStartBeat).clamp(0.0, 1024.0);
    if (event.allOff) {
      for (final open in _midiRecordingOpenNotes.values) {
        _midiRecordingPreviewNotes.add(MidiNoteSnapshot(
          pitch: open.pitch,
          startBeat: open.startBeat,
          durationBeats:
              (localBeat - open.startBeat).clamp(0.05, 1024.0).toDouble(),
          velocity: open.velocity,
        ));
      }
      _midiRecordingOpenNotes.clear();
      if (mounted) setState(() {});
      return;
    }
    if (event.isNoteOn) {
      _midiRecordingOpenNotes[event.pitch] = _MidiRecordingPreviewNote(
        pitch: event.pitch,
        startBeat: localBeat.toDouble(),
        velocity: event.velocity,
      );
      if (mounted) setState(() {});
      return;
    }
    final open = _midiRecordingOpenNotes.remove(event.pitch);
    if (open == null) return;
    _midiRecordingPreviewNotes.add(MidiNoteSnapshot(
      pitch: open.pitch,
      startBeat: open.startBeat,
      durationBeats:
          (localBeat - open.startBeat).clamp(0.05, 1024.0).toDouble(),
      velocity: open.velocity,
    ));
    if (mounted) setState(() {});
  }

  void _stashCurrentMidiRecordingTake({required double endBeat}) {
    final notes = _currentMidiRecordingPreviewNotes(endBeat);
    if (notes.isNotEmpty) {
      _pendingMidiRecordingTakes.add(_PendingMidiRecordingTake(
        startBeat: _midiRecordingStartBeat,
        endBeat: endBeat,
        notes: notes,
      ));
    }
    final previewClipId = _midiRecordingPreviewClipId;
    if (previewClipId != null &&
        previewClipId.startsWith('midi-record-preview-')) {
      _liveClipStartBeats.remove(previewClipId);
    }
    _midiRecordingOpenNotes.clear();
    _midiRecordingPreviewNotes.clear();
  }

  Future<ProjectSnapshot?> _finishMidiRecordingSession(
      {double? endBeat}) async {
    final trackId = _midiRecordingTrackId;
    if (trackId == null) return null;
    final previewClipId = _midiRecordingPreviewClipId;
    final targetClip = _midiRecordingTargetClip;
    final finishBeat = endBeat ?? _effectivePlayheadBeats;
    final recordedNotes = _currentMidiRecordingPreviewNotes(finishBeat);
    final takePasses = [
      ..._pendingMidiRecordingTakes,
      if (recordedNotes.isNotEmpty)
        _PendingMidiRecordingTake(
          startBeat: _midiRecordingStartBeat,
          endBeat: finishBeat,
          notes: recordedNotes,
        ),
    ];
    _pendingMidiRecordingTakes.clear();
    _midiRecordingTrackId = null;
    _midiRecordingPreviewClipId = null;
    _midiRecordingTargetClip = null;
    _midiRecordingOpenNotes.clear();
    _midiRecordingPreviewNotes.clear();
    if (previewClipId != null) {
      _liveClipStartBeats.remove(previewClipId);
    }
    try {
      if (_recordWriteMode == RecordWriteMode.take && takePasses.isEmpty) {
        await widget.bridge.cancelMidiRecordingSession();
        return null;
      }
      if (targetClip != null) {
        await widget.bridge.cancelMidiRecordingSession();
        if (_recordWriteMode == RecordWriteMode.take) {
          ProjectSnapshot? snapshot;
          for (final entry in takePasses.indexed) {
            final pass = entry.$2;
            snapshot = await widget.bridge.addMidiClipTake(
              clipId: targetClip.id,
              name: 'Take ${targetClip.takes.length + 1 + entry.$1}',
              startBeatOffset: (pass.startBeat - targetClip.startBeat)
                  .clamp(0.0, targetClip.lengthBeats)
                  .toDouble(),
              lengthBeats: pass.lengthBeats,
              notes: pass.notes,
            );
          }
          _highlightedClipId = targetClip.id;
          return snapshot;
        }
        var snapshot = await widget.bridge.setMidiClipNotes(
          clipId: targetClip.id,
          notes: mergeMidiRecordingNotes(
            existingNotes: targetClip.notes,
            recordedNotes: recordedNotes,
            targetClipStartBeat: targetClip.startBeat,
            recordingStartBeat: _midiRecordingStartBeat,
            recordingEndBeat: finishBeat,
            mode: _recordWriteMode,
          ),
        );
        final requiredLength = (finishBeat - targetClip.startBeat)
            .clamp(targetClip.lengthBeats, 1024.0)
            .toDouble();
        if (requiredLength > targetClip.lengthBeats + 0.001) {
          snapshot = await widget.bridge.setClipLength(
            clipId: targetClip.id,
            lengthBeats: requiredLength,
          );
        }
        return snapshot;
      }
      if (_recordWriteMode == RecordWriteMode.take) {
        await widget.bridge.cancelMidiRecordingSession();
        final created = await _createMidiTakeAnchorClip(
          trackId: trackId,
          finishBeat: finishBeat,
          firstPass: takePasses.first,
        );
        var snapshot = created.snapshot;
        for (var i = 1; i < takePasses.length; i++) {
          final pass = takePasses[i];
          snapshot = await widget.bridge.addMidiClipTake(
            clipId: created.clipId,
            name: 'Take ${i + 1}',
            startBeatOffset: (pass.startBeat - created.anchorStartBeat)
                .clamp(0.0, created.anchorLengthBeats)
                .toDouble(),
            lengthBeats: pass.lengthBeats,
            notes: pass.notes,
          );
        }
        return snapshot;
      }
      var snapshot =
          await widget.bridge.finishMidiRecordingSession(endBeat: endBeat);
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  Future<
      ({
        ProjectSnapshot snapshot,
        String clipId,
        double anchorStartBeat,
        double anchorLengthBeats,
      })> _createMidiTakeAnchorClip({
    required String trackId,
    required double finishBeat,
    required _PendingMidiRecordingTake firstPass,
  }) async {
    final snap = _snapshot;
    final useLoopAnchor = snap?.loopEnabled == true &&
        firstPass.startBeat >= snap!.loopRegionStartBeat &&
        firstPass.startBeat < snap.loopRegionEndBeat &&
        finishBeat >= snap.loopRegionEndBeat - 0.001;
    final anchorStart =
        useLoopAnchor ? snap.loopRegionStartBeat : firstPass.startBeat;
    final anchorLength = useLoopAnchor
        ? (snap.loopRegionEndBeat - snap.loopRegionStartBeat)
            .clamp(0.25, 1024.0)
            .toDouble()
        : firstPass.lengthBeats;
    final takeOffset =
        (firstPass.startBeat - anchorStart).clamp(0.0, anchorLength);
    final beforeIds =
        _trackById(trackId)?.midiClips.map((clip) => clip.id).toSet() ??
            <String>{};
    var snapshot = await widget.bridge.createMidiClip(
      trackId: trackId,
      startBeat: anchorStart,
      lengthBeats: anchorLength,
    );
    final track = snapshot.tracks.firstWhere((track) => track.id == trackId);
    final created = track.midiClips.lastWhere(
      (clip) => !beforeIds.contains(clip.id),
      orElse: () => track.midiClips.last,
    );
    snapshot = await widget.bridge.setMidiClipNotes(
      clipId: created.id,
      notes: const [],
    );
    snapshot = await widget.bridge.addMidiClipTake(
      clipId: created.id,
      name: 'Take 1',
      startBeatOffset: takeOffset.toDouble(),
      lengthBeats: firstPass.lengthBeats,
      notes: firstPass.notes,
    );
    _highlightedClipId = created.id;
    _liveClipStartBeats.remove(_midiRecordingPreviewClipId);
    return (
      snapshot: snapshot,
      clipId: created.id,
      anchorStartBeat: anchorStart,
      anchorLengthBeats: anchorLength,
    );
  }

  Future<ProjectSnapshot?> _finishAutomationRecordingSegment({
    required double endBeat,
    required bool keepSessionActive,
    double? nextStartBeat,
  }) async {
    if (!_automationRecordingActive) return null;
    final commits = _automationRecording.finishSegment(
      endBeat: endBeat,
      keepActive: keepSessionActive,
      nextStartBeat: nextStartBeat,
    );
    final liveClipIds = Map<String, String>.of(_automationRecordingClipIds);
    final originalClips = Map<String, AutomationClipSnapshot>.of(
        _automationRecordingOriginalClips);
    final committedClipIds = <String>{};
    ProjectSnapshot? snapshot;
    for (final commit in commits) {
      final clipId = await _ensureAutomationRecordingClip(commit);
      if (clipId == null) continue;
      committedClipIds.add(clipId);
      snapshot = await widget.bridge.setClipLength(
        clipId: clipId,
        lengthBeats: _automationPreviewLength(clipId, commit),
      );
      snapshot = await widget.bridge.setAutomationPoints(
        clipId: clipId,
        points: _automationPreviewPoints(clipId, commit),
      );
    }
    for (final clipId in liveClipIds.values) {
      if (committedClipIds.contains(clipId)) continue;
      final original = originalClips[clipId];
      if (original != null) {
        snapshot = await widget.bridge.setClipLength(
          clipId: clipId,
          lengthBeats: original.lengthBeats,
        );
        snapshot = await widget.bridge.setAutomationPoints(
          clipId: clipId,
          points: original.points,
        );
      } else {
        snapshot = await widget.bridge.deleteClip(clipId);
      }
      _liveClipStartBeats.remove(clipId);
    }
    if (!keepSessionActive) {
      for (final clipId in _automationRecordingClipIds.values) {
        _liveClipStartBeats.remove(clipId);
      }
      _automationRecordingClipIds.clear();
      _automationRecordingOriginalClips.clear();
    } else {
      _automationRecordingOriginalClips.clear();
    }
    return snapshot;
  }

  double _automationPreviewLength(
    String clipId,
    AutomationSegmentCommit commit,
  ) {
    final original = _automationRecordingOriginalClips[clipId];
    if (original == null) return commit.lengthBeats;
    return (commit.startBeat + commit.lengthBeats - original.startBeat)
        .clamp(original.lengthBeats, 1024.0)
        .toDouble();
  }

  List<AutomationPointSnapshot> _automationPreviewPoints(
    String clipId,
    AutomationSegmentCommit commit,
  ) {
    final original = _automationRecordingOriginalClips[clipId];
    if (original == null) return commit.points;
    return mergeAutomationRecordingPoints(
      targetClip: original,
      commit: commit,
      mode: _recordWriteMode,
    );
  }

  Future<void> _setMetronome(
      bool enabled, double level, int countInBars) async {
    setState(() {
      _metronomeEnabled = enabled;
      _metronomeLevel = level;
      _countInBars = countInBars;
    });
    try {
      await widget.bridge.setMetronome(
          enabled: enabled, level: level, countInBars: countInBars);
    } catch (e) {
      if (mounted) setState(() => _projectError = e.toString());
    }
  }

  Future<void> _stopPlay() async {
    final sessions = List<AudioRecordingSession>.of(_audioRecordingSessions);
    final clipId = _audioRecordingClipId;
    final automationEndBeat = _effectivePlayheadBeats;
    _audioRecordingTrackId = null;
    _audioRecordingSampleId = null;
    _audioRecordingClipId = null;
    _audioRecordingSessions.clear();
    _lastAudioRecordingPlayhead = null;
    _audioRecordingInputLevel = 0.0;
    _audioRecordingSnapshotTimer?.cancel();
    await _transport.stopPlay();
    _liveMeters.clear();
    try {
      final midiSnapshot =
          await _finishMidiRecordingSession(endBeat: automationEndBeat);
      if (midiSnapshot != null) await _refreshSnapshot(midiSnapshot);
      final automationSnapshot = await _finishAutomationRecordingSegment(
        endBeat: automationEndBeat,
        keepSessionActive: false,
      );
      if (automationSnapshot != null) {
        await _refreshSnapshot(automationSnapshot);
      }
    } catch (e) {
      if (mounted) setState(() => _projectError = e.toString());
    }
    if (sessions.isNotEmpty) {
      try {
        await widget.bridge.stopTrackAudioRecording();
        ProjectSnapshot? lastSnapshot;
        final finished = <String>{};
        for (final session in sessions) {
          final key = '${session.sampleId}:${session.clipId}';
          if (finished.contains(key)) continue;
          finished.add(key);
          _liveClipStartBeats.remove(session.clipId);
          lastSnapshot = await widget.bridge.finishAudioRecordingSession(
            sampleId: session.sampleId,
            clipId: session.clipId,
          );
        }
        if (lastSnapshot != null) await _refreshSnapshot(lastSnapshot);
        _highlightedClipId = clipId;
        _arrangementScrollController.revealPlayheadAtViewportOrigin(
          _audioRecordingStartBeat,
        );
      } catch (e) {
        if (mounted) {
          setState(() => _projectError = e.toString());
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _cancelAudioRecording() async {
    if (!_anyRecordingActive) return;
    final sessions = List<AudioRecordingSession>.of(_audioRecordingSessions);
    final midiPreviewClipId = _midiRecordingPreviewClipId;
    final midiTargetClip = _midiRecordingTargetClip;
    final automationPreviewClipIds = _automationRecordingClipIds.values.toSet();
    final automationOriginalClips = Map<String, AutomationClipSnapshot>.of(
        _automationRecordingOriginalClips);
    _audioRecordingTrackId = null;
    _audioRecordingSampleId = null;
    _audioRecordingClipId = null;
    _midiRecordingTrackId = null;
    _midiRecordingPreviewClipId = null;
    _midiRecordingTargetClip = null;
    _midiRecordingOpenNotes.clear();
    _midiRecordingPreviewNotes.clear();
    _pendingMidiRecordingTakes.clear();
    _automationRecording.cancel();
    _automationRecordingClipIds.clear();
    _automationRecordingOriginalClips.clear();
    _audioRecordingSessions.clear();
    _lastAudioRecordingPlayhead = null;
    _audioRecordingInputLevel = 0.0;
    _highlightedClipId = null;
    _audioRecordingSnapshotTimer?.cancel();
    try {
      await widget.bridge.cancelMidiRecordingSession();
      ProjectSnapshot? lastSnapshot;
      if (midiPreviewClipId != null && midiTargetClip == null) {
        _liveClipStartBeats.remove(midiPreviewClipId);
      }
      for (final clipId in automationPreviewClipIds) {
        _liveClipStartBeats.remove(clipId);
        final original = automationOriginalClips[clipId];
        if (original != null) {
          lastSnapshot = await widget.bridge.setClipLength(
            clipId: clipId,
            lengthBeats: original.lengthBeats,
          );
          lastSnapshot = await widget.bridge.setAutomationPoints(
            clipId: clipId,
            points: original.points,
          );
        } else {
          lastSnapshot = await widget.bridge.deleteClip(clipId);
        }
      }
      if (sessions.isNotEmpty) {
        await widget.bridge.cancelTrackAudioRecording();
      }
      final cancelled = <String>{};
      for (final session in sessions.reversed) {
        final key = '${session.sampleId}:${session.clipId}';
        if (cancelled.contains(key)) continue;
        cancelled.add(key);
        _liveClipStartBeats.remove(session.clipId);
        lastSnapshot = await widget.bridge.cancelAudioRecordingSession(
          sampleId: session.sampleId,
          clipId: session.clipId,
        );
      }
      if (lastSnapshot != null) await _refreshSnapshot(lastSnapshot);
      await _transport.stopPlay();
      _liveMeters.clear();
      if (!mounted) return;
      setState(() {
        _saveStatus = 'Recording discarded';
        _projectError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  void _setFollowPlayheadEnabled(bool enabled) {
    _transport.setFollowPlayheadEnabled(enabled);
    if (enabled && _transport.playing) {
      _arrangementScrollController.catchUpPlayheadOnPlay(
        _effectivePlayheadBeats,
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onFollowSuspended() {
    if (!_transport.followPlayheadSuspended && mounted) {
      setState(() => _transport.followPlayheadSuspended = true);
    }
  }

  void _onFollowResumed() {
    if (_transport.followPlayheadSuspended && mounted) {
      setState(() => _transport.followPlayheadSuspended = false);
    }
  }

  Future<void> _onTabSelected(_ShellTab tab) async {
    if (_snapshot == null) return;
    if (tab == _ShellTab.library) {
      if (_libraryOpen) {
        await _libraryPanelKey.currentState?.close();
      } else {
        await _openLibrary();
      }
      return;
    }

    if (_libraryOpen) {
      _closeLibrary();
    }

    if (_tab == tab) return;
    if (_tab == _ShellTab.keys || tab == _ShellTab.keys) {
      try {
        await widget.bridge.allNotesOff();
      } catch (_) {}
    }
    setState(() => _tab = tab);
    if (tab != _ShellTab.devices) {
      unawaited(_updateMeterSubscriptions(const []));
    }
    await _syncLiveInputForTab(tab);
  }

  Widget _buildArrangementColumn(ProjectSnapshot snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ArrangementView(
            key: const ValueKey('daw-arrangement'),
            timelineScrollController: _arrangementScrollController,
            followPlayheadEnabled: _transport.followPlayheadEnabled,
            onFollowSuspended: _onFollowSuspended,
            onFollowResumed: _onFollowResumed,
            playheadListenable: _transport.playheadNotifier,
            snapshot: snapshot,
            snapClipsEnabled: _snapClipsEnabled,
            snapGridResolution: _snapGridResolution,
            snapGridTriplet: _snapGridTriplet,
            playheadBeats: _effectivePlayheadBeats,
            playing: _transport.playing,
            onPlayRequested: _startPlay,
            onStopRequested: _stopPlay,
            onPlayheadSeek: _setPlayheadBeats,
            onLoopRegionChanged: _setLoopRegion,
            onTrackSelected: _selectTrack,
            onAddTrack: _addTrack,
            onAddGroup: _addGroupTrack,
            onSetTrackGroup: _setTrackGroup,
            onMoveTrack: _moveTrack,
            onSetTrackMuted: _setTrackMuted,
            onSetTrackSoloed: _setTrackSoloed,
            onSetTrackRecordArmed: _setTrackRecordArmed,
            onToggleTrackFreeze: _toggleTrackFreeze,
            onAddMidiClip: _addMidiClip,
            onAddAudioClip: _addAudioClip,
            onClipTap: _openPianoRoll,
            onSampleClipTap: _openSampleEditor,
            onMoveClip: _moveClip,
            onResizeClipCommit: _resizeClip,
            onDeleteTrack: _confirmDeleteTrack,
            onDeleteClip: _confirmDeleteClip,
            onDuplicateClip: _duplicateClip,
            onSetClipLoopContent: _setClipLoopContent,
            onAddAutomationClip: _addAutomationClip,
            automationLinkClipId: _automationLinkClipId,
            highlightedClipId: _highlightedClipId,
            onAutomationLinkToggle: _toggleAutomationLink,
            onAutomationClipDoubleTap: _openAutomationCurveEditor,
            liveClipStartBeats: _liveClipStartBeats,
            liveMidiPreviewNotes: _liveMidiPreviewNotes,
            liveMidiPreviewClips: _liveMidiPreviewClips,
          ),
        ),
        if (_tab == _ShellTab.devices)
          DeviceStrip(
            snapshot: snapshot,
            track: snapshot.selectedTrack,
            samples: snapshot.samples,
            playing: _transport.playing,
            playheadBeatListenable: _transport.playheadNotifier,
            liveMetersListenable: _liveMeters,
            onSamplerParameterChanged: _setSamplerParameter,
            onDeviceStringParameterChanged: _setDeviceStringParameter,
            onAssignSamplerSample: _assignSamplerSample,
            onOpenSamplerEditor: _openSamplerEditor,
            onPreviewSample: _previewSample,
            onPreviewSampler: _previewSamplerNote,
            onImportSamples: () async {
              final updated = await widget.bridge.importSample();
              if (updated != null) {
                await _refreshSnapshot(updated);
                return updated.samples;
              }
              return snapshot.samples;
            },
            onFrequencyChanged: _setFrequency,
            onAddDevice: _addDeviceToTrack,
            onBypassToggle: (deviceId, bypassed) =>
                _setDeviceBypass(deviceId, bypassed),
            onRemoveDevice: _confirmRemoveDevice,
            onOpenDeviceLibrary: _openDeviceLibrary,
            onOpenDrumPadLibrary: _openDrumPadLibrary,
            onModulationBridgeCall: _modulationBridgeCall,
            automationLinkClipId: _automationLinkClipId,
            onAutomationParamSelected: _assignAutomationParam,
            onAutomateParameter: _automateParameter,
            onGetParamDescriptors: widget.bridge.getParamDescriptors,
            onMeterSubscriptionsChanged: _updateMeterSubscriptions,
            onCreateSamplerFromDroppedSample: _createSamplerFromDroppedSample,
            onAssignDroppedSampleToDevice: _assignDroppedSampleToDevice,
          )
        else if (_tab == _ShellTab.keys)
          LiveInstrumentPanel(
            bridge: widget.bridge,
            snapshot: snapshot,
            onRecordArmed: _setRecordArmed,
            recordWriteMode: _recordWriteMode,
            onRecordWriteModeChanged: _setRecordWriteMode,
          ),
      ],
    );
  }

  Widget _buildTabBody(ProjectSnapshot snapshot) {
    switch (_tab) {
      case _ShellTab.devices:
      case _ShellTab.keys:
        return _buildArrangementColumn(snapshot);
      case _ShellTab.mixer:
        return Column(
          children: [
            Expanded(child: _buildArrangementColumn(snapshot)),
            MixerView(
              snapshot: snapshot,
              liveMeters: _liveMeters,
              onTrackGainChanged: _setTrackGain,
              onTrackPanChanged: _setTrackPan,
              onTrackMuted: (trackId, muted) =>
                  _setTrackMuted(trackId: trackId, muted: muted),
              onTrackSoloed: (trackId, soloed) =>
                  _setTrackSoloed(trackId: trackId, soloed: soloed),
              onTrackSelected: _selectTrack,
              onMasterGainChanged: _setMasterGain,
            ),
          ],
        );
      case _ShellTab.library:
        return const SizedBox.shrink();
      case _ShellTab.settings:
        return SettingsScreen(
          onSaveProject: _saveProject,
          onLoadProject: _loadProject,
          onExportMix: _exportMix,
          loopEnabled: snapshot.loopEnabled,
          onLoopToggled: _setLoopEnabled,
          statusMessage: _saveStatus,
          errorMessage: _projectError,
        );
    }
  }

  Widget _buildMainColumn(ProjectSnapshot? snapshot) {
    if (!_bootstrapReady) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (snapshot != null)
          ListenableBuilder(
            listenable: Listenable.merge([
              _transport.playheadNotifier,
              _transport,
            ]),
            builder: (context, _) {
              final selectedTrack = _trackById(snapshot.selectedTrackId);
              return TransportBar.padded(
                context: context,
                bpm: snapshot.bpm,
                playheadBeats: _effectivePlayheadBeats,
                playing: _transport.playing,
                loopEnabled: snapshot.loopEnabled,
                loopRegionStartBeat: snapshot.loopRegionStartBeat,
                loopRegionEndBeat: snapshot.loopRegionEndBeat,
                recordArmed: snapshot.recordArmed,
                recordingActive: _anyRecordingActive,
                recordingStartBeat: _recordingStartBeat,
                recordingInputLevel: _audioRecordingInputLevel,
                recordingModeLabel: _recordingModeLabel,
                followPlayheadEnabled: _transport.followPlayheadEnabled,
                followPlayheadSuspended: _transport.followPlayheadSuspended,
                selectedTrackName: selectedTrack?.name,
                songEndBeat:
                    ArrangementTimelineMetrics.contentEndBeat(snapshot),
                onPlayRequested: _startPlay,
                onStopRequested: _stopPlay,
                onJumpToStart: _jumpToStart,
                onBpmChanged: _setBpm,
                onLoopToggled: _setLoopEnabled,
                onRecordArmedChanged: _setRecordArmed,
                onCancelRecording: _cancelAudioRecording,
                onFollowPlayheadToggled: _setFollowPlayheadEnabled,
                onExportMix: _exportMix,
                snapClipsEnabled: _snapClipsEnabled,
                snapGridResolution: _snapGridResolution,
                snapGridTriplet: _snapGridTriplet,
                onSnapClipsEnabledChanged: (enabled) {
                  setState(() => _snapClipsEnabled = enabled);
                },
                onSnapGridResolutionChanged: (resolution) {
                  setState(() => _snapGridResolution = resolution);
                },
                onSnapGridTripletChanged: (triplet) {
                  setState(() => _snapGridTriplet = triplet);
                },
                metronomeEnabled: _metronomeEnabled,
                metronomeLevel: _metronomeLevel,
                countInBars: _countInBars,
                onMetronomeChanged: _setMetronome,
              );
            },
          ),
        Expanded(
          child: snapshot == null
              ? const Center(child: CircularProgressIndicator())
              : _buildTabBody(snapshot),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final navGeometry = DawShellNavGeometry.of(context);
    final nav = DawShellNav(
      selectedIndex: _libraryOpen ? _ShellTab.library.index : _tab.index,
      geometry: navGeometry,
      onDestinationSelected: (index) => _onTabSelected(_ShellTab.values[index]),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      body: Stack(
        children: [
          Padding(
            padding: navGeometry.contentPadding,
            child: _buildMainColumn(snapshot),
          ),
          navGeometry.position(context: context, child: nav),
          if (_libraryOpen && snapshot != null)
            LibraryFlyInPanel(
              key: _libraryPanelKey,
              snapshot: snapshot,
              initialCategory: _libraryCategory,
              percussionOnly: _libraryDrumMachineId != null,
              presetDeviceId: _libraryPresetDeviceId,
              presetDeviceType: _libraryPresetDeviceType,
              onCaptureDevicePreset: _libraryPresetDeviceId == null
                  ? null
                  : () =>
                      widget.bridge.getDevicePreset(_libraryPresetDeviceId!),
              onClose: _closeLibrary,
              onPreviewAudio: _previewSample,
              onInsertAudio: _onLibraryInsertAudio,
              onImportAudio: _importSample,
              onMidiClipTap: _onLibraryMidiTap,
              onMidiPreviewTap: _onLibraryMidiPreviewTap,
              onAutomationTap: _onLibraryAutomationTap,
              onAutomationPreviewTap: _onLibraryAutomationPreviewTap,
              onPresetTap: _onLibraryPresetTap,
              onPresetPreviewTap: _onLibraryPresetPreviewTap,
              onWavetableTap: _onLibraryWavetableTap,
              onStopPreview: () {
                widget.bridge.stopPreview().catchError((Object _) {});
              },
            ),
        ],
      ),
    );
  }
}
