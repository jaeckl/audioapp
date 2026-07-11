part of 'daw_shell.dart';

extension DawShellStateSetmastergainOperation on _DawShellState {
Future<void> _setMasterGain(double value) async {
    try {
      await widget.bridge.setMasterGain(value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
