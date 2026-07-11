import 'package:flutter/material.dart';

import 'play_deck_theme.dart';
import 'play_scale.dart';

part 'scale_builder_panel_scale_builder_panel_state.dart';
part 'scale_builder_panel_semitone_button.dart';
part 'scale_builder_panel_pill.dart';
part 'scale_builder_panel_section_title.dart';

/// 12-step toggle grid + a "Save" field. Returns a new custom scale on save.
class ScaleBuilderPanel extends StatefulWidget {
  const ScaleBuilderPanel({
    super.key,
    required this.onSave,
  });

  final void Function(PlayScale scale) onSave;

  @override
  State<ScaleBuilderPanel> createState() => _ScaleBuilderPanelState();
}
