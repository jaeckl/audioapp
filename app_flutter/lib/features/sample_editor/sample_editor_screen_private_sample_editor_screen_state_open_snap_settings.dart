part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateOpensnapsettingsOperation on _SampleEditorScreenState {
void _openSnapSettings() => SampleEditSnapSheet.show(
        context,
        settings: editSnap,
        onChanged: (next) => setState(() => editSnap = next),
      );
}
