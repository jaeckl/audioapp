import 'dart:convert';

import 'package:audioapp/features/content_library/library_catalog.dart';
import 'package:audioapp/features/content_library/library_manifest.dart';
import 'package:audioapp/features/content_library/library_midi_patterns.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('manifest defines factory midi clips with valid patterns', () async {
    final raw = await rootBundle.loadString('assets/content_library/manifest.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final manifest = LibraryManifest.fromJson(json);

    expect(manifest.midiClips.length, 182);

    for (final entry in manifest.midiClips) {
      expect(entry.id, isNotEmpty);
      expect(entry.patternId, isNotEmpty);
      expect(
        LibraryMidiPatterns.patterns.containsKey(entry.patternId),
        isTrue,
        reason: 'Missing pattern for ${entry.id}',
      );
      final pattern = LibraryMidiPatterns.patterns[entry.patternId]!;
      expect(pattern.notes, isNotEmpty);
      expect(pattern.lengthBeats, greaterThan(0));
    }
  });

  test('factory midi catalog groups match requested counts', () async {
    final raw = await rootBundle.loadString('assets/content_library/manifest.json');
    final manifest = LibraryManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final items = LibraryCatalog.factoryMidiItems(manifest);

    expect(items.length, 182);

    int tagged(String tag) =>
        items.where((item) => item.tags.contains(tag)).length;

    expect(tagged('bass'), 5);
    expect(tagged('chords'), 5);
    expect(tagged('pad'), 5);
    expect(tagged('melody'), 10);
    expect(tagged('drums'), 157);
    expect(tagged('factory'), 182);
    expect(tagged('electro'), 17);
    expect(tagged('house'), 16);
    expect(tagged('trap'), 16);
    expect(tagged('breakbeat'), 16);
  });

  test('drum midi clips use drum-machine pad pitches', () async {
    final raw = await rootBundle.loadString('assets/content_library/manifest.json');
    final manifest = LibraryManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final drumEntries =
        manifest.midiClips.where((e) => e.tags.contains('drums'));

    for (final entry in drumEntries) {
      final pattern = LibraryMidiPatterns.patterns[entry.patternId]!;
      for (final note in pattern.notes) {
        expect(
          note.pitch,
          inInclusiveRange(36, 51),
          reason: '${entry.patternId} pitch ${note.pitch} outside pad map',
        );
      }
    }
  });
}
