import 'dart:convert';

import 'package:audioapp/bridge/clip_snapshots.dart';
import 'package:audioapp/features/welcome/example_projects.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MIDI Take Comp Lab ships with multi-take open comps', () async {
    final example = kExampleProjects.firstWhere(
      (e) => e.id == 'example-midi-take-comp-lab',
    );
    final raw = await rootBundle.loadString(example.assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    expect(data['name'], 'MIDI Take Comp Lab');

    final tracks = data['tracks'] as List<dynamic>;
    MidiClipSnapshot? openKeys;
    MidiClipSnapshot? openBass;
    MidiClipSnapshot? flatPad;

    for (final track in tracks) {
      final trackMap = track as Map<String, dynamic>;
      for (final clipRaw in trackMap['midiClips'] as List<dynamic>? ?? const []) {
        final clip = MidiClipSnapshot.fromMap(clipRaw as Map<dynamic, dynamic>);
        if (clip.id == 'keys-comp-open') openKeys = clip;
        if (clip.id == 'bass-comp-open') openBass = clip;
        if (clip.id == 'pad-comp-flat') flatPad = clip;
      }
    }

    expect(openKeys, isNotNull);
    expect(openKeys!.takes.length, 3);
    expect(openKeys.activeTakeRegions.length, 4);
    expect(openKeys.compFlattened, isFalse);
    expect(openKeys.notes, isNotEmpty);

    expect(openBass, isNotNull);
    expect(openBass!.takes.length, 2);
    expect(openBass.activeTakeRegions.length, 2);
    expect(openBass.compFlattened, isFalse);

    expect(flatPad, isNotNull);
    expect(flatPad!.takes.length, 2);
    expect(flatPad.compFlattened, isTrue);

    for (final region in openKeys.activeTakeRegions) {
      expect(
        openKeys.takes.any((take) => take.id == region.takeId),
        isTrue,
        reason: 'region takeId ${region.takeId} missing from takes',
      );
    }
  });
}
