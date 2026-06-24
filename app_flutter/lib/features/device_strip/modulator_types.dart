/// Wire values shared with the engine modulator model.
abstract final class ModulatorTypes {
  static const lfo = 0;
  static const envelope = 1;
  static const randomGenerator = 2;

  /// Matches engine [ModulationGraph::kMaxLfos].
  static const maxCount = 16;

  static const retriggerFree = 0;
  static const retriggerSync = 1;
  static const retriggerOnNote = 2;

  static const labels = ['LFO', 'Envelope'];
  static const retriggerLabels = ['Free', 'Sync', 'On note'];

  /// Curve shape labels for the unified envelope modulator.
  static const curveLabels = ['ADSR', 'ASR', 'ADR', 'AHDSR'];

  static String labelFor(int type) => switch (type) {
    0 => 'LFO',
    1 => 'ENV',
    2 => 'RND',
    _ => '?',
  };

  static String retriggerLabelFor(int mode) =>
      mode >= 0 && mode < retriggerLabels.length ? retriggerLabels[mode] : 'Free';
}