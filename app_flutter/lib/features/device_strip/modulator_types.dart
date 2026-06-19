/// Wire values shared with the engine modulator model.
abstract final class ModulatorTypes {
  static const lfo = 0;
  static const adsr = 1;
  static const adr = 2;

  /// Matches engine [ModulationGraph::kMaxLfos].
  static const maxCount = 16;

  static const retriggerFree = 0;
  static const retriggerSync = 1;
  static const retriggerOnNote = 2;

  static const labels = ['LFO', 'ADSR', 'ADR'];
  static const retriggerLabels = ['Free', 'Sync', 'On note'];

  static String labelFor(int type) =>
      type >= 0 && type < labels.length ? labels[type] : 'Mod';

  static String retriggerLabelFor(int mode) =>
      mode >= 0 && mode < retriggerLabels.length ? retriggerLabels[mode] : 'Free';
}
