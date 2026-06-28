import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import '../settings/settings_screen.dart';

class WelcomeHub extends StatelessWidget {
  const WelcomeHub({
    super.key,
    required this.recentProjects,
    required this.hasActiveProject,
    required this.busy,
    required this.onNewProject,
    required this.onContinue,
    required this.onOpenProject,
    required this.onOpenRecent,
    this.onSaveProject,
    this.onExportMix,
    this.loopEnabled = true,
    this.onLoopToggled,
    this.statusMessage,
    this.errorMessage,
  });

  final List<RecentProjectEntry> recentProjects;
  final bool hasActiveProject;
  final bool busy;
  final VoidCallback onNewProject;
  final VoidCallback? onContinue;
  final VoidCallback onOpenProject;
  final ValueChanged<RecentProjectEntry> onOpenRecent;
  final VoidCallback? onSaveProject;
  final VoidCallback? onExportMix;
  final bool loopEnabled;
  final ValueChanged<bool>? onLoopToggled;
  final String? statusMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _WelcomeHeader(),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.folder_copy_outlined), text: 'Projects'),
              Tab(icon: Icon(Icons.settings_outlined), text: 'Settings'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ProjectsPage(
                  recentProjects: recentProjects,
                  hasActiveProject: hasActiveProject,
                  busy: busy,
                  onNewProject: onNewProject,
                  onContinue: onContinue,
                  onOpenProject: onOpenProject,
                  onOpenRecent: onOpenRecent,
                ),
                SettingsScreen(
                  onSaveProject: onSaveProject,
                  onLoadProject: onOpenProject,
                  onExportMix: onExportMix,
                  loopEnabled: loopEnabled,
                  onLoopToggled: onLoopToggled,
                  statusMessage: statusMessage,
                  errorMessage: errorMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Row(
          children: [
            Icon(Icons.graphic_eq, size: 34, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AudioApp', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                Text('Make something worth replaying', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ],
        ),
      );
}

class _ProjectsPage extends StatelessWidget {
  const _ProjectsPage({
    required this.recentProjects,
    required this.hasActiveProject,
    required this.busy,
    required this.onNewProject,
    required this.onContinue,
    required this.onOpenProject,
    required this.onOpenRecent,
  });

  final List<RecentProjectEntry> recentProjects;
  final bool hasActiveProject;
  final bool busy;
  final VoidCallback onNewProject;
  final VoidCallback? onContinue;
  final VoidCallback onOpenProject;
  final ValueChanged<RecentProjectEntry> onOpenRecent;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const ValueKey('welcome-new-project'),
                onPressed: busy ? null : onNewProject,
                icon: const Icon(Icons.add),
                label: const Text('New Project'),
              ),
              FilledButton.tonalIcon(
                key: const ValueKey('welcome-open-project'),
                onPressed: busy ? null : onOpenProject,
                icon: const Icon(Icons.folder_open),
                label: const Text('Open Project'),
              ),
              if (onContinue != null)
                OutlinedButton.icon(
                  key: const ValueKey('welcome-continue'),
                  onPressed: busy ? null : onContinue,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(hasActiveProject ? 'Continue Project' : 'Continue Last'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Recent projects', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (recentProjects.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No recent projects yet.', style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            for (final project in recentProjects)
              Card(
                child: ListTile(
                  key: ValueKey('recent-${project.uri}'),
                  leading: const Icon(Icons.music_note),
                  title: Text(project.name),
                  subtitle: Text(_formatOpenedAt(project.openedAt)),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !busy,
                  onTap: busy ? null : () => onOpenRecent(project),
                ),
              ),
          if (busy) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      );

  static String _formatOpenedAt(DateTime value) {
    if (value.millisecondsSinceEpoch == 0) return 'Recently opened';
    final local = value.toLocal();
    return 'Opened ${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
