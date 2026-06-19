import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/transport_state.dart';

/// Preview transport for clip editors — drives engine playhead without updating the
/// arrangement UI (restore [savedArrangementPlayhead] on [disposePreview]).
class ClipEditorTransportController extends ChangeNotifier {
  ClipEditorTransportController({
    required this.bridge,
    required this.clipStartBeat,
    required this.savedArrangementPlayhead,
    required TickerProvider vsync,
    double maxClipBeat = 4,
  })  : _maxClipBeat = maxClipBeat,
        _clipLocalBeat = 0 {
    _ticker = vsync.createTicker((_) {
      if (!_playing) return;
      _publishClipLocal(_extrapolateLocalBeat());
    });
    _transportSync = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => unawaited(_syncTransport()),
    );
    clipLocalBeatNotifier.addListener(notifyListeners);
  }

  final EngineBridge bridge;
  final double clipStartBeat;
  final double savedArrangementPlayhead;

  late final Ticker _ticker;
  late final Timer _transportSync;
  final ValueNotifier<double> clipLocalBeatNotifier = ValueNotifier(0);

  double _maxClipBeat;
  double _clipLocalBeat;
  bool _playing = false;
  double _syncArrangementBeat = 0;
  DateTime _syncTime = DateTime.now();
  int _syncBpm = 120;

  double get maxClipBeat => _maxClipBeat;
  set maxClipBeat(double value) {
    _maxClipBeat = value;
    _clipLocalBeat = _clipLocalBeat.clamp(0.0, _maxClipBeat);
    _publishClipLocal(_clipLocalBeat);
  }

  bool get isPlaying => _playing;

  double get clipLocalBeat => clipLocalBeatNotifier.value;

  double get arrangementBeat => clipStartBeat + clipLocalBeat;

  void _publishClipLocal(double beat) {
    clipLocalBeatNotifier.value = beat;
  }

  void seekClipLocal(double beat) {
    _clipLocalBeat = beat.clamp(0.0, _maxClipBeat);
    _syncArrangementBeat = clipStartBeat + _clipLocalBeat;
    _syncTime = DateTime.now();
    _publishClipLocal(_clipLocalBeat);
    unawaited(bridge.setPlayheadBeats(_syncArrangementBeat));
    notifyListeners();
  }

  Future<void> togglePlay({required int bpm}) async {
    if (_playing) {
      await stop();
    } else {
      await play(bpm: bpm);
    }
  }

  Future<void> play({required int bpm}) async {
    _syncBpm = bpm;
    final arrangementBeat = clipStartBeat + _clipLocalBeat;
    _syncArrangementBeat = arrangementBeat;
    _syncTime = DateTime.now();
    _publishClipLocal(_clipLocalBeat);
    await bridge.setPlayheadBeats(arrangementBeat);
    await bridge.play();
    _playing = true;
    _ticker.start();
    notifyListeners();
  }

  Future<void> stop() async {
    if (!_playing) return;
    await bridge.stop();
    _playing = false;
    _ticker.stop();
    try {
      final transport = await bridge.getTransportState();
      _anchorTransport(transport);
      _publishClipLocal(_clipLocalBeat);
    } catch (_) {
      _clipLocalBeat =
          (_syncArrangementBeat - clipStartBeat).clamp(0.0, _maxClipBeat);
      _publishClipLocal(_clipLocalBeat);
    }
    notifyListeners();
  }

  Future<void> disposePreview() async {
    _transportSync.cancel();
    clipLocalBeatNotifier.removeListener(notifyListeners);
    if (_playing) {
      await bridge.stop();
      _playing = false;
    }
    _ticker.dispose();
    clipLocalBeatNotifier.dispose();
    await bridge.setPlayheadBeats(savedArrangementPlayhead);
  }

  void _anchorTransport(TransportState transport) {
    _syncArrangementBeat = transport.playheadBeats;
    _syncTime = DateTime.now();
    _syncBpm = transport.bpm;
    _clipLocalBeat =
        (transport.playheadBeats - clipStartBeat).clamp(0.0, _maxClipBeat);
  }

  Future<void> _syncTransport() async {
    if (!_playing) return;
    try {
      final transport = await bridge.getTransportState();
      if (!transport.playing) {
        _playing = false;
        _ticker.stop();
        _anchorTransport(transport);
        _publishClipLocal(_clipLocalBeat);
        notifyListeners();
        return;
      }
      _anchorTransport(transport);
      _publishClipLocal(_extrapolateLocalBeat());
      notifyListeners();
    } catch (_) {}
  }

  double _extrapolateLocalBeat() {
    final elapsed = DateTime.now().difference(_syncTime).inMicroseconds / 1000000.0;
    final arrangement = _syncArrangementBeat + elapsed * (_syncBpm / 60.0);
    return (arrangement - clipStartBeat).clamp(0.0, _maxClipBeat);
  }
}
