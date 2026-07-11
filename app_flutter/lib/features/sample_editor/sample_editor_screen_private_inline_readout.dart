part of 'sample_editor_screen.dart';

class _InlineReadout extends StatelessWidget {
  const _InlineReadout({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AutomationEditorTheme.labelMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3)),
        ],
      );
}
