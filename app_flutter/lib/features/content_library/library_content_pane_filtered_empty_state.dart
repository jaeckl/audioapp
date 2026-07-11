part of 'library_content_pane.dart';

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.onClear, required this.category});

  final VoidCallback onClear;
  final LibraryCategory category;

  @override
  Widget build(BuildContext context) {
    final label = category == LibraryCategory.midiClips
        ? 'No MIDI clips match these filters.'
        : 'No presets match these filters.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LibraryTheme.labelMuted,
                  ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
          ],
        ),
      ),
    );
  }
}
