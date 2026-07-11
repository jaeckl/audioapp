import 'package:flutter/material.dart';

part 'device_preset_filter_list_device_preset_filter.dart';
part 'device_preset_filter_list_device_chip.dart';

const List<DevicePresetFilter> kDevicePresetFilters = [
  DevicePresetFilter(
      deviceType: 'simple_sampler',
      label: 'Sampler',
      icon: Icons.album_outlined),
  DevicePresetFilter(
      deviceType: 'granular_formant_synth',
      label: 'Granular',
      icon: Icons.blur_on),
  DevicePresetFilter(
      deviceType: 'subtractive_synth', label: 'Synth', icon: Icons.waves),
  DevicePresetFilter(
      deviceType: 'kick_generator', label: 'Kick', icon: Icons.circle),
  DevicePresetFilter(
      deviceType: 'snare_generator',
      label: 'Snare',
      icon: Icons.circle_outlined),
  DevicePresetFilter(
      deviceType: 'clap_generator',
      label: 'Clap',
      icon: Icons.pan_tool_outlined),
  DevicePresetFilter(
      deviceType: 'cymbal_generator',
      label: 'Cymbal',
      icon: Icons.music_note_outlined),
  DevicePresetFilter(
      deviceType: 'hi_hat_generator',
      label: 'Hi-hat',
      icon: Icons.timer_outlined),
  DevicePresetFilter(
      deviceType: 'bass_synth', label: 'Bass Synth', icon: Icons.waves),
  DevicePresetFilter(
      deviceType: 'dynamics_fx', label: 'Dynamics', icon: Icons.tune),
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
                Row(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
