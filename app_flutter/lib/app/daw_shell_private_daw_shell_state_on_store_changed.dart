part of 'daw_shell.dart';

extension DawShellStateOnstorechangedOperation on _DawShellState {
void _onStoreChanged() {
    if (mounted) setState(() {});
    if (_tab == _ShellTab.mixer) {
      unawaited(_updateMeterSubscriptions(const []));
    }
  }
}
