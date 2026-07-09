import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';

/// Vertical tool buttons attached to the left of an expanded device card.
class DeviceToolRail extends StatelessWidget {
  const DeviceToolRail({
    super.key,
    required this.deviceName,
    required this.accentColor,
    required this.bypassed,
    required this.showLibrary,
    required this.onBypassToggle,
    this.onDelete,
    this.libraryTooltip = 'Open sample library',
    this.onLibrary,
    this.modActive = false,
    this.onModToggle,
    this.bypassModulationActive = false,
    this.bypassAutomationActive = false,
    this.bypassConnectModeActive = false,
    this.bypassLinkModeActive = false,
    this.onBypassModulationAssign,
    this.onBypassAutomationLinkTap,
    this.onAutomateBypass,
  });

  final String deviceName;
  final Color accentColor;
  final bool bypassed;
  final bool showLibrary;
  final VoidCallback onBypassToggle;
  final VoidCallback? onDelete;
  final String libraryTooltip;
  final VoidCallback? onLibrary;
  final bool modActive;
  final VoidCallback? onModToggle;
  final bool bypassModulationActive;
  final bool bypassAutomationActive;
  final bool bypassConnectModeActive;
  final bool bypassLinkModeActive;
  final ValueChanged<double>? onBypassModulationAssign;
  final VoidCallback? onBypassAutomationLinkTap;
  final VoidCallback? onAutomateBypass;

  @override
  Widget build(BuildContext context) {
    const borderSide = BorderSide(
      color: DeviceStripTheme.cardBorder,
      width: DeviceStripTheme.cardBorderWidth,
    );
    final leftRadius = const Radius.circular(DeviceStripTheme.toolRailRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DeviceStripTheme.toolRailBackground,
        borderRadius:
            BorderRadius.only(topLeft: leftRadius, bottomLeft: leftRadius),
        border: const Border(
          top: borderSide,
          left: borderSide,
          bottom: borderSide,
        ),
      ),
      child: SizedBox(
        width: DeviceStripMetrics.toolRailWidth,
        child: Stack(
          alignment: Alignment.center,
          children: [
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                deviceName.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ToolRailButton(
                    icon: Icons.power_settings_new,
                    tooltip: bypassed ? 'Enable device' : 'Bypass device',
                    active: !bypassed,
                    onPressed: onBypassToggle,
                    modulationActive: bypassModulationActive,
                    automationActive: bypassAutomationActive,
                    connectModeActive: bypassConnectModeActive,
                    linkModeActive: bypassLinkModeActive,
                    onModulationAssign: onBypassModulationAssign,
                    onLinkTap: onBypassAutomationLinkTap,
                    onAutomateRequest: onAutomateBypass,
                  ),
                  if (showLibrary)
                    _ToolRailButton(
                      icon: Icons.library_music_outlined,
                      tooltip: libraryTooltip,
                      enabled: onLibrary != null,
                      onPressed: onLibrary,
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModButton(
                    active: modActive,
                    onPressed: onModToggle,
                  ),
                  if (onDelete != null)
                    _ToolRailButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete device',
                      active: false,
                      onPressed: onDelete,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolRailButton extends StatefulWidget {
  const _ToolRailButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = true,
    this.enabled = true,
    this.modulationActive = false,
    this.automationActive = false,
    this.connectModeActive = false,
    this.linkModeActive = false,
    this.onModulationAssign,
    this.onLinkTap,
    this.onAutomateRequest,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;
  final bool enabled;
  final bool modulationActive;
  final bool automationActive;
  final bool connectModeActive;
  final bool linkModeActive;
  final ValueChanged<double>? onModulationAssign;
  final VoidCallback? onLinkTap;
  final VoidCallback? onAutomateRequest;

  @override
  State<_ToolRailButton> createState() => _ToolRailButtonState();
}

class _ToolRailButtonState extends State<_ToolRailButton>
    with SingleTickerProviderStateMixin {
  double _dragStartY = 0;
  double _assignmentAmount = 0;
  bool _assignmentMode = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _pulseAnimation = Tween<double>(begin: 0.18, end: 0.42).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_pulseActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ToolRailButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive = oldWidget.connectModeActive || oldWidget.linkModeActive;
    if (_pulseActive && !wasActive) {
      _pulseController.repeat(reverse: true);
    } else if (!_pulseActive && wasActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _pulseActive => widget.connectModeActive || widget.linkModeActive;

  void _onTap() {
    if (widget.linkModeActive && widget.onLinkTap != null) {
      HapticFeedback.mediumImpact();
      widget.onLinkTap!.call();
      return;
    }
    widget.onPressed?.call();
  }

  void _onLongPress() {
    if (widget.linkModeActive && widget.onLinkTap != null) {
      HapticFeedback.mediumImpact();
      widget.onLinkTap!.call();
      return;
    }
    if (!widget.connectModeActive && widget.onAutomateRequest != null) {
      HapticFeedback.mediumImpact();
      widget.onAutomateRequest!.call();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!widget.connectModeActive) return;
    HapticFeedback.mediumImpact();
    _dragStartY = details.localPosition.dy;
    setState(() {
      _assignmentAmount = 0;
      _assignmentMode = true;
    });
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_assignmentMode) return;
    final amount = details.localPosition.dy <= _dragStartY ? 1.0 : -1.0;
    setState(() => _assignmentAmount = amount);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_assignmentMode) return;
    widget.onModulationAssign?.call(_assignmentAmount);
    setState(() {
      _assignmentAmount = 0;
      _assignmentMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = !widget.enabled
        ? Colors.white24
        : widget.active
            ? Colors.white70
            : const Color(0xFFE86A6A);
    final highlight = widget.linkModeActive
        ? const Color(0xFFB48CFF)
        : const Color(0xFFE8A54B);
    final showModulationDot = widget.modulationActive || widget.linkModeActive;
    final modulationDotColor = widget.linkModeActive
        ? const Color(0xFFB48CFF)
        : const Color(0xFFE8A54B);

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? _onTap : null,
        onLongPress: widget.enabled &&
                (widget.linkModeActive || !widget.connectModeActive)
            ? _onLongPress
            : null,
        onLongPressStart: widget.enabled && widget.connectModeActive
            ? _onLongPressStart
            : null,
        onLongPressMoveUpdate: widget.enabled && widget.connectModeActive
            ? _onLongPressMoveUpdate
            : null,
        onLongPressEnd:
            widget.enabled && widget.connectModeActive ? _onLongPressEnd : null,
        child: SizedBox(
          width: 28,
          height: 24,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (_pulseActive)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: highlight.withValues(
                          alpha: _pulseAnimation.value,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Icon(widget.icon, size: 18, color: color),
                  if (showModulationDot)
                    Positioned(
                      left: 5,
                      bottom: 3,
                      child: _StatusDot(
                        key: const ValueKey('tool_rail_modulation_dot'),
                        color: modulationDotColor,
                      ),
                    ),
                  if (widget.automationActive)
                    Positioned(
                      right: 5,
                      top: 3,
                      child: _StatusDot(
                        key: const ValueKey('tool_rail_automation_dot'),
                        color: const Color(0xFFB48CFF),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: const SizedBox(width: 7, height: 7),
      ),
    );
  }
}

class _ModButton extends StatelessWidget {
  const _ModButton({
    required this.active,
    required this.onPressed,
  });

  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Modulation',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 24),
      onPressed: onPressed,
      icon: Text(
        'Mod',
        style: TextStyle(
          color: active ? const Color(0xFFE8A54B) : Colors.white54,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
