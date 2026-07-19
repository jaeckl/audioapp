/// Shared layout math for Spectral Loud Split card body.
///
/// Control column (inside elevated panel):
///   leftPad + solo + soloToggleGap + toggle + gap + knob + gap + vu
abstract final class SpectralLoudSplitLayout {
  static const double soloLeftPad = 4;
  static const double solo = 22;
  static const double soloToggleGap = 2;
  static const double toggle = 80; // SplitBranchToggleButton.width
  static const double knob = 52; // DeviceKnobSizes.compact + 8 chrome
  static const double vu = 12;
  static const double gap = 4;
  static const double previewMin = 200;
  static const double padH = 12; // 6×2 body pad
  /// Match device body top/bottom pad (6).
  static const double colGap = 6;

  static const double controlsWidth = soloLeftPad +
      solo +
      soloToggleGap +
      toggle +
      gap +
      knob +
      gap +
      vu;

  /// Body design width: pad + preview + gap + controls.
  static const double designWidth =
      padH + previewMin + colGap + controlsWidth;
}
