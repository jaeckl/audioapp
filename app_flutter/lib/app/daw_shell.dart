import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/shell_insets.dart';
import '../bridge/engine_bridge.dart';
import '../bridge/project_snapshot.dart';
import '../features/arrangement/arrangement_view.dart';
import '../features/device_strip/device_strip.dart';
import '../features/piano_roll/piano_roll_screen.dart';
import '../features/sample_library/sample_library_screen.dart';
import '../features/transport/transport_bar.dart';

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
  String? _bridgeStatus;
  ProjectSnapshot? _snapshot;
  String? _saveStatus;
  String? _error;
  Timer? _playheadTimer;

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
      final pong = await widget.bridge.ping();
      final snapshot = await widget.bridge.createProject();
      if (!mounted) return;
      setState(() {
        _bridgeStatus = pong.isNotEmpty ? 'Engine: $pong' : 'Engine: connected';
        _snapshot = snapshot;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() => _bridgeStatus = 'Engine: native bridge unavailable');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
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
      setState(() => _error = e.toString());
    }
  }

  Future<void> _selectTrack(String trackId) async {
    try {
      final snapshot = await widget.bridge.selectTrack(trackId);
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _addMidiClip() async {
    final trackId = _snapshot?.selectedTrackId;
    if (trackId == null || trackId.isEmpty) return;
    try {
      final snapshot = await widget.bridge.createMidiClip(trackId: trackId);
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
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
      setState(() => _error = e.toString());
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
        _error = null;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _error = '${e.code}: ${e.message ?? "save failed"}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
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
        _error = null;
        _playing = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _error = '${e.code}: ${e.message ?? "load failed"}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _openSampleLibrary() async {
    final snapshot = _snapshot;
    if (snapshot == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => SampleLibraryScreen(
          samples: snapshot.samples,
          onPreview: (sample) async {
            try {
              await widget.bridge.previewSample(sample.id);
            } catch (e) {
              if (!mounted) return;
              setState(() => _error = e.toString());
            }
          },
          onInsert: (sample) async {
            final trackId = _snapshot?.selectedTrackId;
            if (trackId == null || trackId.isEmpty) return;
            final navigator = Navigator.of(context);
            navigator.pop();
            try {
              final updated = await widget.bridge.createSampleClip(
                trackId: trackId,
                sampleId: sample.id,
              );
              await _refreshSnapshot(updated);
            } catch (e) {
              if (!mounted) return;
              setState(() => _error = e.toString());
            }
          },
          onImport: () async {
            try {
              final updated = await widget.bridge.importSample();
              if (!mounted) return;
              if (updated != null) {
                await _refreshSnapshot(updated);
                if (!mounted) return;
                final navigator = Navigator.of(context);
                navigator.pop();
                await _openSampleLibrary();
              }
            } catch (e) {
              if (!mounted) return;
              setState(() => _error = e.toString());
            }
          },
        ),
      ),
    );

    try {
      final refreshed = await widget.bridge.getProjectSnapshot();
      await _refreshSnapshot(refreshed);
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_bridgeStatus != null)
            Padding(
              padding: ShellInsets.headerPadding(context),
              child: Text(
                _bridgeStatus!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54),
              ),
            ),
            if (_saveStatus != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _saveStatus!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54),
                ),
              ),
            if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          Expanded(
            child: snapshot == null
                ? const Center(child: CircularProgressIndicator())
                : ArrangementView(
                    snapshot: snapshot,
                    playheadBeats: snapshot.playheadBeats,
                    onTrackSelected: _selectTrack,
                    onAddTrack: _addTrack,
                    onAddMidiClip: _addMidiClip,
                    onOpenSampleLibrary: _openSampleLibrary,
                    onClipTap: _openPianoRoll,
                    onSampleClipTap: (_, __) {},
                    onSaveProject: _saveProject,
                    onLoadProject: _loadProject,
                  ),
          ),
          DeviceStrip(
            track: snapshot?.selectedTrack,
            onFrequencyChanged: _setFrequency,
          ),
          TransportBar(
            playing: _playing,
            bpm: snapshot?.bpm ?? 120,
            playheadBeats: snapshot?.playheadBeats ?? 0,
            onPlayStop: _togglePlay,
          ),
        ],
      ),
    );
  }
}
