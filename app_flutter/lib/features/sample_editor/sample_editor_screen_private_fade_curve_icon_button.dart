part of 'sample_editor_screen.dart';

class _FadeCurveIconButton extends StatelessWidget {
  const _FadeCurveIconButton({
    required this.kind,
    required this.active,
    required this.fadeOut,
    required this.onTap,
  });
  final _FadeCurveKind kind;
  final bool active;
  final bool fadeOut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: active
            ? AutomationEditorTheme.accent.withValues(alpha: .16)
            : Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: active
                    ? AutomationEditorTheme.accent.withValues(alpha: .55)
                    : Colors.white.withValues(alpha: .08),
              ),
            ),
            child: CustomPaint(
              painter: _FadeCurveIconPainter(
                kind: kind,
                fadeOut: fadeOut,
                color: active ? AutomationEditorTheme.accent : Colors.white60,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
}
