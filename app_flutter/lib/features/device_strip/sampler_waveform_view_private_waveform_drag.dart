part of 'sampler_waveform_view.dart';

enum _WaveformDrag {
  trimStart,
  trimEnd,
  regionStart,
  regionEnd;

  bool get affectsTrim => this == trimStart || this == trimEnd;
  bool get affectsRegion => this == regionStart || this == regionEnd;
}
