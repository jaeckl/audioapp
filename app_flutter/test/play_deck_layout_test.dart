import 'package:audioapp/features/play/play_deck_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayDeckLayout landscape sizing', () {
    test('portrait keeps full deck height and preferred octaves', () {
      const size = Size(400, 800);
      expect(PlayDeckLayout.isLandscape(size), isFalse);
      expect(PlayDeckLayout.deckHeightFor(size), PlayDeckLayout.deckHeight);
      expect(
        PlayDeckLayout.chromeHeightFor(size),
        PlayDeckLayout.deckHeight + PlayDeckLayout.modStripHeight,
      );
      expect(PlayDeckLayout.keyboardRowsFor(size, 1), 1);
      expect(PlayDeckLayout.defaultKeyboardRows, 1);
    });

    test('landscape caps chrome at 1/4 screen height', () {
      const size = Size(800, 400);
      expect(PlayDeckLayout.isLandscape(size), isTrue);
      final chrome = PlayDeckLayout.chromeHeightFor(size);
      expect(chrome, lessThanOrEqualTo(size.height * 0.25 + 0.001));
      expect(
        PlayDeckLayout.deckHeightFor(size),
        chrome - PlayDeckLayout.modStripHeight,
      );
    });

    test('landscape fits more octaves on wider keyboard', () {
      const size = Size(900, 400);
      expect(PlayDeckLayout.octaveCountForWidth(200), 1);
      expect(PlayDeckLayout.octaveCountForWidth(420), 2);
      expect(PlayDeckLayout.octaveCountForWidth(700), 3);
      expect(
        PlayDeckLayout.keyboardRowsFor(size, 1, keyboardWidth: 700),
        3,
      );
    });

    test('landscape without mod strip still ≤ 1/4', () {
      const size = Size(900, 360);
      final deck = PlayDeckLayout.deckHeightFor(size, showModStrip: false);
      expect(deck, lessThanOrEqualTo(size.height * 0.25 + 0.001));
      expect(deck, greaterThanOrEqualTo(PlayDeckLayout.landscapeMinDeckHeight));
    });
  });
}
