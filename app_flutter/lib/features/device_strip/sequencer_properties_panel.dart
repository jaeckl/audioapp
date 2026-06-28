import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';

class SequencerPropertiesPanel extends StatelessWidget {
  const SequencerPropertiesPanel({
    super.key,
    required this.mod,
    required this.onUpdate,
  });

  final LfoSnapshot mod;
  final Future<void> Function(String param, double value) onUpdate;

  static const accent = Color(0xFFE8A54B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: const Color(0xFF14141C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          // HEADER ONLY
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: _header(theme),
          ),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme) {
    final stepOptions = [4, 8, 12, 16, 24, 32];
    final currentSteps = stepOptions.contains(mod.sequencerSteps)
        ? mod.sequencerSteps
        : 16;
    return Row(
      children: [
        Text(
          'SEQ ${mod.id}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        // Polarity toggle
        SizedBox(
          height: 22,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF14141C),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(2, (i) {
                  final active = (mod.polarity.clamp(0, 1)) == i;
                  return Expanded(
                    child: Material(
                      color: active ? accent.withValues(alpha: 0.2) : Colors.transparent,
                      child: InkWell(
                        onTap: () => onUpdate('polarity', i.toDouble()),
                        child: Center(
                          child: Text(
                            ['\u00B1', '+'][i],
                            style: TextStyle(
                              color: active ? accent : Colors.white38,
                              fontSize: 9,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: currentSteps,
          dropdownColor: const Color(0xFF1A1A24),
          isDense: true,
          style: const TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700),
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: accent, size: 14),
          items: stepOptions
              .map((n) => DropdownMenuItem<int>(
                    value: n,
                    child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ))
              .toList(),
          onChanged: (v) { if (v != null) onUpdate('steps', v.toDouble()); },
        ),
      ],
    );
  }
}