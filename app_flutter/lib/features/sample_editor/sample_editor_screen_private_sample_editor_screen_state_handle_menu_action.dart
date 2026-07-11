part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateHandlemenuactionOperation on _SampleEditorScreenState {
void _handleMenuAction(_SampleMenuAction action) {
    switch (action) {
      case _SampleMenuAction.loop:
        unawaited(_toggleLoop());
      case _SampleMenuAction.warp:
        unawaited(_toggleWarp());
      case _SampleMenuAction.reverse:
        setState(() => reversed = !reversed);
        unawaited(_save());
      case _SampleMenuAction.normalize:
        _normalize();
    }
  }
}
