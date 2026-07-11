part of 'daw_shell.dart';

extension DawShellStateAssignautomationparamOperation on _DawShellState {
Future<bool> _assignAutomationParam(String deviceId, String paramId) async {
    final clipId = _automationLinkClipId;
    final snapshot = _snapshot;
    if (clipId == null || snapshot == null) {
      return false;
    }

    if (snapshot.deviceById(deviceId) == null) {
      return false;
    }
    if (snapshot.automationClipById(clipId) == null) {
      return false;
    }

    try {
      final clip = snapshot.automationClipById(clipId);
      final alreadyLinked =
          clip?.deviceId == deviceId && clip?.paramId == paramId;
      final updated = alreadyLinked
          ? await widget.bridge.unlinkAutomationTarget(clipId: clipId)
          : await widget.bridge.assignAutomationTarget(
              clipId: clipId,
              deviceId: deviceId,
              paramId: paramId,
            );
      if (!mounted) return false;
      setState(() => _automationLinkClipId = null);
      await _refreshSnapshot(updated);
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() => _projectError = e.toString());
      return false;
    }
  }
}
