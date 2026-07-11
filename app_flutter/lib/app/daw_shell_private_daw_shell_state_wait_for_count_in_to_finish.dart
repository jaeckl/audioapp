part of 'daw_shell.dart';

extension DawShellStateWaitforcountintofinishOperation on _DawShellState {
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
}
