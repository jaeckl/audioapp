import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_info.dart';
import '../bridge/engine_bridge.dart';
import '../bridge/project_snapshot.dart';
import '../features/arrangement/arrangement_view.dart';
import '../features/device_strip/device_strip.dart';
import '../features/mixer/mixer_view.dart';
import '../features/piano_roll/piano_roll_screen.dart';
import '../features/sample_library/sample_library_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/transport/transport_bar.dart';

enum _ShellTab { arrangement, mixer, library, settings }

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

  Future<void> _addMidiClip(String trackId) async {
    try {
      await widget.bridge.selectTrack(trackId);
      final snapshot = await widget.bridge.createMidiClip(trackId: trackId);
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }

  Future<void> _addAudioClip(String trackId) async {
    final samples = _snapshot?.samples ?? const <SampleLibraryEntrySnapshot>[];
    if (samples.isEmpty) {
      await _selectTrack(trackId);
      if (!mounted) return;
      setState(() => _tab = _ShellTab.library);
      return;
    }

    final sample = await showModalBottomSheet<SampleLibraryEntrySnapshot>(
      context: context,
      backgroundColor: const Color(0xFF1A1A22),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final entry in samples)
              ListTile(
                leading: const Icon(Icons.library_music_outlined),
                title: Text(entry.name),
                onTap: () => Navigator.pop(context, entry),
              ),
          ],
        ),
      ),
    );
    if (sample == null) return;

    try {
      await widget.bridge.selectTrack(trackId);
      final updated = await widget.bridge.createSampleClip(
        trackId: trackId,
        sampleId: sample.id,
      );
      await _refreshSnapshot(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
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
              ),
            ),
            DeviceStrip(
              track: snapshot.selectedTrack,
              onFrequencyChanged: _setFrequency,
            ),
          ],
        );
      case _ShellTab.mixer:
        return MixerView(
          snapshot: snapshot,
          onTrackGainChanged: _setTrackGain,
          onMasterGainChanged: _setMasterGain,
        );
      case _ShellTab.library:
        return SampleLibraryScreen(
          embedded: true,
          samples: snapshot.samples,
          onPreview: _previewSample,
          onInsert: _insertSample,
          onImport: _importSample,
        );
      case _ShellTab.settings:
        return SettingsScreen(
          onSaveProject: _saveProject,
          onLoadProject: _loadProject,
          statusMessage: _saveStatus,
          errorMessage: _projectError,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (snapshot != null)
            TransportBar.padded(
              context: context,
              bpm: snapshot.bpm,
              version: kAppVersion,
            ),
          Expanded(
            child: snapshot == null
                ? const Center(child: CircularProgressIndicator())
                : _buildTabBody(snapshot),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF121218),
        indicatorColor: const Color(0xFF2D2D3A),
        selectedIndex: _tab.index,
        height: 64 + bottomInset,
        onDestinationSelected: (index) => setState(() => _tab = _ShellTab.values[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Arrangement',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Mixer',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
