import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Settings', style: theme.textTheme.titleMedium),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Project settings coming soon',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white38),
            ),
          ),
        ),
      ],
    );
  }
}
