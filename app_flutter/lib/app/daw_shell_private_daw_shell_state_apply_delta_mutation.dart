part of 'daw_shell.dart';

extension DawShellStateApplydeltamutationOperation on _DawShellState {
Future<void> _applyDeltaMutation(
    String method, [
    Map<String, dynamic>? args,
  ]) async {
    await _store.invokeRaw(method, args);
  }
}
