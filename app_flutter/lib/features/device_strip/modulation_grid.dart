import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_strip_theme.dart';

/// A 3-row vertical grid of LFO tool buttons inside the modulation panel.
/// Each button selects an LFO and shows its properties in a side panel.
class ModulationGrid extends StatelessWidget {
  const ModulationGrid({
    super.key,
    required this.lfos,
    required this.selectedLfoId,
    required this.maxLfos,
    required this.connectModeLfoId,
    required this.onLfoTap,
    required this.onLfoLongPress,
    required this.onAddLfo,
    required this.onRemoveLfo,
  });

  final List<LfoSnapshot> lfos;
  final int? selectedLfoId;
  final int maxLfos;
  final int? connectModeLfoId;
  final ValueChanged<int> onLfoTap;
  final ValueChanged<int> onLfoLongPress;
  final VoidCallback onAddLfo;
  final ValueChanged<int> onRemoveLfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4, right: 8),
          child: Text(
            'MODULATORS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFFE8A54B),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...lfos.map((lfo) => _LfoToolButton(
          lfo: lfo,
          isSelected: lfo.id == selectedLfoId,
          isConnectMode: lfo.id == connectModeLfoId,
          onTap: () => onLfoTap(lfo.id),
          onLongPress: () => onLfoLongPress(lfo.id),
          onRemove: () => onRemoveLfo(lfo.id),
        )),
        if (lfos.length < maxLfos)
          _AddLfoButton(onPressed: onAddLfo),
      ],
    );
  }
}

class _LfoToolButton extends StatelessWidget {
  const _LfoToolButton({
    required this.lfo,
    required this.isSelected,
    required this.isConnectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
  });

  final LfoSnapshot lfo;
  final bool isSelected;
  final bool isConnectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;

  Color get _accent => isConnectMode
      ? const Color(0xFFE8A54B)
      : isSelected
          ? const Color(0xFFE8A54B)
          : const Color(0xFFE8A54B).withValues(alpha: 0.5);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isSelected || isConnectMode
                ? const Color(0xFF2A2A35)
                : const Color(0xFF181821),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isConnectMode
                  ? const Color(0xFFE8A54B)
                  : isSelected
                      ? const Color(0xFFE8A54B).withValues(alpha: 0.6)
                      : DeviceStripTheme.cardBorder,
              width: isConnectMode ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Icon(
                Icons.waves,
                size: 14,
                color: _accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'LFO ${lfo.id}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                isConnectMode ? Icons.link : Icons.arrow_forward_ios,
                size: 10,
                color: _accent.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 12, color: Colors.white30),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddLfoButton extends StatelessWidget {
  const _AddLfoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: SizedBox(
        height: 32,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 12, color: Colors.white54),
              SizedBox(width: 4),
              Text(
                'Add Modulator',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}