part of 'sample_editor_screen.dart';

class _EngineField extends StatelessWidget {
  const _EngineField();
  @override
  Widget build(BuildContext context) => Container(
        height: 26,
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ENGINE',
                style: TextStyle(
                    fontSize: 7, color: AutomationEditorTheme.labelMuted)),
            Text('Resample',
                style: TextStyle(fontSize: 9, color: Colors.white70)),
          ],
        ),
      );
}
