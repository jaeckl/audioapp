part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateToggleloopOperation on _SampleEditorScreenState {
Future<void> _toggleLoop() async {
    final next = !loopContent;
    setState(() => loopContent = next);
    await widget.onSnapshot(await widget.bridge
        .setClipLoopContent(clipId: widget.clip.id, loopContent: next));
  }
}
