part of 'sample_editor_screen.dart';

class _FadeCurveSelector extends StatelessWidget {
  const _FadeCurveSelector({
    required this.label,
    required this.percent,
    required this.value,
    required this.fadeOut,
    required this.onChanged,
  });
  final String label;
  final double percent;
  final _FadeCurveKind value;
  final bool fadeOut;
  final ValueChanged<_FadeCurveKind> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .035),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text(label,
                  style: const TextStyle(
                      color: AutomationEditorTheme.labelMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .35)),
              const Spacer(),
              Text('${(percent * 100).round()}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            Expanded(
              child: Column(children: [
                Expanded(
                  child: Row(children: [
                    Expanded(child: _curveButton(_FadeCurveKind.linear)),
                    const SizedBox(width: 6),
                    Expanded(child: _curveButton(_FadeCurveKind.quadratic)),
                  ]),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(children: [
                    Expanded(child: _curveButton(_FadeCurveKind.cubic)),
                    const SizedBox(width: 6),
                    Expanded(child: _curveButton(_FadeCurveKind.smooth)),
                  ]),
                ),
              ]),
            ),
          ],
        ),
      );

  Widget _curveButton(_FadeCurveKind kind) => _FadeCurveIconButton(
        kind: kind,
        active: kind == value,
        fadeOut: fadeOut,
        onTap: () => onChanged(kind),
      );
}
