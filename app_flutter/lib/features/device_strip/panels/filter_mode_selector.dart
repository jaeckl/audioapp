import 'package:flutter/material.dart';

import 'device_panel_theme.dart';
import 'filter_mode_icons.dart';
import 'horizontal_group_shell.dart';
import '../effective_parameter_binding.dart';

part 'filter_mode_selector_filter_mode_primary_option.dart';
part 'filter_mode_selector_filter_mode_overflow_option.dart';
part 'filter_mode_selector_filter_mode_selector_layout.dart';
part 'filter_mode_selector_mode_cell.dart';
part 'filter_mode_selector_overflow_cell.dart';

/// Unified filter mode picker — curve icons + optional overflow menu.
/// Wrapped in [HorizontalGroupShell] for automation / modulation connect.
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
    this.parameterId,
    this.embeddedInWell = false,
    this.modulationAmount = 0.0,
    this.connectModeActive = false,
    this.linkModeActive = false,
    this.onModulationAssign,
    this.onLinkTap,
    this.onAutomateRequest,
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
  final String? parameterId;
  final bool embeddedInWell;
  final double modulationAmount;
  final bool connectModeActive;
  final bool linkModeActive;
  final ValueChanged<double>? onModulationAssign;
  final VoidCallback? onLinkTap;
  final VoidCallback? onAutomateRequest;

  static const _defaultPrimaryOptions = <FilterModePrimaryOption>[
    FilterModePrimaryOption(index: 0, curve: FilterCurveMode.lowPass),
    FilterModePrimaryOption(index: 1, curve: FilterCurveMode.highPass),
    FilterModePrimaryOption(index: 2, curve: FilterCurveMode.bandPass),
    FilterModePrimaryOption(index: 3, curve: FilterCurveMode.notch),
  ];

  List<FilterModePrimaryOption> get _rowOptions =>
      primaryOptions ?? _defaultPrimaryOptions;

  int get _maxIndex {
    var maximum = 0;
    for (final option in _rowOptions) {
      if (option.index > maximum) maximum = option.index;
    }
    for (final option in overflowOptions) {
      if (option.index > maximum) maximum = option.index;
    }
    return maximum;
  }

  @override
  Widget build(BuildContext context) {
    final id = parameterId;
    if (id != null && automated && _maxIndex > 0) {
      return EffectiveParameterValueBuilder(
        parameterId: id,
        fallbackValue: selectedIndex / _maxIndex,
        active: true,
        builder: (context, value) =>
            _buildWithIndex(context, (value * _maxIndex).round()),
      );
    }
    return _buildWithIndex(context, selectedIndex);
  }

  Widget _buildWithIndex(BuildContext context, int liveSelectedIndex) {
    if (layout == FilterModeSelectorLayout.iconGrid) {
      return FilterModeIconGrid(
        selectedIndex: liveSelectedIndex.clamp(0, 3),
        accentColor: accentColor,
        onSelected: onSelected,
      );
    }

    final showLabels =
        _rowOptions.any((o) => o.label != null && o.label!.isNotEmpty);
    final iconSize = (height - 6).clamp(14.0, 24.0);
    final stroke = (iconSize * 0.08).clamp(1.3, 2.0);

    final row = Row(
      children: [
        for (var i = 0; i < _rowOptions.length; i++) ...[
          if (i > 0 && !embeddedInWell) const SizedBox(width: 4),
          Expanded(
            child: _ModeCell(
              selected: !_overflowActiveFor(liveSelectedIndex) &&
                  liveSelectedIndex == _rowOptions[i].index,
              accent: accentColor,
              flush: embeddedInWell,
              onTap: () => onSelected(_rowOptions[i].index),
              child: _modeContent(
                option: _rowOptions[i],
                selected: !_overflowActiveFor(liveSelectedIndex) &&
                    liveSelectedIndex == _rowOptions[i].index,
                showLabel: showLabels,
                iconSize: iconSize,
                stroke: stroke,
              ),
            ),
          ),
        ],
        if (overflowOptions.isNotEmpty) ...[
          const SizedBox(width: 4),
          _OverflowCell(
            accent: accentColor,
            active: _overflowActiveFor(liveSelectedIndex),
            label: _activeOverflowFor(liveSelectedIndex)?.label ?? '···',
            options: overflowOptions,
            onSelected: onSelected,
          ),
        ],
      ],
    );

    final maxValue = _maxIndex > 0 ? _maxIndex.toDouble() : 1.0;
    final shellChild = embeddedInWell
        ? row
        : ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: row,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 200.0;
        return HorizontalGroupShell(
          width: width,
          height: height,
          value: liveSelectedIndex.toDouble().clamp(0.0, maxValue),
          maxValue: maxValue,
          accent: accentColor,
          flat: embeddedInWell,
          modulationActive: modulated,
          modulationAmount: modulationAmount,
          automationActive: automated,
          connectModeActive: connectModeActive,
          linkModeActive: linkModeActive,
          onModulationAssign: onModulationAssign,
          onLinkTap: onLinkTap,
          onAutomateRequest: onAutomateRequest,
          child: embeddedInWell
              ? shellChild
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: shellChild,
                ),
        );
      },
    );
  }

  Widget _modeContent({
    required FilterModePrimaryOption option,
    required bool selected,
    required bool showLabel,
    required double iconSize,
    required double stroke,
  }) {
    final color = selected
        ? accentColor
        : Colors.white.withValues(alpha: showLabel ? 0.55 : 0.46);
    final icon = CustomPaint(
      size: Size.square(iconSize),
      painter: FilterCurveIconPainter(
        mode: option.curve,
        color: color,
        strokeWidth: stroke,
      ),
    );
    final label = option.label;
    if (!showLabel || label == null || label.isEmpty) return icon;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 7,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  bool _overflowActiveFor(int index) =>
      overflowOptions.any((option) => option.index == index);

  FilterModeOverflowOption? _activeOverflowFor(int index) {
    for (final option in overflowOptions) {
      if (option.index == index) return option;
    }
    return null;
  }
}
