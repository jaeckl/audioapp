import 'dart:ui' show Size;

import '../music_theory/chord_quality.dart';

export '../music_theory/chord_quality.dart';

part 'play_deck_layout_play_surface_mode.dart';
part 'play_deck_layout_play_context_view.dart';
part 'play_deck_layout_arp_mode.dart';
part 'play_deck_layout_capture_quantize.dart';
part 'play_deck_layout_chord_memory.dart';

part 'play_deck_layout_arp_mode_label.dart';
part 'play_deck_layout_capture_quantize_label.dart';

/// Mode toggle for the rail (keyboard/pads switch).
/// What is currently filling the play area next to the rail.
class PlayDeckLayout {
  const PlayDeckLayout._();

  static const double deckHeight = 280;
  static const double landscapeMinDeckHeight = 72;
  static const double modStripHeight = 22;
  static const double keyCellMinSize = 40;
  static const double minWhiteKeyWidth = 28;
  static const int keyMaxColumns = 8;
  static const int defaultKeyboardRows = 1;
  static const int maxKeyboardOctaves = 3;

  /// Portrait chrome (deck + mod strip). Prefer [chromeHeightFor] when size known.
  static double get chromeHeight => deckHeight + modStripHeight;

  static bool isLandscape(Size size) => size.width > size.height;

  /// Landscape: deck + optional mod strip ≤ 1/4 screen height.
  static double deckHeightFor(Size size, {bool showModStrip = true}) {
    if (!isLandscape(size)) return deckHeight;
    final mod = showModStrip ? modStripHeight : 0.0;
    final maxDeck = size.height * 0.25 - mod;
    return maxDeck.clamp(landscapeMinDeckHeight, deckHeight);
  }

  static double chromeHeightFor(Size size, {bool showModStrip = true}) {
    final deck = deckHeightFor(size, showModStrip: showModStrip);
    return deck + (showModStrip ? modStripHeight : 0.0);
  }

  /// Fit as many octaves as white-key width allows (1–3).
  static int octaveCountForWidth(double width) {
    if (width <= 0) return 1;
    final whites = (width / minWhiteKeyWidth).floor();
    return (whites ~/ 7).clamp(1, maxKeyboardOctaves);
  }

  /// Portrait: user preference. Landscape: width-fit (more keys on wide screens).
  static int keyboardRowsFor(
    Size size,
    int preferredRows, {
    double? keyboardWidth,
  }) {
    if (isLandscape(size)) {
      return octaveCountForWidth(keyboardWidth ?? size.width);
    }
    return preferredRows.clamp(1, maxKeyboardOctaves);
  }
}
