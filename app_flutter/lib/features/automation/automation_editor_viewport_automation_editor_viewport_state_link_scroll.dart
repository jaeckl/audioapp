part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateLinkscroll
    on AutomationEditorViewportState {
  void _linkScroll(ScrollController source, ScrollController target) {
    if (_syncingScroll || !source.hasClients || !target.hasClients) return;
    if ((source.offset - target.offset).abs() < 0.5) return;
    _syncingScroll = true;
    target.jumpTo(source.offset.clamp(0.0, target.position.maxScrollExtent));
    _syncingScroll = false;
  }
}
