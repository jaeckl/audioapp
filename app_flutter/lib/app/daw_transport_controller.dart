import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

import '../bridge/engine_bridge.dart';
import '../bridge/transport_state.dart';

/// Owns transport playback state, playhead ticker, meter polling, and
/// transport sync. Decoupled from project snapshot — can be tested in
/// isolation.
class DawTransportController extends ChangeNotifier {
  DawTransportController({
    required EngineBridge bridge,
    required TickerProvider vsync,
  })  : _bridge = bridge,
        _vsync = vsync;

  final EngineBridge _bridge;
  final TickerProvider _vsync;

  // --- observable state ---
  bool playing = false;
  final ValueNotifier<double> playheadBeats = ValueNotifier(0);
  int bpm = 120;
  bool loopEnabled = true;
  double loopRegionStart = 0;
  double loopRegionEnd = 16;
  bool followPlayheadEnabled = true;
  bool followPlayheadSuspended = false;

  // --- internal sync state ---
  Ticker? _playheadTicker;
  Timer? _transportSyncTimer;
  Timer? _meterRefreshTimer;
  final Stopwatch _stopwatch = Stopwatch();
  double _syncPlayheadBeats = 0;
  int _syncBpm = 120;
  bool _transportSyncInFlight = false;
  bool _transportSyncPending = false;
  bool _transportCommandInFlight = false;

  ValueNotifier<double> get playheadNotifier => playheadBeats;

  double get effectivePlayheadBeats => playheadBeats.value;

  double wrapPlayheadInLoop(double beats) {
    if (!loopEnabled) return beats;
    final len = loopRegionEnd - loopRegionStart;
    if (len <= 0) return beats;
    if (beats >= loopRegionEnd) {
      return loopRegionStart + (beats - loopRegionStart) % len;
    }
    return beats;
  }

  void publishPlayhead(double beats) {
    playheadBeats.value = beats;
  }

  void anchorTransport(TransportState transport) {
    _syncPlayheadBeats = transport.playheadBeats;
    _stopwatch
      ..reset()
      ..start();
    _syncBpm = transport.bpm;
    bpm = transport.bpm;
    loopEnabled = transport.loopEnabled;
    loopRegionStart = transport.loopRegionStartBeat;
    loopRegionEnd = transport.loopRegionEndBeat;
  }

  void publishSyncedPlayhead({TransportState? transport}) {
    if (playing) {
      publishPlayhead(extrapolatePlayheadBeats());
      return;
    }
    if (transport != null) {
      publishPlayhead(transport.playheadBeats);
    }
  }

  double extrapolatePlayheadBeats() {
    final elapsed = _stopwatch.elapsedMicroseconds / 1000000.0;
    var beats = _syncPlayheadBeats + elapsed * (_syncBpm / 60.0);
    beats = wrapPlayheadInLoop(beats);
    return beats;
  }

  Future<void> syncTransportState({bool updatePlaying = false}) async {
    if (_transportSyncInFlight) {
      _transportSyncPending = true;
      return;
    }
    _transportSyncInFlight = true;
    try {
      final transport = await _bridge.getTransportState();
      anchorTransport(transport);
      if (updatePlaying && !transport.playing) {
        playing = false;
        stopPlayheadAnimation();
      }
      if (updatePlaying) {
        playing = transport.playing;
        notifyListeners();
      }
      publishSyncedPlayhead(transport: transport);
    } catch (_) {
    } finally {
      _transportSyncInFlight = false;
      if (_transportSyncPending) {
        _transportSyncPending = false;
        unawaited(syncTransportState(updatePlaying: updatePlaying));
      }
    }
  }

  void startPlayheadAnimation() {
    stopPlayheadAnimation();
    _playheadTicker = _vsync.createTicker((_) {
      if (playing) {
        publishPlayhead(extrapolatePlayheadBeats());
      }
    })..start();
    _transportSyncTimer = Timer.periodic(
        const Duration(milliseconds: 100), (_) {
      unawaited(syncTransportState());
    });
    _meterRefreshTimer = Timer.periodic(
        const Duration(milliseconds: 500), (_) {
      onMeterRefreshNeeded?.call();
    });
    unawaited(syncTransportState());
  }

  void stopPlayheadAnimation() {
    _playheadTicker?.stop();
    _playheadTicker?.dispose();
    _playheadTicker = null;
    _transportSyncTimer?.cancel();
    _transportSyncTimer = null;
    _meterRefreshTimer?.cancel();
    _meterRefreshTimer = null;
    _stopwatch.stop();
  }

  void syncTransportAnchorFromSnapshot(
    int snapshotBpm,
    bool snapshotLoopEnabled,
    double snapshotLoopRegionStart,
    double snapshotLoopRegionEnd,
    double snapshotPlayheadBeats,
  ) {
    _syncBpm = snapshotBpm;
    if (!playing) {
      _syncPlayheadBeats = snapshotPlayheadBeats;
      publishPlayhead(snapshotPlayheadBeats);
    }
  }

  /// Callback for external meter refresh logic.
  VoidCallback? onMeterRefreshNeeded;

  Future<void> startPlay(double startBeat) async {
    if (playing || _transportCommandInFlight) return;
    _transportCommandInFlight = true;
    try {
      _syncPlayheadBeats = startBeat;
      _stopwatch
        ..reset()
        ..start();
      publishPlayhead(startBeat);
      await _bridge.setPlayheadBeats(startBeat);
      await _bridge.play();
      playing = true;
      notifyListeners();
      startPlayheadAnimation();
    } finally {
      _transportCommandInFlight = false;
    }
  }

  Future<void> stopPlay() async {
    if (!playing || _transportCommandInFlight) return;
    _transportCommandInFlight = true;
    stopPlayheadAnimation();
    playing = false;
    notifyListeners();
    try {
      await _bridge.stop();
      try {
        final transport = await _bridge.getTransportState();
        anchorTransport(transport);
        publishPlayhead(transport.playheadBeats);
      } catch (_) {}
    } finally {
      _transportCommandInFlight = false;
    }
  }

  void setFollowPlayheadEnabled(bool enabled) {
    followPlayheadEnabled = enabled;
    if (enabled) {
      followPlayheadSuspended = false;
    }
    notifyListeners();
  }

  /// Set playhead beats and optionally sync with engine.
  Future<void> setPlayheadBeats(double beats) async {
    try {
      _syncPlayheadBeats = beats;
      _stopwatch
        ..reset()
        ..start();
      publishPlayhead(beats);
      await _bridge.setPlayheadBeats(beats);
      if (playing) {
        await syncTransportState();
      } else {
        final transport = await _bridge.getTransportState();
        _syncPlayheadBeats = transport.playheadBeats;
        publishPlayhead(transport.playheadBeats);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    stopPlayheadAnimation();
    playheadBeats.dispose();
    super.dispose();
  }
}