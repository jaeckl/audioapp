part of 'daw_shell.dart';

extension DawShellStatePresentprojecttemplatepickerOperation on _DawShellState {
  Future<void> _presentProjectTemplatePicker() async {
    final template = await Navigator.of(context).push<ProjectTemplate>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ProjectTemplatePickerScreen(),
      ),
    );
    if (template == null || !mounted) return;
    if (template.isProceduralEmpty) {
      await _createNewProject();
      return;
    }
    await _loadProjectTemplate(template);
  }
}
