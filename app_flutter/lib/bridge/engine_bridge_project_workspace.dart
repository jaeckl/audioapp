part of 'engine_bridge.dart';

class ProjectWorkspaceEntry {
  const ProjectWorkspaceEntry(this.uri, this.name, this.isDirectory);
  final String uri;
  final String name;
  final bool isDirectory;
  factory ProjectWorkspaceEntry.fromMap(Map<dynamic, dynamic> value) =>
      ProjectWorkspaceEntry(value['uri'] as String, value['name'] as String,
          value['directory'] == true);
}

class ProjectWorkspaceListing {
  const ProjectWorkspaceListing(
      {required this.workspaceUri, required this.entries});
  final String? workspaceUri;
  final List<ProjectWorkspaceEntry> entries;
}

extension EngineBridgeProjectWorkspace on EngineBridge {
  Future<bool> chooseProjectWorkspace() async {
    final result = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('chooseProjectWorkspace');
    return result?['ok'] == true;
  }

  Future<ProjectWorkspaceListing> projectWorkspaceEntries(
      [String? folderUri]) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getProjectWorkspaceEntries', {'folderUri': folderUri});
    final entries = ((result?['entries'] as List?) ?? const [])
        .map((entry) =>
            ProjectWorkspaceEntry.fromMap(entry as Map<dynamic, dynamic>))
        .toList();
    return ProjectWorkspaceListing(
      workspaceUri: result?['workspaceUri'] as String?,
      entries: entries,
    );
  }

  Future<ProjectSnapshot> loadWorkspaceProject(String uri) =>
      _invokeForSnapshot('loadWorkspaceProject', {'uri': uri});

  Future<String> saveProjectToWorkspace(String folderUri, String name) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'saveProjectToWorkspace',
      {'folderUri': folderUri, 'name': name},
    );
    if (result?['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'save_failed',
        message: 'Failed to save project in workspace',
      );
    }
    return result!['uri'] as String;
  }
}
