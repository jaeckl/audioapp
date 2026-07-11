part of 'daw_shell.dart';

extension DawShellStateLoadprojectOperation on _DawShellState {
Future<void> _loadProject() async {
    try {
      final snapshot = await widget.bridge.loadProject();
      if (!mounted) return;
      if (snapshot == null) {
        return;
      }
      await _activateProject(snapshot);
      setState(() {
        _saveStatus = 'Loaded project';
        _projectError = null;
      });
      await _refreshRecentProjects();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(
          () => _projectError = '${e.code}: ${e.message ?? "load failed"}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
