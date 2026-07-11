part of 'daw_shell.dart';

extension DawShellStateConfirmdeletetrackOperation on _DawShellState {
Future<void> _confirmDeleteTrack(String trackId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete track?'),
        content: const Text('Clips on this track will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final snapshot = await widget.bridge.deleteTrack(trackId);
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
