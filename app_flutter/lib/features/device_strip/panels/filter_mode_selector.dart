import 'package:flutter/material.dart';

import 'device_panel_theme.dart';
import 'filter_mode_icons.dart';

part 'filter_mode_selector_filter_mode_primary_option.dart';
part 'filter_mode_selector_filter_mode_overflow_option.dart';
part 'filter_mode_selector_filter_mode_selector_layout.dart';
part 'filter_mode_selector_mode_cell.dart';
part 'filter_mode_selector_overflow_cell.dart';

/// Maps an engine mode index to a curve icon in the mode row.
/// Extra filter modes shown in a popup (e.g. Subtractive FB / LP 24).
/// Unified filter mode picker — curve icons + optional overflow menu.
class FilterModeSelector extends StatelessWidget {
  const FilterModeSelector({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.accentColor,
    this.layout = FilterModeSelectorLayout.iconRow,
    this.primaryOptions,
    this.overflowOptions = const [],
    this.height = DevicePanelTheme.modeRowHeight,
    this.modulated = false,
    this.automated = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color accentColor;
  final FilterModeSelectorLayout layout;
  final List<FilterModePrimaryOption>? primaryOptions;
  final List<FilterModeOverflowOption> overflowOptions;
  final double height;
  final bool modulated;
  final bool automated;

  static const _defaultPrimaryOptions = <FilterModePrimaryOption>[
    FilterModePrimaryOption(index: 0, curve: FilterCurveMode.lowPass),
    FilterModePrimaryOption(index: 1, curve: FilterCurveMode.highPass),
    FilterModePrimaryOption(index: 2, curve: FilterCurveMode.bandPass),
    FilterModePrimaryOption(index: 3, curve: FilterCurveMode.notch),
  ];

  List<FilterModePrimaryOption> get _rowOptions =>
      primaryOptions ?? _defaultPrimaryOptions;

  bool get _overflowActive =>
      overflowOptions.any((option) => option.index == selectedIndex);

  bool _isPrimarySelected(int engineIndex) =>
      !_overflowActive && selectedIndex == engineIndex;

  FilterModeOverflowOption? get _activeOverflow {
    for (final option in overflowOptions) {
      if (option.index == selectedIndex) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (layout == FilterModeSelectorLayout.iconGrid) {
      return FilterModeIconGrid(
        selectedIndex: selectedIndex.clamp(0, 3),
        accentColor: accentColor,
        onSelected: onSelected,
      );
    }

    final borderColor = modulated || automated
        ? accentColor.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.08);

    return Container(
      height: height,
      decoration: DevicePanelTheme.sectionDecoration(borderColor: borderColor),
      child: Row(
        children: [
          for (var i = 0; i < _rowOptions.length; i++) ...[
            Expanded(
              child: _ModeCell(
                selected: _isPrimarySelected(_rowOptions[i].index),
                accent: accentColor,
                onTap: () => onSelected(_rowOptions[i].index),
                child: CustomPaint(
                  size: Size.square(height - 6),
                  painter: FilterCurveIconPainter(
                    mode: _rowOptions[i].curve,
                    color: _isPrimarySelected(_rowOptions[i].index)
                        ? accentColor
                        : Colors.white.withValues(alpha: 0.38),
                    strokeWidth: ((height - 6) * 0.05).clamp(1.4, 2.2),
                  ),
                ),
              ),
            ),
            if (i < _rowOptions.length - 1)
              Container(width: 1, color: Colors.white.withValues(alpha: 0.06)),
          ],
          if (overflowOptions.isNotEmpty) ...[
            Container(width: 1, color: Colors.white.withValues(alpha: 0.06)),
            _OverflowCell(
              accent: accentColor,
              active: _overflowActive,
              label: _activeOverflow?.label ?? '···',
              options: overflowOptions,
              onSelected: onSelected,
            ),
          ],
        ],
      ),
    );
  }
}
