part of 'dynamics_fx_screenshot_main.dart';

DynamicsDeviceSnapshot _mockDevice(String type) {
  switch (type) {
    case 'gate':
      return const GateDeviceSnapshot(
        id: 'dev-gate',
        gain: 0.8,
        pan: 0.5,
        bypassed: false,
        meterGainReductionDb: 0.0,
        meterInputLevel: 0.0,
        inputGain: 1.0,
        gateThreshold: 0.45,
        gateAttack: 0.25,
        gateRelease: 0.50,
        gateHold: 0.20,
        gateRange: 0.0,
      );
    case 'compressor':
      return const CompressorDeviceSnapshot(
        id: 'dev-compressor',
        gain: 0.8,
        pan: 0.5,
        bypassed: false,
        meterGainReductionDb: 0.0,
        meterInputLevel: 0.0,
        inputGain: 1.0,
        compThreshold: 0.55,
        compRatio: 0.50,
        compAttack: 0.20,
        compRelease: 0.55,
        compKnee: 0.25,
        compMakeup: 0.35,
      );
    case 'expander':
      return const ExpanderDeviceSnapshot(
        id: 'dev-expander',
        gain: 0.8,
        pan: 0.5,
        bypassed: false,
        meterGainReductionDb: 0.0,
        meterInputLevel: 0.0,
        inputGain: 1.0,
        expandThreshold: 0.40,
        expandRatio: 0.45,
        expandAttack: 0.25,
        expandRelease: 0.55,
        expandRange: 0.15,
      );
    case 'limiter':
      return const LimiterDeviceSnapshot(
        id: 'dev-limiter',
        gain: 0.8,
        pan: 0.5,
        bypassed: false,
        meterGainReductionDb: 0.0,
        meterInputLevel: 0.0,
        inputGain: 1.0,
        limitCeiling: 0.85,
        limitAttack: 0.10,
        limitRelease: 0.40,
        limitKnee: 0.0,
        limitDrive: 0.0,
        limitMakeup: 0.0,
      );
    default:
      throw ArgumentError('Unknown mock dynamics type: $type');
  }
}
