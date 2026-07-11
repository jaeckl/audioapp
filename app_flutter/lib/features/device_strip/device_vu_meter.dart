import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

part 'device_vu_meter_device_vu_meter_state.dart';
part 'device_vu_meter_device_vu_meter_painter.dart';

/// Vertical level meter between devices in the chain strip.
class DeviceVuMeter extends StatefulWidget {
  const DeviceVuMeter({
    super.key,
    required this.active,
    this.level = 0,
    this.gain = 1,
  });

  final bool active;
  final double level;
  final double gain;

  @override
  State<DeviceVuMeter> createState() => _DeviceVuMeterState();
}
