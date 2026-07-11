import 'package:flutter/material.dart';

import '../automation/automation_editor_theme.dart';
import 'sample_editor_snap.dart';

part 'sample_editor_snap_sheet_sample_edit_snap_sheet_state.dart';
part 'sample_editor_snap_sheet_sample_edit_snap_sheet_body.dart';
part 'sample_editor_snap_sheet_sample_edit_snap_sheet_body_state.dart';
part 'sample_editor_snap_sheet_snap_pill.dart';

class SampleEditSnapSheet extends StatefulWidget {
  const SampleEditSnapSheet({super.key, required this.initialSettings});

  final SampleEditSnapSettings initialSettings;

  static Future<void> show(
    BuildContext context, {
    required SampleEditSnapSettings settings,
    required ValueChanged<SampleEditSnapSettings> onChanged,
  }) {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final size = overlay.size;
    return showMenu<void>(
      context: context,
      position:
          RelativeRect.fromLTRB(size.width - 248, 52, 8, size.height - 52),
      color: AutomationEditorTheme.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF343442)),
      ),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: SizedBox(
            width: 216,
            child: _SampleEditSnapSheetBody(
              initialSettings: settings,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  State<SampleEditSnapSheet> createState() => _SampleEditSnapSheetState();
}
