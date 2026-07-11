import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import 'example_projects.dart';
import 'welcome_action_button.dart';
import 'welcome_recent_projects_panel.dart';
import 'welcome_theme.dart';

part 'welcome_hub_private_welcome_hub_state.dart';
part 'welcome_hub_private_welcome_header.dart';
part 'welcome_hub_private_error_banner.dart';

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
