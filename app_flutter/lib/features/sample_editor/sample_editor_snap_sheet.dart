import 'package:flutter/material.dart';

import '../automation/automation_editor_theme.dart';
import 'sample_editor_snap.dart';

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
      position: RelativeRect.fromLTRB(size.width - 248, 52, 8, size.height - 52),
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

class _SampleEditSnapSheetState extends State<SampleEditSnapSheet> {
  @override
  Widget build(BuildContext context) => _SampleEditSnapSheetBody(
        initialSettings: widget.initialSettings,
        onChanged: (_) {},
      );
}

class _SampleEditSnapSheetBody extends StatefulWidget {
  const _SampleEditSnapSheetBody({
    required this.initialSettings,
    required this.onChanged,
  });

  final SampleEditSnapSettings initialSettings;
  final ValueChanged<SampleEditSnapSettings> onChanged;

  @override
  State<_SampleEditSnapSheetBody> createState() =>
      _SampleEditSnapSheetBodyState();
}

class _SampleEditSnapSheetBodyState extends State<_SampleEditSnapSheetBody> {
  late SampleEditSnapSettings _settings = widget.initialSettings;

  void _set(SampleEditSnapSettings value) {
    setState(() => _settings = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Edit snap',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Snaps trim handles and slice markers to source divisions.',
            style: TextStyle(
                color: AutomationEditorTheme.labelMuted.withValues(alpha: .9),
                fontSize: 11,
                height: 1.3),
          ),
          const SizedBox(height: 12),
          const Text('SNAP',
              style: TextStyle(
                  color: AutomationEditorTheme.labelMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .4)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _SnapPill(
                label: 'Off',
                active: _settings.snap == SampleEditSnap.off,
                onTap: () => _set(_settings.copyWith(snap: SampleEditSnap.off)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _SnapPill(
                label: 'On',
                active: _settings.snap != SampleEditSnap.off,
                onTap: () => _set(
                    _settings.copyWith(snap: SampleEditSnap.sixteenth)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          const Text('DIVISION',
              style: TextStyle(
                  color: AutomationEditorTheme.labelMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .4)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: SampleEditSnap.values
                .where((value) => value != SampleEditSnap.off)
                .map(
                  (value) => _SnapPill(
                    label: value.shortLabel,
                    active: _settings.snap == value,
                    compact: true,
                    onTap: () => _set(_settings.copyWith(snap: value)),
                  ),
                )
                .toList(),
          ),
        ],
      );
}

class _SnapPill extends StatelessWidget {
  const _SnapPill({
    required this.label,
    required this.active,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
        color: active
            ? AutomationEditorTheme.accent.withValues(alpha: .18)
            : Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 32,
            width: compact ? 44 : null,
            alignment: Alignment.center,
            padding: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? AutomationEditorTheme.accent
                        : Colors.white70)),
          ),
        ),
      );
}
