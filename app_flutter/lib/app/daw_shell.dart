import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/arrangement/arrangement_timeline_metrics.dart';
import '../app/app_info.dart';
import 'daw_shell_nav.dart';
import '../bridge/engine_bridge.dart';
import '../bridge/project_snapshot.dart';
import '../features/arrangement/arrangement_view.dart';
import '../features/content_library/library_catalog.dart';
import '../features/content_library/library_category.dart';
import '../features/content_library/library_fly_in_panel.dart';
import '../features/device_strip/device_strip.dart';
import '../features/device_strip/sampler_editor_screen.dart';
import '../features/mixer/mixer_view.dart';
import '../features/play/play_surface_screen.dart';
import '../features/piano_roll/piano_roll_screen.dart';
import '../features/sample_library/sample_library_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/transport/transport_bar.dart';

enum _ShellTab { arrangement, play, mixer, library, settings }

class DawShell extends StatefulWidget {
  const DawShell({
    super.key,
    required this.bridge,
  });

  final EngineBridge bridge;

  @override
  State<DawShell> createState() => _DawShellState();
}

class _DawShellState extends State<DawShell> {
  bool _playing = false;
  ProjectSnapshot? _snapshot;
  String? _saveStatus;
  String? _projectError;
  Timer? _playheadTimer;
  _ShellTab _tab = _ShellTab.arrangement;
  bool _libraryOpen = false;
  LibraryCategory _libraryCategory = LibraryCategory.audioClips;
  String? _librarySamplerDeviceId;
  final GlobalKey<LibraryFlyInPanelState> _libraryPanelKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _playheadTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      await widget.bridge.ping();
      final snapshot = await widget.bridge.createProject();
      if (!mounted) return;
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

  void _startPlayheadPolling() {
    _playheadTimer?.cancel();
    _playheadTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      try {
        final snapshot = await widget.bridge.getProjectSnapshot();
        if (!mounted) return;
        setState(() {
          _snapshot = snapshot;
          _playing = snapshot.playing;
        });
        if (!snapshot.playing) {
          _playheadTimer?.cancel();
        }
      } catch (_) {}
    });
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
      final snapshot = await widget.bridge.selectTrack(trackId);
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _addMidiClip(String trackId, double startBeat) async {
    try {
      await widget.bridge.selectTrack(trackId);
      final snapshot = await widget.bridge.createMidiClip(
        trackId: trackId,
        startBeat: startBeat,
      );
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

  Future<void> _openDeviceLibrary(DeviceSnapshot device) async {
    if (device.type != 'simple_sampler') return;
    setState(() {
      _libraryOpen = true;
      _libraryCategory = LibraryCategory.audioClips;
      _librarySamplerDeviceId = device.id;
    });
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

  void _onLibraryPresetTap(LibraryPresetItem item) {
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
      setState(() => _tab = _ShellTab.arrangement);
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

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => PianoRollScreen(
          bridge: widget.bridge,
          clip: clip,
          trackName: track!.name,
          bpm: _snapshot?.bpm ?? 120,
          onSnapshot: _refreshSnapshot,
        ),
      ),
    );

    try {
      final snapshot = await widget.bridge.getProjectSnapshot();
      await _refreshSnapshot(snapshot);
    } catch (_) {}
  }

  Future<void> _setBpm(int bpm) async {
    try {
      final snapshot = await widget.bridge.setBpm(bpm);
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setLoopEnabled(bool enabled) async {
    try {
      final snapshot = await widget.bridge.setLoopEnabled(enabled);
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _setLoopLengthBeats(double beats) async {
    try {
      final snapshot = await widget.bridge.setLoopLengthBeats(beats);
      await _refreshSnapshot(snapshot);
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
      final length = _snapshot?.loopLengthBeats ?? 16.0;
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
      final snapshot = await widget.bridge.setPlayheadBeats(beats);
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await widget.bridge.stop();
      _playheadTimer?.cancel();
    } else {
      await widget.bridge.play();
      _startPlayheadPolling();
    }
    if (!mounted) return;
    setState(() => _playing = !_playing);
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
    if (_tab == _ShellTab.play && tab != _ShellTab.play) {
      try {
        await widget.bridge.allNotesOff();
      } catch (_) {}
    }
    setState(() => _tab = tab);
    if (tab == _ShellTab.play) {
      try {
        await widget.bridge.enterPlayMode();
      } catch (_) {}
    }
  }

  Widget _buildTabBody(ProjectSnapshot snapshot) {
    switch (_tab) {
      case _ShellTab.arrangement:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ArrangementView(
                snapshot: snapshot,
                playheadBeats: snapshot.playheadBeats,
                playing: _playing,
                onPlayStop: _togglePlay,
                onPlayheadSeek: _setPlayheadBeats,
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
                onOpenPlay: (trackId) async {
                  await _selectTrack(trackId);
                  await _onTabSelected(_ShellTab.play);
                },
              ),
            ),
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
            ),
          ],
        );
      case _ShellTab.play:
        return PlaySurfaceScreen(
          bridge: widget.bridge,
          snapshot: snapshot,
          onSnapshot: _refreshSnapshot,
          playing: _playing,
          onPlayStop: _togglePlay,
          onPlayheadSeek: _setPlayheadBeats,
          onTrackSelected: _selectTrack,
          onAddMidiClip: _addMidiClip,
          onAddAudioClip: _addAudioClip,
          onClipTap: _openPianoRoll,
          onSampleClipTap: (_, __) {},
          onMoveClip: _moveClip,
          onDeleteClip: _confirmDeleteClip,
          onDuplicateClip: _duplicateClip,
        );
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
          TransportBar.padded(
            context: context,
            bpm: snapshot.bpm,
            playheadBeats: snapshot.playheadBeats,
            version: kAppVersion,
            loopEnabled: snapshot.loopEnabled,
            loopLengthBeats: snapshot.loopLengthBeats,
            onBpmChanged: _setBpm,
            onLoopToggled: _setLoopEnabled,
            onLoopLengthChanged: _setLoopLengthBeats,
            onExportMix: _exportMix,
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
              onPresetTap: _onLibraryPresetTap,
            ),
        ],
      ),
    );
  }
}
