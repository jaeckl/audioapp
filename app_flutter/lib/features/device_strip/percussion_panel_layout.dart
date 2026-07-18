import 'package:flutter/material.dart';

import 'device_strip_theme.dart';
import 'drum_keytrack_toggle.dart';

/// Shared compact layout primitives for synthesized percussion devices.
///
/// Cards are intentionally unnamed: control labels and spatial grouping carry
/// the hierarchy without spending vertical space on section headings.
class PercussionPanelLayout extends StatelessWidget {
  const PercussionPanelLayout({
    super.key,
    required this.cards,
    this.flexes = const [],
  });

  static const double designWidth = 360;
  static const double gap = 8;

  final List<Widget> cards;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            if (index > 0) const SizedBox(width: gap),
            Expanded(
              flex: index < flexes.length ? flexes[index] : 1,
              child: cards[index],
            ),
          ],
        ],
      ),
    );
  }
}

/// Keyboard tracking relation used by every pitched percussion device.
/// Mirrors the Subtractive filter flow: toggle -> relation -> destination.
class PercussionPitchControl extends StatelessWidget {
  const PercussionPitchControl({
    super.key,
    required this.active,
    required this.accent,
    required this.knob,
    required this.onChanged,
  });

  final bool active;
  final Color accent;
  final Widget knob;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 13),
          child: DrumKeyTrackToggle(
            active: active,
            accent: accent,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 22, 5, 0),
          child: Icon(
            Icons.arrow_forward_ios,
            key: const ValueKey('drum-keytrack-chevron'),
            size: 10,
            color: active ? accent : Colors.white24,
          ),
        ),
        knob,
      ],
    );
  }
}

class PercussionKnobRows extends StatelessWidget {
  const PercussionKnobRows({
    super.key,
    required this.rows,
  });

  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final row in rows)
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final child in row) Flexible(child: child)],
            ),
          ),
      ],
    );
  }
}

class PercussionControlCard extends StatelessWidget {
  const PercussionControlCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF14141C),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class PercussionMiniPreview extends StatelessWidget {
  const PercussionMiniPreview({
    super.key,
    required this.child,
  });

  static const double height = 48;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E14),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: child,
        ),
      ),
    );
  }
}

class PercussionKnobColumn extends StatelessWidget {
  const PercussionKnobColumn({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final child in children) Flexible(child: Center(child: child)),
      ],
    );
  }
}

class PercussionPanelSurface extends StatelessWidget {
  const PercussionPanelSurface({
    super.key,
    required this.title,
    required this.embeddedInCard,
    required this.child,
  });

  final String title;
  final bool embeddedInCard;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (embeddedInCard) return child;

    return Material(
      color: DeviceStripTheme.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Flat header control for genuinely different DSP algorithms.
///
/// Algorithm selection is structural device state. This widget deliberately
/// has no automation or modulation affordances.
class PercussionAlgorithmTabBar extends StatelessWidget {
  const PercussionAlgorithmTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.accent,
    required this.onSelected,
  }) : assert(labels.length > 1);

  final List<String> labels;
  final int selectedIndex;
  final Color accent;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DeviceStripTheme.headerHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: InkWell(
                key: ValueKey('percussion-algorithm-tab-$index'),
                onTap: () => onSelected(index),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: index == selectedIndex
                        ? accent.withValues(alpha: 0.16)
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: index == selectedIndex
                            ? accent
                            : Colors.transparent,
                        width: 3,
                      ),
                      left: index == 0
                          ? BorderSide.none
                          : BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: index == selectedIndex
                            ? Colors.white
                            : Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
