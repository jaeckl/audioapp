part of 'welcome_hub.dart';

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
                    const Text('RECENT PROJECTS',
                        style: WelcomeTheme.sectionLabel),
                    const SizedBox(height: 10),
                    WelcomeRecentProjectsPanel(
                      examples: widget.exampleProjects,
                      recentProjects: widget.recentProjects,
                      busy: _busy,
                      onOpenExample: (example) =>
                          _run(() => widget.onOpenExample(example)),
                      onOpenRecent: (project) =>
                          _run(() => widget.onOpenRecent(project)),
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
              label: widget.hasActiveProject()
                  ? 'Continue Project'
                  : 'Continue Last',
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
