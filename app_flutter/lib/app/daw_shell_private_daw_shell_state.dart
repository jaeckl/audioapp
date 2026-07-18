part of 'daw_shell.dart';

class _DawShellState extends State<DawShell>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final DawTransportController _transport;
  late final SnapshotStore _store;
  late final LiveMetersStore _liveMeters;
  final AppSettingsStore _appSettings = AppSettingsStore();
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
  bool _showWelcomeOnLaunch = true;
  late AudioEngineProfile _audioEngineProfile =
      widget.initialAudioEngineProfile;
  AudioEngineStatus? _audioEngineStatus;
  bool _inactiveStopInFlight = false;
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
    WidgetsBinding.instance.addObserver(this);
    _store = SnapshotStore(widget.bridge)..addListener(_onStoreChanged);
    _liveMeters = LiveMetersStore();
    _transport = DawTransportController(
      bridge: widget.bridge,
      vsync: this,
    );
    _meterSubscription = widget.bridge.meterStream.listen(_onMetersBatch);
    _midiNoteSubscription = widget.bridge.noteEvents.listen(_onLiveMidiNote);
    effectiveParameterMonitor.start(widget.bridge);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pendingWtPositionTimer?.cancel();
    _audioRecordingSnapshotTimer?.cancel();
    _store.removeListener(_onStoreChanged);
    _store.dispose();
    _liveMeters.dispose();
    _meterSubscription?.cancel();
    _midiNoteSubscription?.cancel();
    _transport.dispose();
    effectiveParameterMonitor.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_transport.syncTransportState(updatePlaying: true));
      return;
    }
    if (_inactiveStopInFlight) return;
    _inactiveStopInFlight = true;
    unawaited(_stopForInactiveApp());
  }

  Future<void> _stopForInactiveApp() async {
    try {
      // Update local transport state before platform calls: Flutter may be in
      // the process of detaching. Android repeats the stop synchronously from
      // Activity.onPause, so audio cannot outlive a stalled Flutter frame.
      await _transport.stopForLifecycle();
      _liveMeters.clear();
      await Future.wait<void>([
        widget.bridge.stopPreview().catchError((Object _) {}),
        widget.bridge.allNotesOff().catchError((Object _) {}),
      ]);
      if (_anyRecordingActive) {
        await _stopPlay();
      }
    } catch (_) {
      // Lifecycle cleanup is best effort while the platform view detaches.
    } finally {
      _inactiveStopInFlight = false;
    }
  }

  double get _effectivePlayheadBeats {
    if (_frozenArrangementPlayhead != null) {
      return _frozenArrangementPlayhead!;
    }
    return _transport.effectivePlayheadBeats;
  }

  /// Pushes the welcome/project-picker as a stacked full-screen route on top
  /// of the shell. It is not reachable from the bottom nav; it pops itself
  /// once a project becomes active (see [WelcomeHub]).
  /// Call a mutation via [invokeRaw], merge the delta into store.
  // ── Transport methods (delegated to controller) ──────────

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
