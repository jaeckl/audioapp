/// Which editing tool panel is active in the MIDI editor.
/// Comp replaces the center view.
/// Piano: Notes / Harmonic / Progression / Rhythm share the roll.
/// Drums: Notes / Pattern / Groove / Fill share the roll.
enum PianoRollCenterMode {
  notes,
  harmonic,
  progression,
  rhythm,
  pattern,
  groove,
  fill,
  comp,
}

