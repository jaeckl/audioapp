part of 'filter_mode_selector.dart';

class FilterModePrimaryOption {
  const FilterModePrimaryOption({
    required this.index,
    required this.curve,
    this.label,
  });

  final int index;
  final FilterCurveMode curve;

  /// Short face label (LP / HP / BP / NT). Null = icon only.
  final String? label;
}
