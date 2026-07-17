import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/engine_bridge.dart';
import 'welcome_theme.dart';

class ProjectWorkspaceBrowser extends StatefulWidget {
  const ProjectWorkspaceBrowser({
    super.key,
    required this.bridge,
    this.saveMode = false,
  });

  final EngineBridge bridge;
  final bool saveMode;

  @override
  State<ProjectWorkspaceBrowser> createState() =>
      _ProjectWorkspaceBrowserState();
}

class _FolderLevel {
  const _FolderLevel(this.uri, this.name);
  final String uri;
  final String name;
}

class _ProjectWorkspaceBrowserState extends State<ProjectWorkspaceBrowser> {
  final List<_FolderLevel> _path = [];
  List<ProjectWorkspaceEntry> _entries = const [];
  bool _loading = true;
  String? _workspaceUri;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listing = await widget.bridge
          .projectWorkspaceEntries(_path.isEmpty ? null : _path.last.uri);
      if (!mounted) return;
      setState(() {
        _workspaceUri = listing.workspaceUri;
        _entries = [...listing.entries]..sort((a, b) =>
            a.isDirectory == b.isDirectory
                ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
                : (a.isDirectory ? -1 : 1));
        _loading = false;
      });
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message ?? e.code;
          _loading = false;
        });
      }
    }
  }

  Future<void> _chooseWorkspace() async {
    if (await widget.bridge.chooseProjectWorkspace()) {
      _path.clear();
      await _refresh();
    }
  }

  Future<void> _openExternal() async {
    if (widget.saveMode) {
      final location = await widget.bridge.saveProject();
      if (location != null && mounted) {
        Navigator.of(context).pop(location);
      }
      return;
    }
    final snapshot = await widget.bridge.loadProject();
    if (snapshot != null && mounted) {
      Navigator.of(context).pop(snapshot);
    }
  }

  Future<void> _saveHere() async {
    var projectName = 'project';
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WelcomeTheme.panelBackground,
        title: const Text('Save project',
            style: TextStyle(color: WelcomeTheme.textPrimary)),
        content: TextFormField(
          key: const ValueKey('project-workspace-name'),
          initialValue: projectName,
          autofocus: true,
          style: const TextStyle(color: WelcomeTheme.textPrimary),
          decoration: const InputDecoration(
              labelText: 'Project name', suffixText: '.audioapp.zip'),
          onChanged: (value) => projectName = value,
          onFieldSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(projectName),
              child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final folderUri = _path.isEmpty ? _workspaceUri! : _path.last.uri;
      final location =
          await widget.bridge.saveProjectToWorkspace(folderUri, name);
      if (mounted) Navigator.of(context).pop(location);
    } on PlatformException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message ?? e.code;
          _loading = false;
        });
    }
  }

  Future<void> _open(ProjectWorkspaceEntry entry) async {
    if (entry.isDirectory) {
      _path.add(_FolderLevel(entry.uri, entry.name));
      await _refresh();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await widget.bridge.loadWorkspaceProject(entry.uri);
      if (mounted) Navigator.of(context).pop(snapshot);
    } on PlatformException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message ?? e.code;
          _loading = false;
        });
    }
  }

  void _up() {
    if (_path.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    _path.removeLast();
    _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WelcomeTheme.background,
        appBar: AppBar(
          backgroundColor: WelcomeTheme.panelBackground,
          foregroundColor: WelcomeTheme.textPrimary,
          elevation: 0,
          leading: IconButton(
              onPressed: _up, icon: const Icon(Icons.arrow_back_rounded)),
          title: Text(widget.saveMode
              ? (_path.isEmpty ? 'Save Project' : _path.last.name)
              : (_path.isEmpty ? 'Projects' : _path.last.name)),
          actions: [
            IconButton(
              key: const ValueKey('project-workspace-change'),
              tooltip: 'Change project workspace',
              onPressed: _loading ? null : _chooseWorkspace,
              icon: const Icon(Icons.drive_folder_upload_outlined),
            ),
            if (widget.saveMode && _workspaceUri != null)
              IconButton(
                key: const ValueKey('project-workspace-save-here'),
                tooltip: 'Save in this folder',
                onPressed: _loading ? null : _saveHere,
                icon: const Icon(Icons.save_rounded),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(children: [
            _WorkspacePath(path: _path),
            if (_error != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: WelcomeTheme.error.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: WelcomeTheme.error),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_error!,
                          style:
                              const TextStyle(color: WelcomeTheme.textPrimary)))
                ]),
              ),
            Expanded(child: _buildContent()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: OutlinedButton.icon(
                key: const ValueKey('project-import-external'),
                onPressed: _loading ? null : _openExternal,
                icon: const Icon(Icons.cloud_download_outlined),
                label: Text(widget.saveMode
                    ? 'Save somewhere else'
                    : 'Import from phone or cloud'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: WelcomeTheme.textPrimary,
                    side: const BorderSide(color: WelcomeTheme.panelBorder)),
              ),
            ),
          ]),
        ),
      );

  Widget _buildContent() {
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: WelcomeTheme.accent));
    if (_workspaceUri == null) {
      return _EmptyWorkspace(onChoose: _chooseWorkspace);
    }
    if (_entries.isEmpty) {
      return const Center(
          child: Text('No AudioApp projects in this folder',
              style: TextStyle(color: WelcomeTheme.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final entry = _entries[index];
        return Material(
          color: WelcomeTheme.panelBackground,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            key: ValueKey('workspace-entry-${entry.uri}'),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(
                entry.isDirectory
                    ? Icons.folder_rounded
                    : Icons.graphic_eq_rounded,
                color: entry.isDirectory
                    ? WelcomeTheme.accent
                    : WelcomeTheme.textPrimary),
            title: Text(entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: WelcomeTheme.textPrimary,
                    fontWeight: FontWeight.w600)),
            subtitle: Text(entry.isDirectory ? 'Folder' : 'AudioApp project',
                style: const TextStyle(color: WelcomeTheme.textMuted)),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: WelcomeTheme.textMuted),
            onTap: entry.isDirectory || !widget.saveMode
                ? () => _open(entry)
                : null,
          ),
        );
      },
    );
  }
}

class _WorkspacePath extends StatelessWidget {
  const _WorkspacePath({required this.path});
  final List<_FolderLevel> path;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: WelcomeTheme.panelBackground,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Text(
            ['PROJECT WORKSPACE', ...path.map((e) => e.name)].join('  /  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WelcomeTheme.sectionLabel),
      );
}

class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace({required this.onChoose});
  final VoidCallback onChoose;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.folder_special_outlined,
                size: 58, color: WelcomeTheme.accent),
            const SizedBox(height: 18),
            const Text('Choose your project workspace',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: WelcomeTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
                'AudioApp will show folders and projects from this location in its own browser.',
                textAlign: TextAlign.center,
                style: TextStyle(color: WelcomeTheme.textMuted, height: 1.4)),
            const SizedBox(height: 22),
            FilledButton.icon(
                key: const ValueKey('project-workspace-choose'),
                onPressed: onChoose,
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Choose workspace'),
                style: FilledButton.styleFrom(
                    backgroundColor: WelcomeTheme.accent,
                    minimumSize: const Size(210, 48))),
          ]),
        ),
      );
}
