part of 'sample_editor_screen.dart';

class _SampleToolCard extends StatelessWidget {
  const _SampleToolCard({required this.child});
  final Widget child;

  static const height = 236.0;
  static const _borderColor = Color(0xff3b3b49);

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        decoration: BoxDecoration(
          color: AutomationEditorTheme.panelBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: child,
      );
}
