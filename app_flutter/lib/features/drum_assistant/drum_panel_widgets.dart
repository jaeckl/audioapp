import 'package:flutter/material.dart';

import '../piano_roll/piano_roll_theme.dart';

/// Multi-row chrome strip — matches Harmonic panel padding / dock bg.
class DrumPanelShell extends StatelessWidget {
  const DrumPanelShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PianoRollTheme.dockBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: child,
      ),
    );
  }
}

/// Labeled group: muted caption + content row (visible hierarchy).
class DrumControlGroup extends StatelessWidget {
  const DrumControlGroup({
    super.key,
    required this.title,
    required this.child,
    this.expanded = false,
  });

  final String title;
  final Widget child;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: PianoRollTheme.labelMuted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
    if (!expanded) return body;
    return Expanded(child: body);
  }
}

/// Muted lane name — same language as context strip chips.
class DrumLaneTag extends StatelessWidget {
  const DrumLaneTag({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: PianoRollTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF3B3B49)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: PianoRollTheme.label,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Harmonic-style pill (toggle or action).
class DrumPill extends StatelessWidget {
  const DrumPill({
    super.key,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? PianoRollTheme.accent : const Color(0xFF25252C),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : PianoRollTheme.label,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon-only pill (Material icons).
class DrumIconPill extends StatelessWidget {
  const DrumIconPill({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: const Color(0xFF25252C),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 18, color: PianoRollTheme.label),
        ),
      ),
    );
    if (tooltip == null) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}

/// Compact − value + control.
class DrumValueStepper extends StatelessWidget {
  const DrumValueStepper({
    super.key,
    required this.label,
    required this.display,
    required this.onDecrement,
    required this.onIncrement,
    this.canDecrement = true,
    this.canIncrement = true,
  });

  final String label;
  final String display;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool canDecrement;
  final bool canIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF25252C),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepIcon(Icons.remove, canDecrement ? onDecrement : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(
                      color: PianoRollTheme.labelMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: display,
                    style: const TextStyle(
                      color: PianoRollTheme.label,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _stepIcon(Icons.add, canIncrement ? onIncrement : null),
        ],
      ),
    );
  }

  Widget _stepIcon(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 28,
        height: 30,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null
              ? PianoRollTheme.labelMuted
              : PianoRollTheme.dockIcon,
        ),
      ),
    );
  }
}

/// Wrap pills/steppers with consistent gaps (no forced scroll).
class DrumWrapRow extends StatelessWidget {
  const DrumWrapRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
