part of 'automation_clip_renderer.dart';

class AutomationClipLinkChip extends StatelessWidget {
  const AutomationClipLinkChip({
    super.key,
    required this.active,
    required this.onTap,
  });

  final bool active;
  final VoidCallback onTap;

  static const double _circleSize = 36;
  static const Color _creamFill = Color(0xFFF8F4EC);

  @override
  Widget build(BuildContext context) {
    final accent = LibraryTheme.accentAutomation;
    final glyphColor = active ? accent : const Color(0xFF6B5A4A);

    return Tooltip(
      message: active
          ? 'Link mode on — tap knob to assign'
          : 'Tap to link parameter',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: _circleSize,
            height: _circleSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _creamFill,
              border: active ? Border.all(color: accent, width: 2) : null,
            ),
            child: Text(
              '~',
              style: TextStyle(
                color: glyphColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
