part of 'daw_shell.dart';

extension DawShellStateSetmetronomeOperation on _DawShellState {
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
}
