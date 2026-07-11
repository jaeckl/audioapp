part of 'daw_shell.dart';

extension DawShellStateLoadexampleprojectOperation on _DawShellState {
Future<void> _loadExampleProject(ExampleProject example) async {
    try {
      final projectJson = await rootBundle.loadString(example.assetPath);
      final snapshot = await widget.bridge.loadExampleProject(projectJson);
      await _activateProject(snapshot);
      if (mounted) setState(() => _saveStatus = 'Loaded ${example.name}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
