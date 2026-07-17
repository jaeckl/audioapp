import 'package:flutter/material.dart';

import '../welcome/welcome_theme.dart';

/// Project-level actions. These deliberately live outside app Settings.
class ProjectHubScreen extends StatelessWidget {
  const ProjectHubScreen({
    super.key,
    required this.onNewProject,
    required this.onSaveProject,
    required this.onLoadProject,
    required this.onExportMix,
    required this.onOpenSettings,
    this.statusMessage,
    this.errorMessage,
  });

  final VoidCallback? onNewProject;
  final VoidCallback? onSaveProject;
  final VoidCallback? onLoadProject;
  final VoidCallback? onExportMix;
  final VoidCallback onOpenSettings;
  final String? statusMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: WelcomeTheme.background,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            _ProjectHeader(onOpenSettings: onOpenSettings),
            const SizedBox(height: WelcomeTheme.sectionGap),
            const Text('PROJECT', style: WelcomeTheme.sectionLabel),
            const SizedBox(height: 10),
            _ActionPanel(
              children: [
                _ActionRow(
                  key: const ValueKey('project-new'),
                  icon: Icons.add_rounded,
                  title: 'New project',
                  subtitle: 'Start with a clean arrangement',
                  onTap: onNewProject,
                ),
                _ActionRow(
                  key: const ValueKey('project-open'),
                  icon: Icons.folder_open_rounded,
                  title: 'Open project',
                  subtitle: 'Browse the AudioApp workspace',
                  onTap: onLoadProject,
                ),
                _ActionRow(
                  key: const ValueKey('project-save'),
                  icon: Icons.save_rounded,
                  title: 'Save project',
                  subtitle: 'Store the current arrangement as an archive',
                  onTap: onSaveProject,
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: WelcomeTheme.sectionGap),
            const Text('SHARE', style: WelcomeTheme.sectionLabel),
            const SizedBox(height: 10),
            _ActionPanel(
              children: [
                _ActionRow(
                  key: const ValueKey('project-export'),
                  icon: Icons.graphic_eq_rounded,
                  title: 'Export mix',
                  subtitle: 'Render the arrangement as a WAV file',
                  onTap: onExportMix,
                  showDivider: false,
                ),
              ],
            ),
            if (statusMessage != null) ...[
              const SizedBox(height: 16),
              _MessageBanner(message: statusMessage!),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              _MessageBanner(message: errorMessage!, error: true),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: WelcomeTheme.accentSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: WelcomeTheme.accent.withValues(alpha: 0.4),
            ),
          ),
          child: const Icon(
            Icons.folder_special_rounded,
            size: 27,
            color: WelcomeTheme.accent,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project',
                style: TextStyle(
                  color: WelcomeTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Create, open, save and share',
                style: TextStyle(
                  color: WelcomeTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          key: const ValueKey('project-settings'),
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings_rounded, size: 19),
          label: const Text('Settings'),
          style: TextButton.styleFrom(
            foregroundColor: WelcomeTheme.textPrimary,
            backgroundColor: WelcomeTheme.panelBackground,
            side: const BorderSide(color: WelcomeTheme.panelBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WelcomeTheme.panelBackground,
        borderRadius: BorderRadius.circular(WelcomeTheme.panelRadius),
        border: Border.all(color: WelcomeTheme.panelBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: WelcomeTheme.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: WelcomeTheme.accent, size: 20),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: WelcomeTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: WelcomeTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: WelcomeTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 67,
            color: WelcomeTheme.rowDivider,
          ),
      ],
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? WelcomeTheme.error : WelcomeTheme.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(error ? Icons.error_outline_rounded : Icons.check_rounded,
              color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: WelcomeTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}
