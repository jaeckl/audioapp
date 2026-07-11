import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/live_meters_dto.dart';
import 'device_strip_theme.dart';

part 'analysis_device_panel_analysis_device_panel_state.dart';
part 'analysis_device_panel_analysis_painter.dart';

class AnalysisDevicePanel extends StatefulWidget {
  const AnalysisDevicePanel({super.key, required this.type, this.reading});
  static const double designWidth = 360;
  final String type;
  final DeviceMeterReading? reading;

  @override
  State<AnalysisDevicePanel> createState() => _AnalysisDevicePanelState();
}
