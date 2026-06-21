import 'package:flutter/material.dart';

/// Page header with Library title, global Insert button, and close icon.
class LibraryHeader extends StatelessWidget {
  const LibraryHeader({
    super.key,
    required this.onClose,
    this.selectedItemId,
    this.onInsert,
    required this.accent,
  });

  final Future<void> Function() onClose;
  final String? selectedItemId;
  final VoidCallback? onInsert;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedItemId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
      child: Row(
        children: [
          Text(
            'Library',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: hasSelection ? onInsert : null,
            child: Text(
              'Insert',
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