part of 'mixer_view.dart';

class _TrackChannel extends StatelessWidget {
  const _TrackChannel({
    required this.track,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.recordArmed,
    required this.meter,
    required this.outputChoices,
    required this.onGainChanged,
    required this.onPanChanged,
    required this.onSelect,
    required this.onMute,
    required this.onSolo,
    required this.onRecord,
    required this.onOutputChanged,
  });

  final TrackSnapshot track;
  final IconData icon;
  final Color accent;
  final bool selected;
  final bool recordArmed;
  final DeviceMeterReading? meter;
  final List<_OutputDestination> outputChoices;
  final ValueChanged<double> onGainChanged;
  final ValueChanged<double> onPanChanged;
  final VoidCallback onSelect;
  final VoidCallback onMute;
  final VoidCallback onSolo;
  final VoidCallback? onRecord;
  final ValueChanged<String> onOutputChanged;

  @override
  Widget build(BuildContext context) {
    final device = track.trackGainDevice;
    final railAccent = selected ? accent : accent.withValues(alpha: 0.65);
    final outputValue = outputChoices.any((c) => c.id == track.outputTarget)
        ? track.outputTarget
        : 'master';
    final canArm =
        onRecord != null && !track.isGroup && !track.freeze.isManual;

    return _MixerChannelFrame(
      selected: selected,
      isMaster: false,
      accent: accent,
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSelect,
            child: Row(
              children: [
                Icon(icon, size: MixerTheme.headerIconSize, color: railAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    track.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: MixerTheme.nameFontSize,
                      fontWeight: FontWeight.w700,
                      color: MixerTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _MixerFader(
              key: ValueKey('mixer-gain-${track.id}'),
              gain: device?.gain ?? 1,
              accent: railAccent,
              meter: meter,
              onChanged: onGainChanged,
            ),
          ),
          const SizedBox(height: 6),
          _MixerPanSlider(
            key: ValueKey('mixer-pan-${track.id}'),
            pan: (device?.pan ?? .5).clamp(0.0, 1.0),
            accent: railAccent,
            onChanged: onPanChanged,
          ),
          const SizedBox(height: 6),
          _MixerMixButtonRow(
            recordArmed: recordArmed,
            soloed: track.soloed,
            muted: track.muted,
            onRecord: canArm ? onRecord : null,
            onSolo: onSolo,
            onMute: onMute,
            recordEnabled: canArm,
          ),
          const SizedBox(height: 6),
          _MixerOutputMenu(
            choices: outputChoices,
            valueId: outputValue,
            onChanged: onOutputChanged,
          ),
        ],
      ),
    );
  }
}
