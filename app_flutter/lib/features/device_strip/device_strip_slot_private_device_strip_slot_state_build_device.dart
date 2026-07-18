part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuilddeviceOperation on _DeviceStripSlotState {
  Widget _buildDevice(BuildContext context, double contentHeight) {
    switch (widget.device.type) {
      case 'oscilloscope':
      case 'spectrum_analyzer':
      case 'loudness_meter':
      case 'stereo_imager':
        return _buildOscilloscopeDevice(context, contentHeight);
      case 'drum_machine':
        return _buildDrumMachineDevice(context, contentHeight);
      case 'device_chain':
        return _buildDeviceChainDevice(context, contentHeight);
      case 'lr_split':
      case 'ms_split':
        return _buildSplitDevice(context, contentHeight);
      case 'granular_formant_synth':
        return _buildGranularFormantSynthDevice(context, contentHeight);
      case 'simple_sampler':
        return _buildSimpleSamplerDevice(context, contentHeight);
      case 'simple_oscillator':
        return _buildSimpleOscillatorDevice(context, contentHeight);
      case 'bass_synth':
        return _buildBassSynthDevice(context, contentHeight);
      case 'phase_mod_synth':
        return _buildPhaseModSynthDevice(context, contentHeight);
      case 'wavetable_synth':
        return _buildWavetableSynthDevice(context, contentHeight);
      case 'subtractive_synth':
        return _buildSubtractiveSynthDevice(context, contentHeight);
      case 'kick_generator':
        return _buildKickGeneratorDevice(context, contentHeight);
      case 'snare_generator':
        return _buildSnareGeneratorDevice(context, contentHeight);
      case 'clap_generator':
        return _buildClapGeneratorDevice(context, contentHeight);
      case 'hihat_generator':
      case 'ride_generator':
      case 'tom_generator':
      case 'rimshot_generator':
        return _buildDedicatedPercussionDevice(context, contentHeight);
      case 'crash_generator':
        return _buildCrashGeneratorDevice(context, contentHeight);
      case 'gate':
        return _buildGateDevice(context, contentHeight);
      case 'compressor':
        return _buildCompressorDevice(context, contentHeight);
      case 'expander':
        return _buildExpanderDevice(context, contentHeight);
      case 'limiter':
        return _buildLimiterDevice(context, contentHeight);
      case 'filter':
        return _buildFilterDevice(context, contentHeight);
      case 'four_band_eq':
        return _buildFourBandEqDevice(context, contentHeight);
      case 'frequency_shifter':
        return _buildFrequencyShifterDevice(context, contentHeight);
      case 'resonator_bank':
        return _buildResonatorBankDevice(context, contentHeight);
      case 'audio_receiver':
      case 'midi_receiver':
        return _buildAudioReceiverDevice(context, contentHeight);
      case 'midi_delay':
        return _buildMidiDelayDevice(context, contentHeight);
      case 'delay':
        return _buildDelayDevice(context, contentHeight);
      case 'reverb':
        return _buildReverbDevice(context, contentHeight);
      case 'chorus':
        return _buildChorusDevice(context, contentHeight);
      case 'phaser':
        return _buildPhaserDevice(context, contentHeight);
      case 'bitcrusher':
        return _buildBitcrusherDevice(context, contentHeight);
      case 'distortion':
        return _buildDistortionDevice(context, contentHeight);
      case 'tremolo':
        return _buildTremoloDevice(context, contentHeight);
      case 'stutter_fx':
        return _buildStutterFxDevice(context, contentHeight);
      default:
        return _buildUnknownDevice(context, contentHeight);
    }
  }
}
