part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateAuditionOperation on _SampleEditorScreenState {
Future<void> _audition() async {
    await transport.togglePlay(bpm: widget.bpm);
  }
}
