import '../../bridge/project_snapshot.dart';

import 'library_category.dart';
import 'library_manifest.dart';
import 'library_midi_patterns.dart';

sealed class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> tags;
}

class LibraryAudioItem extends LibraryItem {
  const LibraryAudioItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.sample,
    this.isProjectClip = false,
    super.tags,
  });

  final SampleLibraryEntrySnapshot sample;
  final bool isProjectClip;
}

class LibraryMidiItem extends LibraryItem {
  const LibraryMidiItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.clip,
    this.trackId,
    this.isFactory = false,
    super.tags,
  });

  final String? trackId;
  final MidiClipSnapshot clip;
  final bool isFactory;
}

class LibraryAutomationItem extends LibraryItem {
  const LibraryAutomationItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.parameterLabel,
    this.trackId,
    this.clip,
    this.suggestedParamId,
    super.tags,
  });

  final String parameterLabel;
  final String? trackId;
  final AutomationClipSnapshot? clip;
  final String? suggestedParamId;
}

class LibraryPresetItem extends LibraryItem {
  const LibraryPresetItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.deviceType,
    super.tags,
  });

  final String deviceType;
}

abstract final class LibraryCatalog {
  static List<LibraryItem> itemsFor(
    LibraryCategory category,
    ProjectSnapshot snapshot, {
    LibraryManifest? manifest,
  }) {
    return switch (category) {
      LibraryCategory.audioClips => _audioItems(snapshot),
      LibraryCategory.midiClips => _midiItems(snapshot, manifest),
      LibraryCategory.automationClips => _automationItems(snapshot),
      LibraryCategory.devicePresets => presetItems(manifest),
    };
  }

  static List<LibraryPresetItem> presetItems(LibraryManifest? manifest) {
    if (manifest == null) {
      return const [];
    }
    return manifest.presets
        .map(
          (entry) => LibraryPresetItem(
            id: entry.id,
            title: entry.title,
            subtitle: entry.subtitle,
            deviceType: entry.deviceType,
            tags: entry.tags,
          ),
        )
        .toList();
  }

  static List<LibraryItem> _audioItems(ProjectSnapshot snapshot) {
    final items = <LibraryItem>[];
    for (final sample in snapshot.samples) {
      items.add(
        LibraryAudioItem(
          id: 'sample:${sample.id}',
          title: sample.name,
          subtitle: sample.source == 'bundled' ? 'Sample library' : 'Imported audio',
          sample: sample,
          tags: sample.source == 'bundled' ? const ['factory'] : const ['imported'],
        ),
      );
    }
    for (final track in snapshot.tracks) {
      for (final clip in track.sampleClips) {
        items.add(
          LibraryAudioItem(
            id: 'clip:${clip.id}',
            title: clip.sampleName.isEmpty ? 'Audio clip' : clip.sampleName,
            subtitle: '${track.name} · ${clip.lengthBeats.round()} beats',
            sample: SampleLibraryEntrySnapshot(
              id: clip.sampleId,
              name: clip.sampleName,
              source: 'project',
              durationBeats: clip.lengthBeats,
              waveformPeaks: clip.waveformPeaks,
            ),
            isProjectClip: true,
            tags: const ['project'],
          ),
        );
      }
    }
    return items;
  }

  static List<LibraryMidiItem> factoryMidiItems(LibraryManifest? manifest) {
    if (manifest == null) {
      return const [];
    }
    final items = <LibraryMidiItem>[];
    for (final entry in manifest.midiClips) {
      final pattern = LibraryMidiPatterns.patterns[entry.patternId];
      if (pattern == null) {
        continue;
      }
      items.add(
        LibraryMidiItem(
          id: entry.id,
          title: entry.title,
          subtitle: entry.subtitle,
          clip: pattern.toClip(entry.id),
          isFactory: true,
          tags: entry.tags,
        ),
      );
    }
    return items;
  }

  static List<LibraryItem> _midiItems(
    ProjectSnapshot snapshot,
    LibraryManifest? manifest,
  ) {
    final items = <LibraryItem>[...factoryMidiItems(manifest)];
    for (final track in snapshot.tracks) {
      for (final clip in track.midiClips) {
        items.add(
          LibraryMidiItem(
            id: 'midi:${clip.id}',
            title: 'MIDI clip',
            subtitle: '${track.name} · ${clip.notes.length} notes · ${clip.lengthBeats.round()} beats',
            trackId: track.id,
            clip: clip,
            tags: const ['project'],
          ),
        );
      }
    }
    return items;
  }

  static List<LibraryItem> _automationItems(ProjectSnapshot snapshot) {
    final items = <LibraryItem>[];
    for (final track in snapshot.tracks) {
      for (final clip in track.automationClips) {
        items.add(
          LibraryAutomationItem(
            id: 'auto-clip:${clip.id}',
            title: clip.isLinked ? clip.linkLabel : 'Automation clip',
            subtitle: '${track.name} · ${clip.lengthBeats.round()} beats',
            parameterLabel: clip.linkLabel,
            trackId: track.id,
            clip: clip,
          ),
        );
      }
    }
    if (items.isEmpty) {
      items.addAll(const [
        LibraryAutomationItem(
          id: 'auto:filter',
          title: 'Filter cutoff',
          subtitle: 'Synth/sampler filter sweep',
          parameterLabel: 'Filter',
          suggestedParamId: 'filterCutoff',
        ),
        LibraryAutomationItem(
          id: 'auto:gain',
          title: 'Gain',
          subtitle: 'Device output level',
          parameterLabel: 'Gain',
          suggestedParamId: 'gain',
        ),
        LibraryAutomationItem(
          id: 'auto:blank',
          title: 'Blank automation',
          subtitle: 'Create clip · tap Link to assign',
          parameterLabel: 'Link',
        ),
      ]);
    }
    return items;
  }
}
