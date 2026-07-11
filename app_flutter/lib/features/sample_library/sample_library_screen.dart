import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';

part 'sample_library_screen_private_sample_library_tile.dart';
part 'sample_library_screen_waveform_painter.dart';
part 'sample_library_screen_private_waveform_painter.dart';
part 'sample_library_screen_sample_library_picker_sheet.dart';
part 'sample_library_screen_private_sample_library_picker_sheet_state.dart';

class SampleLibraryScreen extends StatelessWidget {
  const SampleLibraryScreen({
    super.key,
    this.embedded = false,
    this.embeddedTitle,
    required this.samples,
    required this.onPreview,
    required this.onInsert,
    required this.onImport,
  });

  final bool embedded;
  final String? embeddedTitle;
  final List<SampleLibraryEntrySnapshot> samples;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreview;
  final ValueChanged<SampleLibraryEntrySnapshot> onInsert;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = samples.isEmpty
        ? Center(
            child: Text(
              'No samples yet',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: Colors.white38),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: samples.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sample = samples[index];
              return _SampleLibraryTile(
                sample: sample,
                onPreview: () => onPreview(sample),
                onInsert: () => onInsert(sample),
              );
            },
          );

    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              children: [
                Text(embeddedTitle ?? 'Library',
                    style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: 'Import audio',
                  onPressed: onImport,
                  icon: const Icon(Icons.upload_file_outlined),
                ),
              ],
            ),
          ),
          Expanded(child: list),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A22),
        title: const Text('Sample library'),
        actions: [
          IconButton(
            tooltip: 'Import audio',
            onPressed: onImport,
            icon: const Icon(Icons.upload_file_outlined),
          ),
        ],
      ),
      body: list,
    );
  }
}

/// Bottom-sheet sample picker with live refresh after import.
