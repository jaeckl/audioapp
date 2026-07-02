import 'package:flutter/material.dart';

import 'curve_library_store.dart';

abstract final class CurveLibraryDialog {
  static Future<CurveLibraryResource?> pick(BuildContext context) async {
    final resources = await CurveLibraryStore.load();
    if (!context.mounted) return null;
    return showModalBottomSheet<CurveLibraryResource>(
      context: context,
      backgroundColor: const Color(0xFF181820),
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const ListTile(
              title: Text('Curve Library'),
              subtitle: Text('Load into the current editor'),
            ),
            for (final resource in resources)
              ListTile(
                leading: const Icon(Icons.show_chart),
                title: Text(resource.name),
                subtitle:
                    Text(resource.factory ? 'Factory curve' : 'User curve'),
                onTap: () => Navigator.pop(context, resource),
              ),
          ],
        ),
      ),
    );
  }

  static Future<String?> requestName(BuildContext context) async {
    final controller = TextEditingController(text: 'My Curve');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save curve'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result?.isEmpty == true ? null : result;
  }
}
