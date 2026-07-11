part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateSavepresetOperation on LibraryFlyInPanelState {
Future<void> _savePreset() async {
    final capture = widget.onCaptureDevicePreset;
    final type = widget.presetDeviceType;
    if (capture == null || type == null) return;
    final selected = _selectedUserPreset;
    if (selected != null) {
      final json = await capture();
      await UserDevicePresetStore.save(
          UserDevicePreset(id: selected.id, name: selected.title, deviceType: type, presetJson: json, updatedAt: DateTime.now().millisecondsSinceEpoch));
      if (mounted) setState(() {});
      return;
    }
    final controller = TextEditingController();
    final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                backgroundColor: LibraryTheme.panelBackground,
                title: const Text('Save device preset'),
                content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Preset name')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isNotEmpty) Navigator.pop(context, value);
                      },
                      child: const Text('Save'))
                ]));
    controller.dispose();
    if (name == null) return;
    final json = await capture();
    final id = 'user-preset:${DateTime.now().microsecondsSinceEpoch}';
    await UserDevicePresetStore.save(
        UserDevicePreset(id: id, name: name, deviceType: type, presetJson: json, updatedAt: DateTime.now().millisecondsSinceEpoch));
    if (mounted) setState(() => _selectedItemId = id);
  }
}
