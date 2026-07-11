part of 'editor_virtual_playhead.dart';

class EditorVirtualPlayheadPill extends StatelessWidget {
  const EditorVirtualPlayheadPill({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Material(
        elevation: 4,
        color: EditorVirtualPlayheadTheme.color,
        shape: CircleBorder(),
        child: SizedBox(
          width: EditorVirtualPlayheadTheme.pillSize,
          height: EditorVirtualPlayheadTheme.pillSize,
          child: Icon(Icons.play_arrow, size: 18, color: Color(0xFF1A1408)),
        ),
      ),
    );
  }
}
