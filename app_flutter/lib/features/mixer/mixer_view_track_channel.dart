part of 'mixer_view.dart';

class _TrackChannel extends StatelessWidget {
  const _TrackChannel({
    required this.track,
    required this.icon,
    required this.selected,
    required this.meter,
    required this.outputChoices,
    required this.onGainChanged,
    required this.onPanChanged,
    required this.onSelect,
    required this.onMute,
    required this.onSolo,
    required this.onOutputChanged,
  });

  final TrackSnapshot track;
  final IconData icon;
  final bool selected;
  final DeviceMeterReading? meter;
  final List<_OutputDestination> outputChoices;
  final ValueChanged<double> onGainChanged, onPanChanged;
  final VoidCallback onSelect, onMute, onSolo;
  final ValueChanged<String> onOutputChanged;

  @override
  Widget build(BuildContext context) {
    final device = track.trackGainDevice;
    final accent = selected ? const Color(0xFFE8A54B) : const Color(0xFF777787);
    final outputValue = outputChoices.any((c) => c.id == track.outputTarget)
        ? track.outputTarget
        : 'master';
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        width: 104,
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF23232D) : const Color(0xFF191920),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: selected ? accent : Colors.white10),
        ),
        child: Column(
          children: [
            Row(children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 3),
              Expanded(
                child: Text(track.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: Colors.white70)),
              ),
            ]),
            const SizedBox(height: 3),
            Expanded(
              child: Row(
                children: [
                  _StereoMeter(
                    left: meter?.leftLevel ?? 0,
                    right: meter?.rightLevel ?? 0,
                  ),
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          activeTrackColor: accent,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Colors.white70,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: (device?.gain ?? 1).clamp(0.0, 1.0),
                          onChanged: onGainChanged,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            RotaryKnob(
              label: 'Pan',
              value: (device?.pan ?? .5).clamp(0.0, 1.0),
              displayValue: _panLabel(device?.pan ?? .5),
              accentColor: accent,
              size: DeviceKnobSizes.compact,
              onChanged: onPanChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MixToggle(
                    label: 'M',
                    active: track.muted,
                    color: Colors.orange,
                    onTap: onMute),
                const SizedBox(width: 4),
                _MixToggle(
                    label: 'S',
                    active: track.soloed,
                    color: Colors.amber,
                    onTap: onSolo),
                const SizedBox(width: 4),
                Text('${track.visibleDevices.length}',
                    style: const TextStyle(fontSize: 8, color: Colors.white38)),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 22,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  isDense: true,
                  value: outputValue,
                  dropdownColor: const Color(0xFF1E1E28),
                  style: const TextStyle(fontSize: 9, color: Colors.white70),
                  iconSize: 14,
                  items: [
                    for (final choice in outputChoices)
                      DropdownMenuItem(
                        value: choice.id,
                        child: Text(
                          choice.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) onOutputChanged(value);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
