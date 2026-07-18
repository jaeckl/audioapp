import 'package:flutter/material.dart';

import '../play/play_scale.dart';
import '../play/play_deck_layout.dart';
import 'editor_view_range.dart';
import 'piano_roll_metrics.dart';
import 'piano_roll_scale.dart';
import 'piano_roll_theme.dart';

part 'piano_roll_grid_sheet_piano_roll_grid_sheet_state.dart';
part 'piano_roll_grid_sheet_title.dart';
part 'piano_roll_grid_sheet_section_title.dart';
part 'piano_roll_grid_sheet_pill.dart';
part 'piano_roll_grid_sheet_dropdown_row.dart';

class PianoRollGridSheet extends StatefulWidget {
  const PianoRollGridSheet({
    super.key,
    required this.initialSettings,
    required this.initialScaleSettings,
    required this.showScaleControls,
    required this.onChanged,
    required this.onScaleChanged,
    this.showViewRange = false,
    this.initialViewRangeBars = EditorViewRange.defaultBars,
    this.onViewRangeChanged,
    this.drawControls = false,
    this.initialDrawPattern = PianoRollDrawPattern.single,
    this.onDrawPatternChanged,
  });

  final PianoRollGridSettings initialSettings;
  final PianoRollScaleSettings initialScaleSettings;
  final bool showScaleControls;
  final bool showViewRange;
  final int initialViewRangeBars;
  final ValueChanged<int>? onViewRangeChanged;
  final bool drawControls;
  final PianoRollDrawPattern initialDrawPattern;
  final ValueChanged<PianoRollDrawPattern>? onDrawPatternChanged;
  final ValueChanged<PianoRollGridSettings> onChanged;
  final ValueChanged<PianoRollScaleSettings> onScaleChanged;

  static Future<void> show(
    BuildContext context, {
    required PianoRollGridSettings settings,
    required ValueChanged<PianoRollGridSettings> onChanged,
    PianoRollScaleSettings scaleSettings = const PianoRollScaleSettings(),
    ValueChanged<PianoRollScaleSettings>? onScaleChanged,
    bool showScaleControls = false,
    double bottomInset = 0,
  }) =>
      showView(
        context,
        settings: settings,
        onChanged: onChanged,
        scaleSettings: scaleSettings,
        onScaleChanged: onScaleChanged,
        showScaleControls: showScaleControls,
        viewRangeBars: EditorViewRange.defaultBars,
        onViewRangeChanged: null,
      );

  /// Unified view sheet: zoom range, grid snap, and scale controls.
  static Future<void> showView(
    BuildContext context, {
    required PianoRollGridSettings settings,
    required ValueChanged<PianoRollGridSettings> onChanged,
    PianoRollScaleSettings scaleSettings = const PianoRollScaleSettings(),
    ValueChanged<PianoRollScaleSettings>? onScaleChanged,
    bool showScaleControls = false,
    required int viewRangeBars,
    ValueChanged<int>? onViewRangeChanged,
  }) =>
      _showPopup(
        context,
        alignBottom: false,
        panelHeight: showScaleControls ? 520 : 440,
        child: PianoRollGridSheet(
          initialSettings: settings,
          initialScaleSettings: scaleSettings,
          showScaleControls: showScaleControls,
          showViewRange: onViewRangeChanged != null,
          initialViewRangeBars: viewRangeBars,
          onViewRangeChanged: onViewRangeChanged,
          onChanged: onChanged,
          onScaleChanged: onScaleChanged ?? (_) {},
        ),
      );

  static Future<void> showDraw(
    BuildContext context, {
    required PianoRollGridSettings settings,
    required ValueChanged<PianoRollGridSettings> onChanged,
    required PianoRollScaleSettings scaleSettings,
    required ValueChanged<PianoRollScaleSettings> onScaleChanged,
    required bool showScaleControls,
    PianoRollDrawPattern drawPattern = PianoRollDrawPattern.single,
    ValueChanged<PianoRollDrawPattern>? onDrawPatternChanged,
    double bottomInset = 0,
  }) =>
      _showPopup(
        context,
        alignBottom: true,
        child: PianoRollGridSheet(
          initialSettings: settings,
          initialScaleSettings: scaleSettings,
          showScaleControls: showScaleControls,
          drawControls: true,
          initialDrawPattern: drawPattern,
          onDrawPatternChanged: onDrawPatternChanged,
          onChanged: onChanged,
          onScaleChanged: onScaleChanged,
        ),
      );

  static Future<void> _showPopup(
    BuildContext context, {
    required bool alignBottom,
    required Widget child,
    double panelHeight = 390,
  }) {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final size = overlay.size;
    final position = alignBottom
        ? RelativeRect.fromLTRB(
            8, size.height - panelHeight, size.width - 292, 56)
        : RelativeRect.fromLTRB(size.width - 292, 52, 8, size.height - 52);
    return showMenu<void>(
      context: context,
      position: position,
      color: const Color(0xFF1A1A22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF343442)),
      ),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: SizedBox(width: 260, child: child),
        ),
      ],
    );
  }

  @override
  State<PianoRollGridSheet> createState() => _PianoRollGridSheetState();
}
