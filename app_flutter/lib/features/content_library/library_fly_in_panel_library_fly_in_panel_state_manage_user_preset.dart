part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateManageuserpresetOperation on LibraryFlyInPanelState {
Future<void> _manageUserPreset(LibraryPresetItem preset) async {
    final action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: LibraryTheme.panelBackground,
        builder: (context) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Rename'), onTap: () => Navigator.pop(context, 'rename')),
              ListTile(leading: const Icon(Icons.save_as_outlined), title: const Text('Overwrite'), onTap: () => Navigator.pop(context, 'overwrite')),
              ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  onTap: () => Navigator.pop(context, 'delete')),
            ])));
    if (action == 'delete') {
      await UserDevicePresetStore.delete(preset.id);
      if (mounted)
        setState(() {
          if (_selectedItemId == preset.id) _selectedItemId = null;
        });
    } else if (action == 'overwrite') {
      setState(() => _selectedItemId = preset.id);
      await _savePreset();
    } else if (action == 'rename') {
      final controller = TextEditingController(text: preset.title);
      final name = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
                  backgroundColor: LibraryTheme.panelBackground,
                  title: const Text('Rename preset'),
                  content: TextField(controller: controller, autofocus: true),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () {
                          final v = controller.text.trim();
                          if (v.isNotEmpty) Navigator.pop(context, v);
                        },
                        child: const Text('Rename'))
                  ]));
      controller.dispose();
      if (name != null) {
        await UserDevicePresetStore.rename(preset.id, name);
        if (mounted) setState(() {});
      }
    }
  }
}
