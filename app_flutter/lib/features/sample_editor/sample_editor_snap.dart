part 'sample_editor_snap_sample_edit_snap_settings.dart';

enum SampleEditSnap {
  off,
  half,
  quarter,
  eighth,
  sixteenth,
  thirtySecond,
}

extension SampleEditSnapLabel on SampleEditSnap {
  String get shortLabel => switch (this) {
        SampleEditSnap.off => 'Off',
        SampleEditSnap.half => '1/2',
        SampleEditSnap.quarter => '1/4',
        SampleEditSnap.eighth => '1/8',
        SampleEditSnap.sixteenth => '1/16',
        SampleEditSnap.thirtySecond => '1/32',
      };

  double get sourceStep => switch (this) {
        SampleEditSnap.off => 0,
        SampleEditSnap.half => 0.5,
        SampleEditSnap.quarter => 0.25,
        SampleEditSnap.eighth => 0.125,
        SampleEditSnap.sixteenth => 0.0625,
        SampleEditSnap.thirtySecond => 0.03125,
      };
}
