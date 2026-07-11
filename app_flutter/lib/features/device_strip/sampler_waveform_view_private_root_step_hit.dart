part of 'sampler_waveform_view.dart';

class _RootStepHit extends StatelessWidget {
  const _RootStepHit({
    required this.icon,
    required this.color,
    required this.onTap,
    this.expand = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: expand
            ? Center(child: Icon(icon, size: 14, color: color))
            : SizedBox(
                width: 46,
                height: 16,
                child: Center(child: Icon(icon, size: 14, color: color)),
              ),
      ),
    );
  }
}
