part of 'transport_bar.dart';

class _SnapGridMenuButton extends StatelessWidget {
  const _SnapGridMenuButton({
    required this.snapClipsEnabled,
    required this.snapGridResolution,
    required this.snapGridTriplet,
    required this.enabled,
    this.onSnapClipsEnabledChanged,
    this.onSnapGridResolutionChanged,
    this.onSnapGridTripletChanged,
  });

  final bool snapClipsEnabled;
  final SnapGridResolution snapGridResolution;
  final bool snapGridTriplet;
  final bool enabled;
  final ValueChanged<bool>? onSnapClipsEnabledChanged;
  final ValueChanged<SnapGridResolution>? onSnapGridResolutionChanged;
  final ValueChanged<bool>? onSnapGridTripletChanged;

  @override
  Widget build(BuildContext context) {
    final tooltip =
        '${snapClipsEnabled ? 'Clip snap on' : 'Clip snap off'} · ${snapGridResolution.label}${snapGridTriplet ? ' triplet' : ''}';

    return PopupMenuButton<void>(
      tooltip: tooltip,
      enabled: enabled,
      padding: EdgeInsets.zero,
      color: TransportBarTheme.menuBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: TransportBarTheme.chipBorder),
      ),
      icon: Icon(
        Icons.grid_4x4,
        size: 20,
        color: enabled
            ? TransportBarTheme.textSecondary
            : TransportBarTheme.textMuted,
      ),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: _SnapGridMenu(
            snapClips: snapClipsEnabled,
            resolution: snapGridResolution,
            triplet: snapGridTriplet,
            onSnapClipsChanged: (value) =>
                onSnapClipsEnabledChanged?.call(value),
            onResolutionChanged: (value) =>
                onSnapGridResolutionChanged?.call(value),
            onTripletChanged: (value) => onSnapGridTripletChanged?.call(value),
          ),
        ),
      ],
    );
  }
}
