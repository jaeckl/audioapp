part of 'play_scale.dart';

extension VelocityCurveLabel on VelocityCurve {
  String get label => switch (this) {
        VelocityCurve.linear => 'Linear',
        VelocityCurve.soft => 'Soft',
        VelocityCurve.hard => 'Hard',
        VelocityCurve.fixed => 'Fixed',
      };
}
