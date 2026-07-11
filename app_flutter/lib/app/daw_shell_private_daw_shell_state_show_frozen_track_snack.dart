part of 'daw_shell.dart';

extension DawShellStateShowfrozentracksnackOperation on _DawShellState {
void _showFrozenTrackSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unfreeze track to add clips')),
    );
  }
}
