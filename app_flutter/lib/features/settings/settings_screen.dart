import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onSaveProject,
    required this.onLoadProject,
    this.statusMessage,
    this.errorMessage,
  });

  final VoidCallback onSaveProject;
  final VoidCallback onLoadProject;
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
