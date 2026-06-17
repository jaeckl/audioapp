import '../../bridge/project_snapshot.dart';import 'library_category.dart';

sealed class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

class LibraryAudioItem extends LibraryItem {
  const LibraryAudioItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.sample,
    this.isProjectClip = false,
  });

  final SampleLibraryEntrySnapshot sample;
  final bool isProjectClip;
}

class LibraryMidiItem extends LibraryItem {
  const LibraryMidiItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.trackId,
    required this.clip,
  });

  final String trackId;
  final MidiClipSnapshot clip;
}

class LibraryAutomationItem extends LibraryItem {
  const LibraryAutomationItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.parameterLabel,
  });

  final String parameterLabel;
}

class LibraryPresetItem extends LibraryItem {
  const LibraryPresetItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.deviceType,
  });

  final String deviceType;
}

abstract final class LibraryCatalog {
  static List<LibraryItem> itemsFor(
    LibraryCategory category,
    ProjectSnapshot snapshot,
  ) {
    return switch (category) {
      LibraryCategory.audioClips => _audioItems(snapshot),
      LibraryCategory.midiClips => _midiItems(snapshot),
      LibraryCategory.automationClips => _automationItems(snapshot),
      LibraryCategory.devicePresets => _presetItems(snapshot),
    };
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
          ),
        );
      }
    }
    return items;
  }

  static List<LibraryItem> _midiItems(ProjectSnapshot snapshot) {
    final items = <LibraryItem>[];
    for (final track in snapshot.tracks) {
      for (final clip in track.midiClips) {
        items.add(
          LibraryMidiItem(
            id: 'midi:${clip.id}',
            title: 'MIDI clip',
            subtitle: '${track.name} · ${clip.notes.length} notes · ${clip.lengthBeats.round()} beats',
            trackId: track.id,
            clip: clip,
          ),
        );
      }
    }
    return items;
  }

  static List<LibraryItem> _automationItems(ProjectSnapshot snapshot) {
    if (snapshot.tracks.isEmpty) {
      return const [];
    }
    return [
      const LibraryAutomationItem(
        id: 'auto:volume',
        title: 'Volume lane',
        subtitle: 'Master track automation',
        parameterLabel: 'Volume',
      ),
      const LibraryAutomationItem(
        id: 'auto:filter',
        title: 'Filter cutoff',
        subtitle: 'Sampler filter sweep',
        parameterLabel: 'Filter',
      ),
      const LibraryAutomationItem(
        id: 'auto:send',
        title: 'Send A',
        subtitle: 'Aux send level',
        parameterLabel: 'Send',
      ),
    ];
  }

  static List<LibraryItem> _presetItems(ProjectSnapshot snapshot) {
    return const [
      LibraryPresetItem(
        id: 'preset:sampler-warm',
        title: 'Warm sampler',
        subtitle: 'Punchy kit · short env',
        deviceType: 'simple_sampler',
      ),
      LibraryPresetItem(
        id: 'preset:sampler-lofi',
        title: 'Lo-fi keys',
        subtitle: 'Filtered piano stack',
        deviceType: 'simple_sampler',
      ),
      LibraryPresetItem(
        id: 'preset:osc-pluck',
        title: 'Pluck oscillator',
        subtitle: 'Bright mono lead',
        deviceType: 'simple_oscillator',
      ),
      LibraryPresetItem(
        id: 'preset:osc-bass',
        title: 'Sub bass',
        subtitle: 'Low sine foundation',
        deviceType: 'simple_oscillator',
      ),
    ];
  }
}
