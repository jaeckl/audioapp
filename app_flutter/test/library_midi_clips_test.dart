import 'dart:convert';

import 'package:audioapp/features/content_library/library_catalog.dart';
import 'package:audioapp/features/content_library/library_manifest.dart';
import 'package:audioapp/features/content_library/library_midi_patterns.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('manifest defines 25 factory midi clips with valid patterns', () async {
    final raw = await rootBundle.loadString('assets/content_library/manifest.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final manifest = LibraryManifest.fromJson(json);

    expect(manifest.midiClips.length, 25);

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

    expect(items.length, 25);

    int tagged(String tag) =>
        items.where((item) => item.tags.contains(tag)).length;

    expect(tagged('bass'), 5);
    expect(tagged('chords'), 5);
    expect(tagged('pad'), 5);
    expect(tagged('melody'), 10);
    expect(tagged('factory'), 25);
  });
}
