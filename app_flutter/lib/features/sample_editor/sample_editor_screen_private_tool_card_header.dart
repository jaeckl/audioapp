part of 'sample_editor_screen.dart';

class _ToolCardHeader extends StatelessWidget {
  const _ToolCardHeader({required this.title, this.hint});
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: .5)),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(hint!,
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color:
                        ArrangementLoopRegionTheme.color.withValues(alpha: .85),
                    letterSpacing: .25)),
          ],
          const SizedBox(height: 4),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: .06),
          ),
        ],
      );
}
