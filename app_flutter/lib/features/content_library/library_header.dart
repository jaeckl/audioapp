import 'package:flutter/material.dart';

/// Page header with Library title, global Insert button, and close icon.
class LibraryHeader extends StatelessWidget {
  const LibraryHeader({
    super.key,
    required this.onClose,
    this.selectedItemId,
    this.onInsert,
    required this.accent,
    this.title = 'Library',
    this.onSavePreset,
    this.updatePreset = false,
    this.actionLabel = 'Insert',
  });

  final Future<void> Function() onClose;
  final String? selectedItemId;
  final VoidCallback? onInsert;
  final Color accent;
  final String title;
  final VoidCallback? onSavePreset;
  final bool updatePreset;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedItemId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          if (onSavePreset != null)
            IconButton(
              tooltip: updatePreset ? 'Update preset' : 'Save device preset',
              onPressed: onSavePreset,
              color: accent,
              icon: Icon(
                  updatePreset ? Icons.save_as_outlined : Icons.save_outlined),
            ),
          FilledButton(
            onPressed: hasSelection ? onInsert : null,
            child: Text(
              actionLabel,
              style: TextStyle(
                color: hasSelection ? Colors.white : Colors.white38,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Close library',
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
