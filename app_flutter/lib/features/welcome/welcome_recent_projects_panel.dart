import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import 'example_projects.dart';
import 'welcome_theme.dart';

/// Bordered panel listing bundled example projects (always present, never
/// deletable) followed by the user's recently opened projects, styled like
/// the app's device-strip section cards instead of stock Material
/// `Card`/`ListTile`.
class WelcomeRecentProjectsPanel extends StatelessWidget {
  const WelcomeRecentProjectsPanel({
    super.key,
    required this.examples,
    required this.recentProjects,
    required this.busy,
    required this.onOpenExample,
    required this.onOpenRecent,
  });

  final List<ExampleProject> examples;
  final List<RecentProjectEntry> recentProjects;
  final bool busy;
  final ValueChanged<ExampleProject> onOpenExample;
  final ValueChanged<RecentProjectEntry> onOpenRecent;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: WelcomeTheme.panelBackground,
      borderRadius: BorderRadius.circular(WelcomeTheme.panelRadius),
      border: Border.all(color: WelcomeTheme.panelBorder),
    );

    final rowCount = examples.length + recentProjects.length;
    if (rowCount == 0) {
      return DecoratedBox(
        decoration: decoration,
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'No recent projects yet.',
            style: TextStyle(color: WelcomeTheme.textMuted),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: decoration,
      child: Column(
        children: [
          for (var i = 0; i < examples.length; i++)
            _ProjectRow(
              key: ValueKey('example-${examples[i].id}'),
              icon: Icons.auto_awesome_rounded,
              title: examples[i].name,
              subtitle: examples[i].subtitle,
              badgeLabel: 'EXAMPLE',
              showDivider: i != examples.length - 1 || recentProjects.isNotEmpty,
              busy: busy,
              onTap: () => onOpenExample(examples[i]),
            ),
          for (var i = 0; i < recentProjects.length; i++)
            _ProjectRow(
              key: ValueKey('recent-${recentProjects[i].uri}'),
              icon: Icons.music_note_rounded,
              title: recentProjects[i].name,
              subtitle: _formatOpenedAt(recentProjects[i].openedAt),
              badgeLabel: null,
              showDivider: i != recentProjects.length - 1,
              busy: busy,
              onTap: () => onOpenRecent(recentProjects[i]),
            ),
        ],
      ),
    );
  }

  static String _formatOpenedAt(DateTime value) {
    if (value.millisecondsSinceEpoch == 0) return 'Recently opened';
    final local = value.toLocal();
    return 'Opened ${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

/// A single tappable row shared by both example and recent project entries.
/// Example rows carry a [badgeLabel] ("EXAMPLE") instead of a chevron to
/// signal they're bundled, permanent content rather than a user file.
class _ProjectRow extends StatelessWidget {
  const _ProjectRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.showDivider,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeLabel;
  final bool showDivider;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: busy ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: WelcomeTheme.accentSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: WelcomeTheme.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: WelcomeTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(color: WelcomeTheme.textMuted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (badgeLabel != null)
                    _ExampleBadge(label: badgeLabel!)
                  else
                    const Icon(Icons.chevron_right_rounded, color: WelcomeTheme.textMuted),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: WelcomeTheme.rowDivider,
            indent: 14,
            endIndent: 14,
          ),
      ],
    );
  }
}

/// Small pill marking a row as bundled, non-deletable example content.
class _ExampleBadge extends StatelessWidget {
  const _ExampleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: WelcomeTheme.accentSoft,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: WelcomeTheme.accent.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: WelcomeTheme.accent,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );
}
