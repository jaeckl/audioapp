part of 'play_deck_layout.dart';

extension CaptureQuantizeLabel on CaptureQuantize {
  String get label => switch (this) {
        CaptureQuantize.off => 'Off',
        CaptureQuantize.quarter => '1/4',
        CaptureQuantize.eighth => '1/8',
        CaptureQuantize.sixteenth => '1/16',
      };
}
