part of 'mixer_view.dart';

class _MasterChannel extends StatelessWidget {
  const _MasterChannel({
    required this.title,
    required this.gain,
    required this.muted,
    required this.selected,
    required this.meter,
    required this.onGainChanged,
    required this.onSelect,
    required this.onMute,
  });

  final String title;
  final double gain;
  final bool muted;
  final bool selected;
  final DeviceMeterReading? meter;
  final ValueChanged<double> onGainChanged;
  final VoidCallback onSelect;
  final VoidCallback onMute;

  @override
  Widget build(BuildContext context) {
    final accent =
        selected ? TrackLaneColor.master : MixerTheme.masterIcon;
    return _MixerChannelFrame(
      selected: selected,
      isMaster: true,
      accent: TrackLaneColor.master,
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSelect,
            child: Column(
              children: [
                Icon(Icons.speaker_outlined,
                    size: MixerTheme.headerIconSize, color: accent),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: MixerTheme.nameFontSize,
                    fontWeight: FontWeight.w700,
                    color: MixerTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _MixerFader(
              gain: gain,
              accent: accent,
              meter: meter,
              onChanged: onGainChanged,
            ),
          ),
          const SizedBox(height: 6),
          _MixerMixButtonRow(
            recordArmed: false,
            soloed: false,
            muted: muted,
            onRecord: null,
            onSolo: null,
            onMute: onMute,
            showRecord: false,
            showSolo: false,
          ),
          const SizedBox(height: 6),
          const _MixerOutputMenu(
            choices: [
              _OutputDestination(
                id: 'device',
                label: 'Device',
                icon: Icons.headphones_outlined,
              ),
            ],
            valueId: 'device',
            onChanged: null,
            locked: true,
          ),
        ],
      ),
    );
  }
}
