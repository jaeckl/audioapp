import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bridge/live_meters_dto.dart';
import '../features/arrangement/arrangement_timeline_metrics.dart';
import '../app/app_info.dart';
import 'daw_shell_nav.dart';
import 'daw_transport_controller.dart';
import '../bridge/engine_bridge.dart';
import '../bridge/project_snapshot.dart';
import '../features/automation/automation_editor_screen.dart';
import '../features/arrangement/arrangement_view.dart';
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
  late final DawTransportController _transport;
  ProjectSnapshot? _snapshot;
  String? _saveStatus;
  String? _projectError;
  _ShellTab _tab = _ShellTab.devices;
  bool _libraryOpen = false;
  LibraryCategory _libraryCategory = LibraryCategory.audioClips;
  String? _librarySamplerDeviceId;
  String? _automationLinkClipId;
  final GlobalKey<LibraryFlyInPanelState> _libraryPanelKey = GlobalKey();
  final TimelineViewportScrollController _arrangementScrollController =
      TimelineViewportScrollController();
  double? _frozenArrangementPlayhead;
  StreamSubscription<LiveMetersBatch>? _meterSubscription;

  @override
  void initState() {
    super.initState();
    _transport = DawTransportController(
      bridge: widget.bridge,
      vsync: this,
    );
    _meterSubscription = widget.bridge.meterStream.listen(_onMetersBatch);
    _bootstrap();
  }

  @override
  void dispose() {
    _meterSubscription?.cancel();
    _transport.dispose();
    super.dispose();
  }

  void _onMetersBatch(LiveMetersBatch batch) {
    if (!mounted || _snapshot == null || !_transport.playing) return;
    setState(() {
      _snapshot = _snapshot!.withMergedMeters(batch);
    });
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
      await widget.bridge.createProject();
      final snapshot = await widget.bridge.addTrack(name: 'Track 1');
      await widget.bridge.enterPlayMode();
      if (!mounted) return;
      _transport.syncTransportAnchorFromSnapshot(
        snapshot.bpm,
        snapshot.loopEnabled,
        snapshot.loopRegionStartBeat,
        snapshot.loopRegionEndBeat,
        snapshot.playheadBeats,
      );
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
      final beforeIds = _snapshot?.automationClips.map((c) => c.id).toSet() ?? <String>{};
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
      }).clamp(0.0, 1.0),
      'filterQ' => (switch (device) {
        SubtractiveSynthDeviceSnapshot d => d.filterQ,
        PhaseModSynthDeviceSnapshot d => d.filterQ,
        SamplerDeviceSnapshot d => d.filterQ,
        _ => 0.5,
      }).clamp(0.0, 1.0),
      'attack' => (switch (device) {
        SubtractiveSynthDeviceSnapshot d => d.attack,
        PhaseModSynthDeviceSnapshot d => d.attack,
        SamplerDeviceSnapshot d => d.attack,
        BassSynthDeviceSnapshot d => d.attack,
        _ => 0.01,
      }).clamp(0.0, 1.0),
      'decay' => (switch (device) {
        SubtractiveSynthDeviceSnapshot d => d.decay,
        PhaseModSynthDeviceSnapshot d => d.decay,
        SamplerDeviceSnapshot d => d.decay,
        _ => 0.3,
      }).clamp(0.0, 1.0),
      'sustain' => (switch (device) {
        SubtractiveSynthDeviceSnapshot d => d.sustain,
        PhaseModSynthDeviceSnapshot d => d.sustain,
        SamplerDeviceSnapshot d => d.sustain,
        BassSynthDeviceSnapshot d => d.sustain,
        _ => 0.7,
      }).clamp(0.0, 1.0),
      'release' => (switch (device) {
        SubtractiveSynthDeviceSnapshot d => d.release,
        PhaseModSynthDeviceSnapshot d => d.release,
        SamplerDeviceSnapshot d => d.release,
        BassSynthDeviceSnapshot d => d.release,
        _ => 0.4,
      }).clamp(0.0, 1.0),
      'frequency' => (switch (device) {
        OscillatorDeviceSnapshot d => ((d.frequencyHz - 110.0) / 770.0),
        _ => 0.5,
      }).clamp(0.0, 1.0),
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
      final beforeIds = _snapshot?.automationClips.map((c) => c.id).toSet() ?? <String>{};
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
          result = await widget.bridge.createLfo(
            modulatorType: (args['modulatorType'] as num?)?.toInt() ?? 0,
          );
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
        case 'batchUpdateLfoParams':
          result = await widget.bridge.batchUpdateLfoParams(
            lfoId: (args['lfoId'] as num).toInt(),
            params: (args['params'] as List<dynamic>).cast<Map<String, dynamic>>(),
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
    // Stop any active preview (preset/midi/sampler) so closing the library
    // also halts the audio and the visual playhead ticker — not just the
    // panel UI.
    widget.bridge.stopPreview().catchError((Object _) {});
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
        final updatedTrack = snapshot.tracks.firstWhere((t) => t.id == track.id);
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

  Future<void> _onLibraryAutomationPreviewTap(LibraryAutomationItem item) async {
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
          final updatedTrack = snapshot.tracks.firstWhere((t) => t.id == track.id);
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

  Future<void> _onLibraryPresetPreviewTap(LibraryPresetItem item, {double startBeat = 0.0, bool loop = true}) async {
    final preset = DevicePresetStore.find(item.deviceType, item.id);
    debugPrint('[library preset] item.id=${item.id} deviceType=${item.deviceType} startBeat=$startBeat loop=$loop presetFound=${preset != null}');
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
      notes.add(const MidiNoteSnapshot(pitch: 48, startBeat: 0.0, durationBeats: 1.0, velocity: 90.0));
      notes.add(const MidiNoteSnapshot(pitch: 52, startBeat: 1.0, durationBeats: 1.0, velocity: 90.0));
      notes.add(const MidiNoteSnapshot(pitch: 55, startBeat: 2.0, durationBeats: 1.0, velocity: 90.0));
      notes.add(const MidiNoteSnapshot(pitch: 60, startBeat: 3.0, durationBeats: 1.0, velocity: 90.0));
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _openSamplerEditor(TrackSnapshot track, DeviceSnapshot device) async {
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
      _transport.syncTransportAnchorFromSnapshot(
        snapshot.bpm,
        snapshot.loopEnabled,
        snapshot.loopRegionStartBeat,
        snapshot.loopRegionEndBeat,
        snapshot.playheadBeats,
      );
      setState(() {
        _saveStatus = 'Loaded project';
        _projectError = null;
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

  Future<void> _previewSamplerNote(int rootPitch) async {
    try {
      await widget.bridge.noteOn(pitch: rootPitch, velocity: 100);
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

  // ── Transport methods (delegated to controller) ──────────

  Future<void> _setBpm(int bpm) async {
    try {
      final snapshot = await widget.bridge.setBpm(bpm);
      await _refreshSnapshot(snapshot);
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
      final snapshot = await widget.bridge.setLoopEnabled(enabled);
      await _refreshSnapshot(snapshot);
      _transport.syncTransportAnchorFromSnapshot(
        snapshot.bpm,
        snapshot.loopEnabled,
        snapshot.loopRegionStartBeat,
        snapshot.loopRegionEndBeat,
        snapshot.playheadBeats,
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
      final snapshot = await widget.bridge.setLoopRegion(
        startBeat: startBeat,
        endBeat: endBeat,
      );
      await _refreshSnapshot(snapshot);
      _transport.syncTransportAnchorFromSnapshot(
        snapshot.bpm,
        snapshot.loopEnabled,
        snapshot.loopRegionStartBeat,
        snapshot.loopRegionEndBeat,
        snapshot.playheadBeats,
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final snapshot = await widget.bridge.removeDeviceFromTrack(deviceId: device.id);
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

  Future<void> _setPlayheadBeats(double beats) async {
    try {
      await _transport.setPlayheadBeats(beats);
      final snapshot = await widget.bridge.getProjectSnapshot();
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _startPlay() async {
    final beats = _effectivePlayheadBeats;
    await _transport.startPlay(beats);
    _arrangementScrollController.catchUpPlayheadOnPlay(beats);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _stopPlay() async {
    await _transport.stopPlay();
    if (mounted) {
      setState(() {});
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
          child: ArrangementView(
            key: const ValueKey('daw-arrangement'),
            timelineScrollController: _arrangementScrollController,
            followPlayheadEnabled: _transport.followPlayheadEnabled,
            onFollowSuspended: _onFollowSuspended,
            onFollowResumed: _onFollowResumed,
            playheadListenable: _transport.playheadNotifier,
            snapshot: snapshot,
            playheadBeats: _effectivePlayheadBeats,
            playing: _transport.playing,
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
            onResizeClipCommit: _resizeClip,
            onDeleteTrack: _confirmDeleteTrack,
            onDeleteClip: _confirmDeleteClip,
            onDuplicateClip: _duplicateClip,
            onAddAutomationClip: _addAutomationClip,
            automationLinkClipId: _automationLinkClipId,
            onAutomationLinkToggle: _toggleAutomationLink,
            onAutomationClipDoubleTap: _openAutomationCurveEditor,
          ),
        ),
        if (_tab == _ShellTab.devices)
          DeviceStrip(
            snapshot: snapshot,
            track: snapshot.selectedTrack,
            samples: snapshot.samples,
            playing: _transport.playing,
            playheadBeatListenable: _transport.playheadNotifier,
            onSamplerParameterChanged: _setSamplerParameter,
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
            onBypassToggle: (deviceId, bypassed) => _setDeviceBypass(deviceId, bypassed),
            onRemoveDevice: _confirmRemoveDevice,
            onOpenDeviceLibrary: _openDeviceLibrary,
            onModulationBridgeCall: _modulationBridgeCall,
            automationLinkClipId: _automationLinkClipId,
            onAutomationParamSelected: _assignAutomationParam,
            onAutomateParameter: _automateParameter,
            onGetParamDescriptors: widget.bridge.getParamDescriptors,
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
            listenable: _transport.playheadNotifier,
            builder: (context, _) => TransportBar.padded(
              context: context,
              bpm: snapshot.bpm,
              playheadBeats: _effectivePlayheadBeats,
              version: kAppVersion,
              loopEnabled: snapshot.loopEnabled,
              followPlayheadEnabled: _transport.followPlayheadEnabled,
              followPlayheadSuspended: _transport.followPlayheadSuspended,
              onBpmChanged: _setBpm,
              onLoopToggled: _setLoopEnabled,
              onFollowPlayheadToggled: _setFollowPlayheadEnabled,
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
              onMidiPreviewTap: _onLibraryMidiPreviewTap,
              onAutomationTap: _onLibraryAutomationTap,
              onAutomationPreviewTap: _onLibraryAutomationPreviewTap,
              onPresetTap: _onLibraryPresetTap,
              onPresetPreviewTap: _onLibraryPresetPreviewTap,
              onStopPreview: () {
                widget.bridge.stopPreview().catchError((Object _) {});
              },
            ),
        ],
      ),
    );
  }
}