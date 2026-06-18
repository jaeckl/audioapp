import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../sample_library/sample_library_screen.dart';
import 'library_catalog.dart';
import 'library_category.dart';
import 'library_theme.dart';

class LibraryContentPane extends StatelessWidget {
  const LibraryContentPane({
    super.key,
    required this.category,
    required this.snapshot,
    required this.onPreviewAudio,
    required this.onInsertAudio,
    required this.onImportAudio,
    this.onMidiClipTap,
    this.onAutomationTap,
    this.onPresetTap,
  });

  final LibraryCategory category;
  final ProjectSnapshot snapshot;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewAudio;
  final ValueChanged<SampleLibraryEntrySnapshot> onInsertAudio;
  final VoidCallback onImportAudio;
  final void Function(LibraryMidiItem item)? onMidiClipTap;
  final void Function(LibraryAutomationItem item)? onAutomationTap;
  final void Function(LibraryPresetItem item)? onPresetTap;

  @override
  Widget build(BuildContext context) {
    final items = LibraryCatalog.itemsFor(category, snapshot);
    final theme = Theme.of(context);
    final accent = LibraryTheme.accentFor(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _headerTitle(category),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: LibraryTheme.labelMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (category == LibraryCategory.audioClips)
                IconButton(
                  tooltip: 'Import audio',
                  onPressed: onImportAudio,
                  icon: const Icon(Icons.upload_file_outlined, color: Colors.white70),
                ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _EmptyCategoryState(category: category)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _LibraryItemTile(
                    item: items[index],
                    accent: accent,
                    onPreviewAudio: onPreviewAudio,
                    onInsertAudio: onInsertAudio,
                    onMidiClipTap: onMidiClipTap,
                    onAutomationTap: onAutomationTap,
                    onPresetTap: onPresetTap,
                  ),
                ),
        ),
      ],
    );
  }

  static String _headerTitle(LibraryCategory category) => switch (category) {
        LibraryCategory.audioClips => 'Audio clips',
        LibraryCategory.midiClips => 'MIDI clips',
        LibraryCategory.automationClips => 'Automation clips',
        LibraryCategory.devicePresets => 'Device presets',
      };
}

class _EmptyCategoryState extends StatelessWidget {
  const _EmptyCategoryState({required this.category});

  final LibraryCategory category;

  @override
  Widget build(BuildContext context) {
    final message = switch (category) {
      LibraryCategory.audioClips => 'Import audio or add sample clips to the project.',
      LibraryCategory.midiClips => 'Create MIDI clips in the arrangement to see them here.',
      LibraryCategory.automationClips => 'Automation clips will appear here once recorded.',
      LibraryCategory.devicePresets => 'Starter presets will be listed here.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: LibraryTheme.labelMuted),
        ),
      ),
    );
  }
}

class _LibraryItemTile extends StatelessWidget {
  const _LibraryItemTile({
    required this.item,
    required this.accent,
    required this.onPreviewAudio,
    required this.onInsertAudio,
    this.onMidiClipTap,
    this.onAutomationTap,
    this.onPresetTap,
  });

  final LibraryItem item;
  final Color accent;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewAudio;
  final ValueChanged<SampleLibraryEntrySnapshot> onInsertAudio;
  final void Function(LibraryMidiItem item)? onMidiClipTap;
  final void Function(LibraryAutomationItem item)? onAutomationTap;
  final void Function(LibraryPresetItem item)? onPresetTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LibraryTheme.cardBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _handleTap(),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _LeadingVisual(item: item, accent: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ..._trailingActions(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    switch (item) {
      case final LibraryAudioItem audio when !audio.isProjectClip:
        onInsertAudio(audio.sample);
      case final LibraryMidiItem midi:
        onMidiClipTap?.call(midi);
      case final LibraryAutomationItem automation:
        onAutomationTap?.call(automation);
      case final LibraryPresetItem preset:
        onPresetTap?.call(preset);
      default:
        break;
    }
  }

  List<Widget> _trailingActions() {
    return switch (item) {
      final LibraryAudioItem audio when !audio.isProjectClip => [
          IconButton(
            tooltip: 'Preview',
            onPressed: () => onPreviewAudio(audio.sample),
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white70),
          ),
          FilledButton.tonal(
            onPressed: () => onInsertAudio(audio.sample),
            child: const Text('Insert'),
          ),
        ],
      LibraryMidiItem() => [
          Icon(Icons.north_west, size: 18, color: accent.withValues(alpha: 0.8)),
        ],
      LibraryAutomationItem() => [
          Icon(Icons.timeline, size: 18, color: accent.withValues(alpha: 0.8)),
        ],
      final LibraryPresetItem preset => [
          FilledButton.tonal(
            onPressed: () => onPresetTap?.call(preset),
            child: const Text('Load'),
          ),
        ],
      _ => const <Widget>[],
    };
  }
}

class _LeadingVisual extends StatelessWidget {
  const _LeadingVisual({required this.item, required this.accent});

  final LibraryItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      LibraryAudioItem(:final sample) => SizedBox(
          width: 96,
          height: 36,
          child: CustomPaint(
            painter: WaveformPainter(
              peaks: sample.waveformPeaks,
              color: accent,
            ),
          ),
        ),
      LibraryMidiItem(:final clip) => _BadgeBox(
          accent: accent,
          child: Text(
            '${clip.notes.length}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      LibraryAutomationItem() => _BadgeBox(
          accent: accent,
          child: Icon(Icons.show_chart, color: accent, size: 20),
        ),
      LibraryPresetItem(:final deviceType) => _BadgeBox(
          accent: accent,
          child: Icon(
            deviceType == 'simple_sampler' ? Icons.album_outlined : Icons.waves,
            color: accent,
            size: 20,
          ),
        ),
    };
  }
}

class _BadgeBox extends StatelessWidget {
  const _BadgeBox({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}
