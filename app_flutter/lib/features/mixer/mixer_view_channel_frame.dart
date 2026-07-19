part of 'mixer_view.dart';

class _MixerChannelFrame extends StatelessWidget {
  const _MixerChannelFrame({
    required this.selected,
    required this.isMaster,
    required this.accent,
    required this.child,
  });

  final bool selected;
  final bool isMaster;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? accent
        : (isMaster
            ? MixerTheme.masterBorder
            : accent.withValues(alpha: 0.4));
    // Accent is border / rails / icon only — card fill stays neutral.
    final fill = isMaster
        ? (selected ? MixerTheme.masterFillSelected : MixerTheme.masterFill)
        : (selected ? MixerTheme.trackFillSelected : MixerTheme.trackFill);
    // No GestureDetector here — it steals arena from pan/gain controls.
    return Container(
      width: MixerTheme.channelWidth,
      margin: const EdgeInsets.only(right: MixerTheme.channelGap),
      padding: MixerTheme.channelPadding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(MixerTheme.channelRadius),
        border: Border.all(color: border, width: selected ? 1.5 : 1),
      ),
      child: child,
    );
  }
}
