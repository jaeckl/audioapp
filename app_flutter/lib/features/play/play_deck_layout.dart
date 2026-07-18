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
  static const double modStripHeight = 22;
  static const double keyCellMinSize = 40;
  static const int keyMaxColumns = 8;
  static const int defaultKeyboardRows = 2;

  static double get chromeHeight => deckHeight + modStripHeight;
}
