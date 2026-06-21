import 'package:flutter/material.dart';

class DevicePresetFilter {
  final String deviceType;
  final String label;
  final IconData icon;

  const DevicePresetFilter({
    required this.deviceType,
    required this.label,
    required this.icon,
  });
}

const List<DevicePresetFilter> kDevicePresetFilters = [
  DevicePresetFilter(deviceType: 'simple_sampler', label: 'Sampler', icon: Icons.album_outlined),
  DevicePresetFilter(deviceType: 'subtractive_synth', label: 'Synth', icon: Icons.waves),
  DevicePresetFilter(deviceType: 'kick_generator', label: 'Kick', icon: Icons.circle),
  DevicePresetFilter(deviceType: 'snare_generator', label: 'Snare', icon: Icons.circle_outlined),
  DevicePresetFilter(deviceType: 'clap_generator', label: 'Clap', icon: Icons.pan_tool_outlined),
  DevicePresetFilter(deviceType: 'cymbal_generator', label: 'Cymbal', icon: Icons.music_note_outlined),
  DevicePresetFilter(deviceType: 'hi_hat_generator', label: 'Hi-hat', icon: Icons.timer_outlined),
  DevicePresetFilter(deviceType: 'bass_synth', label: 'Bass Synth', icon: Icons.waves),
  DevicePresetFilter(deviceType: 'dynamics_fx', label: 'Dynamics', icon: Icons.tune),
];

class DevicePresetFilterList extends StatelessWidget {
  const DevicePresetFilterList({
    super.key,
    this.selectedType,
    required this.onFilterChanged,
  });

  /// The currently selected device type, or null for "All".
  final String? selectedType;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'Device type',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _DeviceChip(
                    label: 'All',
                    selected: selectedType == null,
                    onTap: () => onFilterChanged(null),
                  ),
                ),
                for (final filter in kDevicePresetFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _DeviceChip(
                      label: filter.label,
                      icon: filter.icon,
                      selected: selectedType == filter.deviceType,
                      onTap: () => onFilterChanged(filter.deviceType),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceChip extends StatelessWidget {
  const _DeviceChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF9A9AA8);
    return Material(
      color: selected ? accent.withValues(alpha: 0.22) : const Color(0xFF1C1C26),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : Colors.white24,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: selected ? accent : Colors.white70),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? accent : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
