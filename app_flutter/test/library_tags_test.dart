import 'package:audioapp/features/content_library/library_tags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('libraryItemMatchesTagFilter', () {
    const warmPad = ['pad', 'warm', 'factory'];
    const synthBass = ['bass', 'dark', 'factory'];
    const pluck = ['pluck', 'bright', 'factory'];

    test('empty selection matches all', () {
      expect(libraryItemMatchesTagFilter(warmPad, {}), isTrue);
    });

    test('single role tag filters', () {
      expect(libraryItemMatchesTagFilter(warmPad, {'pad'}), isTrue);
      expect(libraryItemMatchesTagFilter(synthBass, {'pad'}), isFalse);
    });

    test('AND across groups', () {
      expect(libraryItemMatchesTagFilter(warmPad, {'pad', 'warm'}), isTrue);
      expect(libraryItemMatchesTagFilter(warmPad, {'pad', 'bright'}), isFalse);
      expect(libraryItemMatchesTagFilter(pluck, {'pluck', 'bright'}), isTrue);
    });

    test('OR within group', () {
      expect(
        libraryItemMatchesTagFilter(warmPad, {'pad', 'bass'}),
        isTrue,
      );
      expect(
        libraryItemMatchesTagFilter(synthBass, {'pad', 'bass'}),
        isTrue,
      );
    });
  });

  group('libraryTagsPresentIn', () {
    test('returns tags in group order', () {
      final tags = libraryTagsPresentIn([
        ['bass', 'factory'],
        ['pad', 'warm', 'factory'],
      ]);
      expect(tags, contains('bass'));
      expect(tags, contains('pad'));
      expect(tags, contains('warm'));
      expect(tags.indexOf('pad'), lessThan(tags.indexOf('warm')));
    });
  });
}
