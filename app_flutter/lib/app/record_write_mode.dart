enum RecordWriteMode {
  take('Take'),
  fresh('New'),
  overdub('Overdub'),
  replace('Replace');

  const RecordWriteMode(this.label);

  final String label;

  bool get targetsExisting =>
      this == RecordWriteMode.overdub || this == RecordWriteMode.replace;
}
