import '../../bridge/project_snapshot.dart';

import 'library_category.dart';

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
    this.trackId,
    this.clip,
    this.suggestedParamId,
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
      LibraryPresetItem(
        id: 'preset:synth-init',
        title: 'Init synth',
        subtitle: 'Saw · open filter',
        deviceType: 'subtractive_synth',
      ),
      LibraryPresetItem(
        id: 'preset:synth-warm-pad',
        title: 'Warm pad',
        subtitle: 'Unison · slow attack',
        deviceType: 'subtractive_synth',
      ),
      LibraryPresetItem(
        id: 'preset:synth-pluck',
        title: 'Pluck',
        subtitle: 'Short amp · filter sweep',
        deviceType: 'subtractive_synth',
      ),
      LibraryPresetItem(
        id: 'preset:synth-bass',
        title: 'Synth bass',
        subtitle: 'Square + saw stack',
        deviceType: 'subtractive_synth',
      ),
      LibraryPresetItem(
        id: 'preset:synth-lead',
        title: 'Detuned lead',
        subtitle: 'AM mix · glide',
        deviceType: 'subtractive_synth',
      ),
      LibraryPresetItem(
        id: 'preset:synth-noise-sweep',
        title: 'Noise sweep',
        subtitle: 'Filter env texture',
        deviceType: 'subtractive_synth',
      ),
    ];
  }
}
