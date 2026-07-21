part of 'daw_shell.dart';

extension DawShellStateRequestnewprojectOperation on _DawShellState {
Future<void> _requestNewProject() async {
    if (_snapshot != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create a new project?'),
          content: const Text(
            'Unsaved changes in the current project will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('New Project'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    await _presentProjectTemplatePicker();
  }
}
