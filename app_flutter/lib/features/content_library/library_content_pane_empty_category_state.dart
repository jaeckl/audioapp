part of 'library_content_pane.dart';

class _EmptyCategoryState extends StatelessWidget {
  const _EmptyCategoryState({required this.category});

  final LibraryCategory category;

  @override
  Widget build(BuildContext context) {
    final message = switch (category) {
      LibraryCategory.audioClips =>
        'Import audio or add sample clips to the project.',
      LibraryCategory.midiClips =>
        'Factory loops and project clips appear here.',
      LibraryCategory.automationClips =>
        'Automation clips will appear here once recorded.',
      LibraryCategory.curves =>
        'Saved automation and modulation curves appear here.',
      LibraryCategory.devicePresets => 'Starter presets will be listed here.',
      LibraryCategory.wavetables => 'Bundled wavetables will be listed here.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: LibraryTheme.labelMuted),
        ),
      ),
    );
  }
}
