part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateSaveOperation on _SampleEditorScreenState {
Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final snapshot = await widget.bridge.setSampleClipProperties(
          clipId: widget.clip.id,
          sourceStart: start,
          sourceEnd: end,
          gain: gain,
          fadeIn: fadeIn,
          fadeOut: fadeOut,
          fadeInCurve: fadeInCurve,
          fadeOutCurve: fadeOutCurve,
          reversed: reversed);
      await widget.onSnapshot(snapshot);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
