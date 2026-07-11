part of 'device_strip.dart';

class _FreezeStripBadge extends StatelessWidget {
  const _FreezeStripBadge({required this.stale});

  final bool stale;

  @override
  Widget build(BuildContext context) {
    final color = stale ? Colors.amber : const Color(0xFF8EB4FF);
    final label = stale ? 'STALE' : 'FROZEN';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontSize: 9,
            ),
      ),
    );
  }
}
