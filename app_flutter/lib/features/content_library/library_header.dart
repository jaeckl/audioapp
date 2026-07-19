import 'package:flutter/material.dart';

import '../welcome/welcome_theme.dart';
import 'library_theme.dart';

/// Page header with Library title, action button, and close — Project chrome.
class LibraryHeader extends StatelessWidget {
  const LibraryHeader({
    super.key,
    required this.onClose,
    this.selectedItemId,
    this.onInsert,
    required this.accent,
    this.title = 'Library',
    this.subtitle = 'Browse project resources',
    this.onSavePreset,
    this.updatePreset = false,
    this.actionLabel = 'Insert',
  });

  final Future<void> Function() onClose;
  final String? selectedItemId;
  final VoidCallback? onInsert;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback? onSavePreset;
  final bool updatePreset;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedItemId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: LibraryTheme.softFill(accent),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.library_music_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: WelcomeTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: WelcomeTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onSavePreset != null)
            IconButton(
              tooltip: updatePreset ? 'Update preset' : 'Save device preset',
              onPressed: onSavePreset,
              color: accent,
              icon: Icon(
                  updatePreset ? Icons.save_as_outlined : Icons.save_outlined),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: hasSelection ? accent : LibraryTheme.cardBackground,
              foregroundColor:
                  hasSelection ? Colors.white : WelcomeTheme.textMuted,
              disabledBackgroundColor: LibraryTheme.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: WelcomeTheme.panelBorder),
              ),
            ),
            onPressed: hasSelection ? onInsert : null,
            child: Text(actionLabel),
          ),
          IconButton(
            tooltip: 'Close library',
            onPressed: onClose,
            icon: const Icon(Icons.close, color: WelcomeTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
