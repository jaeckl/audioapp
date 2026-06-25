/// Wire values shared with the engine modulator model.
abstract final class ModulatorTypes {
  static const lfo = 0;
  static const envelope = 1;
  static const randomGenerator = 2;
  static const sequencer = 3;

  /// Matches engine [ModulationGraph::kMaxLfos].
  static const maxCount = 16;

  static const retriggerFree = 0;
  static const retriggerSync = 1;
  static const retriggerOnNote = 2;

  static const labels = ['LFO', 'Envelope', 'Random Generator'];
  static const retriggerLabels = ['Free', 'Sync', 'On note'];
  static const curveLabels = ['ADSR', 'ASR', 'ADR', 'AHDSR'];

  static const sequencerDirectionLabels = ['Fwd', 'Rev', 'P-P', 'Rnd'];
  static const sequencerShapeLabels = ['Hold', 'Lin', 'Smth'];

  static String labelFor(int type) => switch (type) {
    0 => 'LFO',
    1 => 'ENV',
    2 => 'RND',
    3 => 'SEQ',
    _ => '?',
  };

  static String retriggerLabelFor(int mode) =>
      mode >= 0 && mode < retriggerLabels.length ? retriggerLabels[mode] : 'Free';
}