part of 'daw_shell.dart';

extension DawShellStateConfirmdeleteclipOperation on _DawShellState {
Future<void> _confirmDeleteClip(String clipId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete clip?'),
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
      final snapshot = await widget.bridge.deleteClip(clipId);
      await _refreshSnapshot(snapshot);
      // If the deleted clip was in link mode, clear it
      if (_automationLinkClipId == clipId) {
        setState(() => _automationLinkClipId = null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
