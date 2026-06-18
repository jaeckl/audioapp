import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onSaveProject,
    required this.onLoadProject,
    required this.onExportMix,
    this.loopEnabled = true,
    this.loopLengthBeats = 16,
    this.onLoopToggled,
    this.onLoopLengthChanged,
    this.statusMessage,
    this.errorMessage,
  });

  final VoidCallback onSaveProject;
  final VoidCallback onLoadProject;
  final VoidCallback onExportMix;
  final bool loopEnabled;
  final double loopLengthBeats;
  final ValueChanged<bool>? onLoopToggled;
  final ValueChanged<double>? onLoopLengthChanged;
  final String? statusMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loopBars = (loopLengthBeats / 4).clamp(1, 64).toDouble();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Settings', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        if (onLoopToggled != null) ...[
          Text('Transport', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Loop playback'),
            subtitle: const Text('Repeat the timeline when playing'),
            value: loopEnabled,
            onChanged: onLoopToggled,
          ),
          if (onLoopLengthChanged != null) ...[
            const SizedBox(height: 4),
            Text('Loop length (bars)', style: theme.textTheme.labelMedium),
            Slider(
              min: 1,
              max: 64,
              divisions: 63,
              label: '${loopBars.round()} bars',
              value: loopBars,
              onChanged: loopEnabled ? (bars) => onLoopLengthChanged!(bars * 4) : null,
            ),
          ],
          const SizedBox(height: 16),
        ],
        Text('Project', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: onSaveProject,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save project'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: onLoadProject,
          icon: const Icon(Icons.folder_open_outlined),
          label: const Text('Open project'),
        ),
        const SizedBox(height: 16),
        Text('Export', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: onExportMix,
          icon: const Icon(Icons.upload_outlined),
          label: const Text('Export mix (WAV)'),
        ),
        if (statusMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            statusMessage!,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(errorMessage!, style: const TextStyle(color: Colors.redAccent)),
        ],
      ],
    );
  }
}
