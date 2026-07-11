part of 'daw_shell.dart';

extension DawShellStateSetrecordarmedOperation on _DawShellState {
Future<void> _setRecordArmed(bool armed) async {
    try {
      if (armed) {
        await widget.bridge.ensureRecordAudioPermission();
      }
      await _store.invokeRaw('setRecordArmed', {'armed': armed});
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
