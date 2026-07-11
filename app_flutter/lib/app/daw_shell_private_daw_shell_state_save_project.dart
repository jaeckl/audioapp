part of 'daw_shell.dart';

extension DawShellStateSaveprojectOperation on _DawShellState {
Future<void> _saveProject() async {
    try {
      final location = await widget.bridge.saveProject();
      if (!mounted) return;
      if (location == null) {
        return;
      }
      setState(() {
        _saveStatus = 'Saved project';
        _projectError = null;
      });
      await _refreshRecentProjects();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(
          () => _projectError = '${e.code}: ${e.message ?? "save failed"}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
