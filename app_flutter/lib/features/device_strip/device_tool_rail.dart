import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'device_drag_data.dart';
import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';
import 'effective_parameter_binding.dart';

part 'device_tool_rail_tool_rail_button.dart';
part 'device_tool_rail_tool_rail_button_state.dart';
part 'device_tool_rail_status_dot.dart';
part 'device_tool_rail_mod_button.dart';
part 'device_tool_rail_device_drag_feedback.dart';

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
    this.reorderDragData,
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
  final DeviceDragData? reorderDragData;

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
            if (reorderDragData != null)
              Positioned.fill(
                child: LongPressDraggable<DeviceDragData>(
                  data: reorderDragData!,
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: _DeviceDragFeedback(
                    deviceName: deviceName,
                    accentColor: accentColor,
                  ),
                  childWhenDragging: const SizedBox.expand(),
                  onDragStarted: HapticFeedback.selectionClick,
                  child: const SizedBox.expand(),
                ),
              ),
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
                  EffectiveParameterValueBuilder(
                    parameterId: 'bypass',
                    fallbackValue: bypassed ? 1 : 0,
                    active: bypassAutomationActive,
                    builder: (context, value) => _ToolRailButton(
                      icon: Icons.power_settings_new,
                      tooltip: value >= .5 ? 'Enable device' : 'Bypass device',
                      active: value < .5,
                      onPressed: onBypassToggle,
                      modulationActive: bypassModulationActive,
                      automationActive: bypassAutomationActive,
                      connectModeActive: bypassConnectModeActive,
                      linkModeActive: bypassLinkModeActive,
                      onModulationAssign: onBypassModulationAssign,
                      onLinkTap: onBypassAutomationLinkTap,
                      onAutomateRequest: onAutomateBypass,
                    ),
                  ),
                  if (showLibrary)
                    _ToolRailButton(
                      icon: Icons.folder_outlined,
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
