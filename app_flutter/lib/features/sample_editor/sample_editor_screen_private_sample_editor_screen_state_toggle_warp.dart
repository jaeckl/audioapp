part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateTogglewarpOperation on _SampleEditorScreenState {
Future<void> _toggleWarp() async {
    final next = !warpRepitch;
    setState(() => warpRepitch = next);
    _syncPreviewTransportSpan();
    await widget.onSnapshot(await widget.bridge
        .setSampleClipWarp(clipId: widget.clip.id, warpRepitch: next));
  }
}
