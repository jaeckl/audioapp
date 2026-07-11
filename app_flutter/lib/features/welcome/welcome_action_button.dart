import 'package:flutter/material.dart';

import 'welcome_theme.dart';

part 'welcome_action_button_welcome_action_emphasis.dart';

/// Pill-shaped call-to-action button used on the welcome screen, styled to
/// match the app's dark bordered-panel chrome instead of stock Material
/// buttons.
class WelcomeActionButton extends StatelessWidget {
  const WelcomeActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasis = WelcomeActionEmphasis.secondary,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final WelcomeActionEmphasis emphasis;
  final bool busy;

  bool get _isPrimary => emphasis == WelcomeActionEmphasis.primary;

  @override
  Widget build(BuildContext context) {
    final background =
        _isPrimary ? WelcomeTheme.accent : WelcomeTheme.panelBackground;
    final border = _isPrimary ? WelcomeTheme.accent : WelcomeTheme.panelBorder;
    final foreground = _isPrimary ? Colors.white : WelcomeTheme.textPrimary;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(WelcomeTheme.actionRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(WelcomeTheme.actionRadius),
        onTap: busy ? null : onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WelcomeTheme.actionRadius),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy && _isPrimary)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: foreground),
                )
              else
                Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                      color: foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
