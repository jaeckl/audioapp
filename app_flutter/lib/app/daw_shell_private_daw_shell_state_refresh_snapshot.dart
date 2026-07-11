part of 'daw_shell.dart';

extension DawShellStateRefreshsnapshotOperation on _DawShellState {
Future<void> _refreshSnapshot(ProjectSnapshot snapshot) async {
    _store.replaceSnapshot(snapshot);
  }
}
