import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import 'example_projects.dart';
import 'welcome_action_button.dart';
import 'welcome_recent_projects_panel.dart';
import 'welcome_theme.dart';

/// Full-screen project picker shown as a stacked page on top of [DawShell]
/// at launch. It is not part of the bottom nav / tab system: it is pushed
/// via [Navigator] and pops itself once a project becomes active.
class WelcomeHub extends StatefulWidget {
  const WelcomeHub({
    super.key,
    required this.recentProjects,
    required this.hasActiveProject,
    required this.onNewProject,
    required this.onOpenProject,
    required this.onOpenRecent,
    required this.onOpenExample,
    this.exampleProjects = kExampleProjects,
    this.onContinue,
  });

  final List<RecentProjectEntry> recentProjects;
  final List<ExampleProject> exampleProjects;
  final bool Function() hasActiveProject;
  final Future<void> Function() onNewProject;
  final Future<void> Function() onOpenProject;
  final Future<void> Function(RecentProjectEntry) onOpenRecent;
  final Future<void> Function(ExampleProject) onOpenExample;
  final Future<void> Function()? onContinue;

  @override
  State<WelcomeHub> createState() => _WelcomeHubState();
}

class _WelcomeHubState extends State<WelcomeHub> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
      return;
    }
    if (!mounted) return;
    if (widget.hasActiveProject()) {
      // Direct pop (not maybePop): PopScope.canPop is false to block the
      // hardware back button, but a successful action should always close
      // this stacked page regardless of that guard.
      Navigator.of(context).pop();
      return;
    }
    // Action completed without activating a project (e.g. the open-project
    // dialog was cancelled) — stay on the welcome screen.
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: WelcomeTheme.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _WelcomeHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    _buildActions(),
                    const SizedBox(height: WelcomeTheme.sectionGap),
                    const Text('RECENT PROJECTS', style: WelcomeTheme.sectionLabel),
                    const SizedBox(height: 10),
                    WelcomeRecentProjectsPanel(
                      examples: widget.exampleProjects,
                      recentProjects: widget.recentProjects,
                      busy: _busy,
                      onOpenExample: (example) => _run(() => widget.onOpenExample(example)),
                      onOpenRecent: (project) => _run(() => widget.onOpenRecent(project)),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _error!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final onContinue = widget.onContinue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onContinue != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WelcomeActionButton(
              key: const ValueKey('welcome-continue'),
              icon: Icons.play_arrow_rounded,
              label: widget.hasActiveProject() ? 'Continue Project' : 'Continue Last',
              emphasis: WelcomeActionEmphasis.primary,
              busy: _busy,
              onTap: () => _run(onContinue),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: WelcomeActionButton(
                key: const ValueKey('welcome-new-project'),
                icon: Icons.add_rounded,
                label: 'New Project',
                emphasis: onContinue == null
                    ? WelcomeActionEmphasis.primary
                    : WelcomeActionEmphasis.secondary,
                busy: _busy,
                onTap: () => _run(widget.onNewProject),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: WelcomeActionButton(
                key: const ValueKey('welcome-open-project'),
                icon: Icons.folder_open_rounded,
                label: 'Open Project',
                emphasis: WelcomeActionEmphasis.secondary,
                busy: _busy,
                onTap: () => _run(widget.onOpenProject),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: WelcomeTheme.accentSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WelcomeTheme.accent.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.graphic_eq_rounded, size: 28, color: WelcomeTheme.accent),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AudioApp',
                  style: TextStyle(
                    color: WelcomeTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Make something worth replaying',
                  style: TextStyle(color: WelcomeTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WelcomeTheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WelcomeTheme.error.withValues(alpha: 0.4)),
        ),
        child: Text(message, style: const TextStyle(color: WelcomeTheme.error, fontSize: 13)),
      );
}
