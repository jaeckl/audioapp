import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onSaveProject,
    required this.onLoadProject,
    required this.onExportMix,
    this.loopEnabled = true,
    this.onLoopToggled,
    this.statusMessage,
    this.errorMessage,
  });

  final VoidCallback? onSaveProject;
  final VoidCallback? onLoadProject;
  final VoidCallback? onExportMix;
  final bool loopEnabled;
  final ValueChanged<bool>? onLoopToggled;
  final String? statusMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            subtitle: const Text('Set the loop region with the blue markers in the arrangement'),
            value: loopEnabled,
            onChanged: onLoopToggled,
          ),
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
          const SizedBox(height: 16),
          Text(statusMessage!, style: theme.textTheme.bodySmall),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}
