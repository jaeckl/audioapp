part of 'daw_shell.dart';

extension DawShellStateLoadprojecttemplateOperation on _DawShellState {
  Future<void> _loadProjectTemplate(ProjectTemplate template) async {
    final assetPath = template.assetPath;
    if (assetPath == null) {
      await _createNewProject();
      return;
    }
    try {
      final projectJson = await rootBundle.loadString(assetPath);
      final snapshot = await widget.bridge.loadExampleProject(projectJson);
      await _activateProject(snapshot);
      if (mounted) {
        setState(() => _saveStatus = 'Started from ${template.name}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
