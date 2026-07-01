export 'panels/filter_mode_icons.dart'
    show FilterCurveMode, FilterModeIconButton, FilterModeIconGrid, FilterCurveIconPainter;

import 'panels/filter_mode_icons.dart';

/// Legacy alias — prefer [FilterCurveMode].
typedef SamplerFilterModeKind = FilterCurveMode;

extension SamplerFilterModeKindIndex on FilterCurveMode {
  int get engineIndex => index;

  static FilterCurveMode fromIndex(int index) {
    return FilterCurveMode.values[index.clamp(0, FilterCurveMode.values.length - 1)];
  }
}

/// Legacy alias — prefer [FilterModeIconButton].
typedef SamplerFilterModeButton = FilterModeIconButton;

/// Legacy alias — prefer [FilterModeIconGrid].
typedef SamplerFilterModeBar = FilterModeIconGrid;
