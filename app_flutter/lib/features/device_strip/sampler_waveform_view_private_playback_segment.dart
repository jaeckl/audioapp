part of 'sampler_waveform_view.dart';

class _PlaybackSegment extends StatelessWidget {
  const _PlaybackSegment({
    required this.selected,
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accentColor.withValues(alpha: 0.2) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? accentColor : Colors.white38,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? accentColor : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
