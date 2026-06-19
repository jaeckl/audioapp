import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../features/arrangement/arrangement_timeline_metrics.dart';
import '../app/app_info.dart';
import 'daw_shell_nav.dart';
import '../bridge/engine_bridge.dart';
import '../bridge/project_snapshot.dart';
import '../bridge/transport_state.dart';
import '../features/automation/automation_editor_screen.dart';
import '../features/arrangement/arrangement_view.dart';
import '../features/editor/timeline_marker_layer.dart';
import '../features/content_library/library_catalog.dart';
import '../features/content_library/library_category.dart';
import '../features/content_library/library_fly_in_panel.dart';
import '../features/device_strip/device_strip.dart';
import '../features/device_strip/sampler_editor_screen.dart';
import '../features/device_strip/subtractive_synth_editor_screen.dart';
import '../features/device_strip/subtractive_synth_presets.dart';
import '../features/mixer/mixer_view.dart';
import '../features/play/live_instrument_panel.dart';
import '../features/piano_roll/piano_roll_screen.dart';
import '../features/sample_library/sample_library_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/transport/transport_bar.dart';

enum _ShellTab { devices, keys, mixer, library, settings }

class DawShell extends StatefulWidget {
  const DawShell({
    super.key,
    required this.bridge,
  });

  final EngineBridge bridge;

  @override
  State<DawShell> createState() => _DawShellState();
}

class _DawShellState extends State<DawShell> with TickerProviderStateMixin {
  bool _playing = false;
  ProjectSnapshot? _snapshot;
  String? _saveStatus;
  String? _projectError;
  Ticker? _playheadTicker;
  Timer? _transportSyncTimer;
  final ValueNotifier<double> _playheadNotifier = ValueNotifier(0);
  double _syncPlayheadBeats = 0;
  DateTime _syncTime = DateTime.now();
  int _syncBpm = 120;
  bool _syncLoopEnabled = true;
  double _syncLoopRegionStart = 0;
  double _syncLoopRegionEnd = 16;
  bool _transportSyncInFlight = false;
  bool _transportSyncPending = false;
  DateTime _lastMeterRefresh = DateTime.fromMillisecondsSinceEpoch(0);
  _ShellTab _tab = _ShellTab.devices;
  bool _libraryOpen = false;
  LibraryCategory _libraryCategory = LibraryCategory.audioClips;
  String? _librarySamplerDeviceId;
  String? _automationLinkClipId;
  final GlobalKey<LibraryFlyInPanelState> _libraryPanelKey = GlobalKey();
  final TimelineViewportScrollController _arrangementScrollController =
      TimelineViewportScrollController();
  double? _frozenArrangementPlayhead;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _stopPlayheadAnimation();
    _playheadNotifier.dispose();
    super.dispose();
  }

  double _wrapPlayheadInLoop(double beats) {
    if (!_syncLoopEnabled) {
      return beats;
    }
    final len = _syncLoopRegionEnd - _syncLoopRegionStart;
    if (len <= 0) {
      return beats;
    }
    if (beats >= _syncLoopRegionEnd) {
      return _syncLoopRegionStart + (beats - _syncLoopRegionStart) % len;
    }
    return beats;
  }

  double get _effectivePlayheadBeats {
    if (_frozenArrangementPlayhead != null) {
      return _frozenArrangementPlayhead!;
    }
    return _playheadNotifier.value;
  }

  void _publishPlayhead(double beats) {
    _playheadNotifier.value = beats;
  }

  Future<double> _beginClipEditorSession() async {
    if (_playing) {
      await widget.bridge.stop();
      _stopPlayheadAnimation();
      if (mounted) {
        setState(() => _playing = false);
      }
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
    await _syncTransportState();
  }

  void _stopPlayheadAnimation() {
    _playheadTicker?.stop();
    _playheadTicker?.dispose();
    _playheadTicker = null;
    _transportSyncTimer?.cancel();
    _transportSyncTimer = null;
  }

  void _anchorTransport(TransportState transport) {
    _syncPlayheadBeats = transport.playheadBeats;
    _syncTime = DateTime.now();
    _syncBpm = transport.bpm;
    _syncLoopEnabled = transport.loopEnabled;
    _syncLoopRegionStart = transport.loopRegionStartBeat;
    _syncLoopRegionEnd = transport.loopRegionEndBeat;
  }

  void _publishSyncedPlayhead({TransportState? transport}) {
    if (_playing) {
      _publishPlayhead(_extrapolatePlayheadBeats());
      return;
    }
    if (transport != null) {
      _publishPlayhead(transport.playheadBeats);
    }
  }

  double _extrapolatePlayheadBeats() {
    final elapsed = DateTime.now().difference(_syncTime).inMicroseconds / 1000000.0;
    var beats = _syncPlayheadBeats + elapsed * (_syncBpm / 60.0);
    beats = _wrapPlayheadInLoop(beats);
    return beats;
  }

  Future<void> _syncTransportState({bool updatePlaying = false}) async {
    if (_frozenArrangementPlayhead != null) return;
    if (_transportSyncInFlight) {
      _transportSyncPending = true;
      return;
    }
    _transportSyncInFlight = true;
    try {
      final transport = await widget.bridge.getTransportState();
      if (!mounted) return;
      _anchorTransport(transport);
      if (updatePlaying && !transport.playing) {
        _playing = false;
        _stopPlayheadAnimation();
      }
      if (updatePlaying) {
        setState(() => _playing = transport.playing);
      }
      _publishSyncedPlayhead(transport: transport);
      if (_playing && _snapshot != null) {
        final now = DateTime.now();
        if (now.difference(_lastMeterRefresh).inMilliseconds >= 500) {
          _lastMeterRefresh = now;
          unawaited(_refreshLiveMeters());
        }
      }
    } catch (_) {
    } finally {
      _transportSyncInFlight = false;
      if (_transportSyncPending) {
        _transportSyncPending = false;
        unawaited(_syncTransportState(updatePlaying: updatePlaying));
      }
    }
  }

  void _startPlayheadAnimation() {
    _stopPlayheadAnimation();
    _playheadTicker = createTicker((_) {
      if (!mounted || !_playing) return;
      _publishPlayhead(_extrapolatePlayheadBeats());
    })..start();
    _transportSyncTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      unawaited(_syncTransportState());
    });
    unawaited(_syncTransportState());
  }

  void _syncTransportAnchorFromSnapshot(ProjectSnapshot snapshot) {
    _syncBpm = snapshot.bpm;
    _syncLoopEnabled = snapshot.loopEnabled;
    _syncLoopRegionStart = snapshot.loopRegionStartBeat;
    _syncLoopRegionEnd = snapshot.loopRegionEndBeat;
    if (!_playing) {
      _syncPlayheadBeats = snapshot.playheadBeats;
      _publishPlayhead(snapshot.playheadBeats);
    }
  }

  Future<void> _bootstrap() async {
    try {
      await widget.bridge.ping();
      await widget.bridge.createProject();
      final snapshot = await widget.bridge.addTrack(name: 'Track 1');
      await widget.bridge.enterPlayMode();
      if (!mounted) return;
      _syncTransportAnchorFromSnapshot(snapshot);
      setState(() => _snapshot = snapshot);
    } on MissingPluginException {
      if (!mounted) return;
      setState(() => _projectError = 'Engine: native bridge unavailable');
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _refreshSnapshot(ProjectSnapshot snapshot) async {
    if (!mounted) return;
    setState(() => _snapshot = snapshot);
  }

  Future<void> _refreshLiveMeters() async {
    if (!_playing || _snapshot == null) return;
    try {
      final fresh = await widget.bridge.getProjectSnapshot();
      if (!mounted || _snapshot == null) return;
      setState(() => _snapshot = _snapshot!.withMergedDeviceMeters(fresh));
    } catch (_) {}
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

  Future<void> _selectTrack(String trackId) async {
    try {
      var snapshot = await widget.bridge.selectTrack(trackId);
      snapshot = await _syncArmWithSelection(snapshot);
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<ProjectSnapshot> _syncArmWithSelection(ProjectSnapshot snapshot) async {
    final hasTrack = snapshot.selectedTrackId.isNotEmpty;
    if (_tab == _ShellTab.keys && hasTrack && !snapshot.recordArmed) {
      return widget.bridge.setRecordArmed(true);
    }
    if (_tab == _ShellTab.devices && snapshot.recordArmed) {
      return widget.bridge.setRecordArmed(false);
    }
    return snapshot;
  }

  Future<void> _syncLiveInputForTab(_ShellTab tab) async {
    try {
      if (tab == _ShellTab.keys) {
        await widget.bridge.enterPlayMode();
        if (_snapshot != null) {
          final synced = await _syncArmWithSelection(_snapshot!);
          await _refreshSnapshot(synced);
        }
      } else {
        await widget.bridge.allNotesOff();
        if (_snapshot?.recordArmed == true) {
          final updated = await widget.bridge.setRecordArmed(false);
          await _refreshSnapshot(updated);
        }
      }
    } catch (_) {}
  }

  Future<void> _addMidiClip(String trackId, double startBeat) async {
    try {
      await widget.bridge.selectTrack(trackId);
      final before = _trackById(trackId);
      final beforeClipCount = before?.midiClips.length ?? 0;
      var snapshot = await widget.bridge.createMidiClip(
        trackId: trackId,
        startBeat: startBeat,
      );
      final track = snapshot.tracks.firstWhere((t) => t.id == trackId);
      if (track.midiClips.length > beforeClipCount) {
        final clip = track.midiClips.last;
        final defaultPitch = _defaultMidiPitchForTrack(track);
        if (defaultPitch != null) {
          snapshot = await widget.bridge.setMidiClipNotes(
            clipId: clip.id,
            notes: [
              MidiNoteSnapshot(
                pitch: defaultPitch,
                startBeat: 0,
                durationBeats: 1,
                velocity: 100,
              ),
            ],
          );
        }
      }
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  int? _defaultMidiPitchForTrack(TrackSnapshot track) {
    for (final device in track.visibleDevices) {
      switch (device.type) {
        case 'kick_generator':
          return 36;
        case 'snare_generator':
          return 38;
        case 'clap_generator':
          return 39;
        case 'cymbal_generator':
          return 42;
        case 'crash_generator':
          return 49;
      }
    }
    return null;
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
    try {
      await widget.bridge.selectTrack(trackId);
      final beforeCount = _trackById(trackId)?.automationClips.length ?? 0;
      var snapshot = await widget.bridge.createAutomationClip(
        trackId: trackId,
        startBeat: startBeat,
      );
      final track = snapshot.tracks.firstWhere((t) => t.id == trackId);
      if (track.automationClips.length <= beforeCount) {
        await _refreshSnapshot(snapshot);
        return;
      }
      final created = track.automationClips.last;
      if (deviceId != null && paramId != null) {
        snapshot = await widget.bridge.assignAutomationTarget(
          clipId: created.id,
          deviceId: deviceId,
          paramId: paramId,
        );
      } else {
        setState(() => _automationLinkClipId = created.id);
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
      'filterCutoff' => device.filterCutoff.clamp(0.0, 1.0),
      'filterQ' => device.filterQ.clamp(0.0, 1.0),
      'attack' => device.attack.clamp(0.0, 1.0),
      'decay' => device.decay.clamp(0.0, 1.0),
      'sustain' => device.sustain.clamp(0.0, 1.0),
      'release' => device.release.clamp(0.0, 1.0),
      'frequency' => ((device.frequencyHz - 110.0) / 770.0).clamp(0.0, 1.0),
      _ => 0.5,
    };
  }

  Future<void> _automateParameter(String deviceId, String paramId) async {
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
      final beforeCount = track.automationClips.length;
      var snapshot = await widget.bridge.createAutomationClip(
        trackId: track.id,
        startBeat: startBeat,
        lengthBeats: lengthBeats,
      );
      final updatedTrack = snapshot.tracks.firstWhere((t) => t.id == track.id);
      if (updatedTrack.automationClips.length <= beforeCount) {
        await _refreshSnapshot(snapshot);
        return;
      }
      final created = updatedTrack.automationClips.last;
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
      for (final t in fresh.tracks) {
        if (t.id != trackId) continue;
        for (final candidate in t.automationClips) {
          if (candidate.id == clip.id) {
            editorClip = candidate;
            break;
          }
        }
        break;
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

  Future<void> _setSamplerParameter(String deviceId, String parameterId, double value) async {
    try {
      final snapshot = await widget.bridge.setDeviceParameter(
        deviceId: deviceId,
        parameterId: parameterId,
        value: value,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
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
      ProjectSnapshot result;
      switch (method) {
        case 'createLfo':
          result = await widget.bridge.createLfo();
          break;
        case 'removeLfo':
          result = await widget.bridge.removeLfo(
            (args['lfoId'] as num).toInt(),
          );
          break;
        case 'updateLfoParam':
          result = await widget.bridge.updateLfoParam(
            lfoId: (args['lfoId'] as num).toInt(),
            param: args['param'] as String,
            value: (args['value'] as num).toDouble(),
          );
          break;
        case 'assignModulation':
          result = await widget.bridge.assignModulation(
            lfoId: (args['lfoId'] as num).toInt(),
            deviceId: args['deviceId'] as String,
            paramId: args['paramId'] as String,
            amount: (args['amount'] as num).toDouble(),
          );
          break;
        case 'removeModulation':
          result = await widget.bridge.removeModulation(
            lfoId: (args['lfoId'] as num).toInt(),
            paramId: args['paramId'] as String,
          );
          break;
        default:
          throw Exception('Unknown modulation bridge method: $method');
      }
      await _refreshSnapshot(result);
      return result;
    } catch (e) {
      if (!mounted) return _snapshot ?? ProjectSnapshot(
        bpm: 120,
        selectedTrackId: '',
        playheadBeats: 0,
        playing: false,
        loopEnabled: true,
        recordArmed: false,
        master: const MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1.0),
        samples: [],
        tracks: [],
        lfos: [],
        modEdges: [],
      );
      rethrow;
    }
  }

  Future<void> _openDeviceLibrary(DeviceSnapshot device) async {
    if (device.type == 'simple_sampler') {
      setState(() {
        _libraryOpen = true;
        _libraryCategory = LibraryCategory.audioClips;
        _librarySamplerDeviceId = device.id;
      });
      return;
    }
    if (device.type == 'subtractive_synth') {
      setState(() {
        _libraryOpen = true;
        _libraryCategory = LibraryCategory.devicePresets;
        _librarySamplerDeviceId = null;
      });
    }
  }

  void _closeLibrary() {
    setState(() {
      _libraryOpen = false;
      _librarySamplerDeviceId = null;
    });
  }

  Future<void> _openLibrary({LibraryCategory category = LibraryCategory.audioClips}) async {
    setState(() {
      _libraryOpen = true;
      _libraryCategory = category;
      _librarySamplerDeviceId = null;
    });
  }

  Future<void> _onLibraryInsertAudio(SampleLibraryEntrySnapshot sample) async {
    final deviceId = _librarySamplerDeviceId;
    if (deviceId != null) {
      await _assignSamplerSample(deviceId, sample.id);
      await _libraryPanelKey.currentState?.close();
      return;
    }
    await _insertSample(sample);
  }

  Future<void> _onLibraryMidiTap(LibraryMidiItem item) async {
    await _openPianoRoll(item.trackId, item.clip);
    await _libraryPanelKey.currentState?.close();
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
    final synth = _snapshot?.selectedTrack?.subtractiveSynthDevice;
    if (item.deviceType == 'subtractive_synth') {
      if (synth == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a track with a Subtractive Synth first')),
        );
        return;
      }
      final params = SubtractiveSynthPresets.presets[item.id];
      if (params == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown preset "${item.title}"')),
        );
        return;
      }
      for (final entry in params.entries) {
        await _setSamplerParameter(synth.id, entry.key, entry.value);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded preset "${item.title}"')),
      );
      await _libraryPanelKey.currentState?.close();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preset "${item.title}" — coming soon')),
    );
  }

  Future<void> _setSamplerGain(String deviceId, double value) async {
    await _setSamplerParameter(deviceId, 'gain', value);
  }

  Future<void> _assignSamplerSample(String deviceId, String sampleId) async {
    try {
      final snapshot = await widget.bridge.setDeviceStringParameter(
        deviceId: deviceId,
        parameterId: 'sampleId',
        value: sampleId,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  SampleLibraryEntrySnapshot? _sampleForDevice(DeviceSnapshot device) {
    if (device.sampleId.isEmpty) {
      return null;
    }
    for (final sample in _snapshot?.samples ?? const <SampleLibraryEntrySnapshot>[]) {
      if (sample.id == device.sampleId) {
        return sample;
      }
    }
    return null;
  }

  Future<void> _openSamplerEditor(TrackSnapshot track, DeviceSnapshot device) async {
    if (device.type == 'subtractive_synth') {
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
    } else if (device.type == 'simple_sampler') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => SamplerEditorScreen(
            trackName: track.name,
            device: device,
            sample: _sampleForDevice(device),
            bpm: _snapshot?.bpm ?? 120,
            onParameterChanged: (parameterId, value) =>
                _setSamplerParameter(device.id, parameterId, value),
            onLoadSample: () => _pickSamplerSample(device.id),
          ),
        ),
      );
    } else {
      return;
    }

    try {
      final snapshot = await widget.bridge.getProjectSnapshot();
      await _refreshSnapshot(snapshot);
    } catch (_) {}
  }

  Future<SampleLibraryEntrySnapshot?> _pickSamplerSample(String deviceId) async {
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
    if (sample == null) return null;
    await _assignSamplerSample(deviceId, sample.id);
    return sample;
  }

  Future<void> _setFrequency(String deviceId, double value) async {
    try {
      final snapshot = await widget.bridge.setDeviceParameter(
        deviceId: deviceId,
        parameterId: 'frequency',
        value: value,
      );
      await _refreshSnapshot(snapshot);
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
    try {
      final snapshot = await widget.bridge.setDeviceParameter(
        deviceId: deviceId,
        parameterId: 'gain',
        value: value,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setMasterGain(double value) async {
    try {
      final snapshot = await widget.bridge.setMasterGain(value);
      await _refreshSnapshot(snapshot);
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
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _projectError = '${e.code}: ${e.message ?? "save failed"}');
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
      await _refreshSnapshot(snapshot);
      if (!mounted) return;
      setState(() {
        _saveStatus = 'Loaded project';
        _projectError = null;
        _playing = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _projectError = '${e.code}: ${e.message ?? "load failed"}');
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

  Future<void> _openPianoRoll(String trackId, MidiClipSnapshot clip) async {
    TrackSnapshot? track;
    for (final t in _snapshot?.tracks ?? const <TrackSnapshot>[]) {
      if (t.id == trackId) {
        track = t;
        break;
      }
    }
    if (track == null) return;

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

  Future<void> _setBpm(int bpm) async {
    try {
      final snapshot = await widget.bridge.setBpm(bpm);
      await _refreshSnapshot(snapshot);
      if (_playing) {
        await _syncTransportState();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setLoopEnabled(bool enabled) async {
    try {
      final snapshot = await widget.bridge.setLoopEnabled(enabled);
      await _refreshSnapshot(snapshot);
      _syncTransportAnchorFromSnapshot(snapshot);
      if (_playing) {
        await _syncTransportState();
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
      final snapshot = await widget.bridge.setLoopRegion(
        startBeat: startBeat,
        endBeat: endBeat,
      );
      await _refreshSnapshot(snapshot);
      _syncTransportAnchorFromSnapshot(snapshot);
      if (_playing) {
        await _syncTransportState();
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
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

  Future<void> _confirmDeleteClip(String clipId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete clip?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final snapshot = await widget.bridge.deleteClip(clipId);
      await _refreshSnapshot(snapshot);
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

  Future<void> _setPlayheadBeats(double beats) async {
    try {
      if (_playing) {
        _syncPlayheadBeats = beats;
        _syncTime = DateTime.now();
        _publishPlayhead(beats);
      }
      final snapshot = await widget.bridge.setPlayheadBeats(beats);
      await _refreshSnapshot(snapshot);
      if (_playing) {
        await _syncTransportState();
      } else if (mounted) {
        _syncPlayheadBeats = snapshot.playheadBeats;
        _publishPlayhead(snapshot.playheadBeats);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  bool _transportCommandInFlight = false;

  Future<void> _startPlay() async {
    if (_playing || _transportCommandInFlight) return;
    _transportCommandInFlight = true;
    try {
      final beats = _effectivePlayheadBeats;
      _syncPlayheadBeats = beats;
      _syncTime = DateTime.now();
      _syncBpm = _snapshot?.bpm ?? _syncBpm;
      _publishPlayhead(beats);
      await widget.bridge.setPlayheadBeats(beats);
      await widget.bridge.play();
      if (!mounted) return;
      setState(() => _playing = true);
      _startPlayheadAnimation();
      _arrangementScrollController.revealPlayheadAtViewportOrigin(beats);
    } finally {
      _transportCommandInFlight = false;
    }
  }

  Future<void> _stopPlay() async {
    if (!_playing || _transportCommandInFlight) return;
    _transportCommandInFlight = true;
    try {
      await widget.bridge.stop();
      _stopPlayheadAnimation();
      try {
        final transport = await widget.bridge.getTransportState();
        if (mounted) {
          _anchorTransport(transport);
          _publishPlayhead(transport.playheadBeats);
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() => _playing = false);
    } finally {
      _transportCommandInFlight = false;
    }
  }

  Future<void> _onTabSelected(_ShellTab tab) async {
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
    await _syncLiveInputForTab(tab);
  }

  Widget _buildArrangementColumn(ProjectSnapshot snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListenableBuilder(
            listenable: _playheadNotifier,
            builder: (context, _) => ArrangementView(
              timelineScrollController: _arrangementScrollController,
              snapshot: snapshot,
              playheadBeats: _effectivePlayheadBeats,
              playing: _playing,
              onPlayRequested: _startPlay,
              onStopRequested: _stopPlay,
              onPlayheadSeek: _setPlayheadBeats,
              onLoopRegionChanged: _setLoopRegion,
              onTrackSelected: _selectTrack,
              onAddTrack: _addTrack,
              onAddMidiClip: _addMidiClip,
              onAddAudioClip: _addAudioClip,
              onClipTap: _openPianoRoll,
              onSampleClipTap: (_, __) {},
              onMoveClip: _moveClip,
              onDeleteTrack: _confirmDeleteTrack,
              onDeleteClip: _confirmDeleteClip,
              onDuplicateClip: _duplicateClip,
              onAddAutomationClip: _addAutomationClip,
              automationLinkClipId: _automationLinkClipId,
              onAutomationLinkToggle: _toggleAutomationLink,
              onAutomationClipDoubleTap: _openAutomationCurveEditor,
            ),
          ),
        ),
        if (_tab == _ShellTab.devices)
          DeviceStrip(
            snapshot: snapshot,
            track: snapshot.selectedTrack,
            samples: snapshot.samples,
            playing: _playing,
            onSamplerParameterChanged: _setSamplerParameter,
            onAssignSamplerSample: _assignSamplerSample,
            onOpenSamplerEditor: _openSamplerEditor,
            onPreviewSample: _previewSample,
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
            onBypassToggle: (deviceId, bypassed) => _setDeviceBypass(deviceId, bypassed),
            onOpenDeviceLibrary: _openDeviceLibrary,
            onModulationBridgeCall: _modulationBridgeCall,
            automationLinkClipId: _automationLinkClipId,
            onAutomationParamSelected: _assignAutomationParam,
            onAutomateParameter: _automateParameter,
          )
        else
          LiveInstrumentPanel(
            bridge: widget.bridge,
            snapshot: snapshot,
            onSnapshot: _refreshSnapshot,
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
        return MixerView(
          snapshot: snapshot,
          onTrackGainChanged: _setTrackGain,
          onMasterGainChanged: _setMasterGain,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (snapshot != null)
          ListenableBuilder(
            listenable: _playheadNotifier,
            builder: (context, _) => TransportBar.padded(
              context: context,
              bpm: snapshot.bpm,
              playheadBeats: _effectivePlayheadBeats,
              version: kAppVersion,
              loopEnabled: snapshot.loopEnabled,
              onBpmChanged: _setBpm,
              onLoopToggled: _setLoopEnabled,
              onExportMix: _exportMix,
            ),
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
              onClose: _closeLibrary,
              onPreviewAudio: _previewSample,
              onInsertAudio: _onLibraryInsertAudio,
              onImportAudio: _importSample,
              onMidiClipTap: _onLibraryMidiTap,
              onAutomationTap: _onLibraryAutomationTap,
              onPresetTap: _onLibraryPresetTap,
            ),
        ],
      ),
    );
  }
}
