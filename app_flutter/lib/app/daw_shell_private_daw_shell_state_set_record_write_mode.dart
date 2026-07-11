part of 'daw_shell.dart';

extension DawShellStateSetrecordwritemodeOperation on _DawShellState {
void _setRecordWriteMode(RecordWriteMode mode) {
    if (_recordWriteMode == mode) return;
    setState(() => _recordWriteMode = mode);
  }
}
