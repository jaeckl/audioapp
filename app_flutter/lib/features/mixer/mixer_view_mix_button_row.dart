part of 'mixer_view.dart';

/// Single segmented control — header icons (rec / solo / mute), shared chrome.
class _MixerMixButtonRow extends StatelessWidget {
  const _MixerMixButtonRow({
    required this.recordArmed,
    required this.soloed,
    required this.muted,
    required this.onRecord,
    required this.onSolo,
    required this.onMute,
    this.showRecord = true,
    this.showSolo = true,
    this.recordEnabled = true,
  });

  final bool recordArmed;
  final bool soloed;
  final bool muted;
  final VoidCallback? onRecord;
  final VoidCallback? onSolo;
  final VoidCallback onMute;
  final bool showRecord;
  final bool showSolo;
  final bool recordEnabled;

  @override
  Widget build(BuildContext context) {
    final segments = <_MixSegment>[
      if (showRecord)
        _MixSegment(
          icon: Icons.circle,
          tooltip: 'Record arm',
          active: recordArmed,
          color: Colors.redAccent,
          onTap: recordEnabled ? onRecord : null,
          enabled: recordEnabled && onRecord != null,
        ),
      if (showSolo)
        _MixSegment(
          icon: Icons.headphones,
          tooltip: 'Solo',
          active: soloed,
          color: Colors.amber,
          onTap: onSolo,
          enabled: onSolo != null,
        ),
      _MixSegment(
        icon: Icons.volume_off,
        tooltip: 'Mute',
        active: muted,
        color: Colors.redAccent,
        onTap: onMute,
        enabled: true,
      ),
    ];

    return SizedBox(
      height: MixerTheme.mixButtonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MixerTheme.chromeSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Row(
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0)
                  Container(width: 1, color: Colors.white12),
                Expanded(child: _MixSegmentButton(segment: segments[i])),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MixSegment {
  const _MixSegment({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.color,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;
}

class _MixSegmentButton extends StatelessWidget {
  const _MixSegmentButton({required this.segment});

  final _MixSegment segment;

  @override
  Widget build(BuildContext context) {
    final fg = segment.active
        ? Colors.black
        : MixerTheme.textPrimary.withValues(alpha: segment.enabled ? 1 : 0.35);
    return Tooltip(
      message: segment.tooltip,
      child: Material(
        color: segment.active ? segment.color : Colors.transparent,
        child: InkWell(
          onTap: segment.enabled ? segment.onTap : null,
          child: Center(
            child: Icon(
              segment.icon,
              size: MixerTheme.mixButtonHeight * 0.48,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
