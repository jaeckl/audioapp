import 'package:flutter/foundation.dart';

/// Chain-wide connect mode: a long-pressed modulator can target controls in
/// virtual child strips as well as its originating device.
final ValueNotifier<int?> deviceModulationConnectMode = ValueNotifier(null);
