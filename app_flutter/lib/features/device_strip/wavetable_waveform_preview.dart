import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'wavetable_waveform_preview_wavetable_waveform_preview_state.dart';
part 'wavetable_waveform_preview_parsed_wav.dart';
part 'wavetable_waveform_preview_wavetable_shape.dart';
part 'wavetable_waveform_preview_wavetable3_d_painter.dart';

class WavetableWaveformPreview extends StatefulWidget {
  const WavetableWaveformPreview({
    super.key,
    this.accent = const Color(0xFF3B82F6),
    this.showLabel = false,
    this.label,
    this.onTap,
    this.wavetableId,
    this.wtPosition,
  });

  final Color accent;
  final bool showLabel;
  final String? label;
  final VoidCallback? onTap;
  final String? wavetableId;
  final double? wtPosition;

  @override
  State<WavetableWaveformPreview> createState() =>
      _WavetableWaveformPreviewState();
}
