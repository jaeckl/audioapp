part of 'daw_shell.dart';

extension DawShellStateToggleautomationlinkOperation on _DawShellState {
void _toggleAutomationLink(String clipId) {
    setState(() {
      _automationLinkClipId = _automationLinkClipId == clipId ? null : clipId;
    });
  }
}
