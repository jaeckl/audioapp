/// Shared layout math for multiband split cards.
///
/// Band column stacks toggle (80) above knob (52) → column width = 80.
/// Between columns: 6. Horizontal pad: 8×2 = 16. Accent stripes: 4×2 = 8.
abstract final class MbSplitLayout {
  static const double bandCol = 80;
  static const double colGap = 6;
  static const double padH = 16;
  static const double stripes = 8;

  static double designWidth(int bandCount) {
    final cols = bandCount.clamp(2, 4);
    return padH + cols * bandCol + (cols - 1) * colGap + stripes;
  }
}
