import 'package:flutter/material.dart';

/// Bottom sheet to pick a device type when inserting into the chain.
Future<String?> showDevicePickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF1A1A22),
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Insert device',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.piano, color: Color(0xFFE8A54B)),
              title: const Text('Sampler'),
              subtitle: const Text('Play audio samples from MIDI'),
              onTap: () => Navigator.pop(context, 'simple_sampler'),
            ),
            ListTile(
              leading: const Icon(Icons.waves, color: Color(0xFF6EC9E8)),
              title: const Text('Oscillator'),
              subtitle: const Text('Simple sine tone generator'),
              onTap: () => Navigator.pop(context, 'simple_oscillator'),
            ),
            ListTile(
              leading: const Icon(Icons.graphic_eq, color: Color(0xFF7B6CF6)),
              title: const Text('Subtractive Synth'),
              subtitle: const Text('2 osc · multimode · 8-voice poly'),
              onTap: () => Navigator.pop(context, 'subtractive_synth'),
            ),
            ListTile(
              leading: const Icon(Icons.music_note, color: Color(0xFF4ADE80)),
              title: const Text('Bass Synth'),
              subtitle: const Text('Mono · sub · analog grunt'),
              onTap: () => Navigator.pop(context, 'bass_synth'),
            ),
            ListTile(
              leading: const Icon(Icons.account_tree, color: Color(0xFFFF6B35)),
              title: const Text('Phase Mod Synth'),
              subtitle: const Text('4-OP · FM/PM · 8 algorithms'),
              onTap: () => Navigator.pop(context, 'phase_mod_synth'),
            ),
            ListTile(
              leading: const Icon(Icons.view_column, color: Color(0xFF3B82F6)),
              title: const Text('Wavetable Synth'),
              subtitle: const Text('Load-your-own wavetables · 8 voices'),
              onTap: () => Navigator.pop(context, 'wavetable_synth'),
            ),
            ListTile(
              leading: const Icon(Icons.album, color: Color(0xFFE85D4B)),
              title: const Text('Kick Generator'),
              subtitle: const Text('808-style · pitch-drop body'),
              onTap: () => Navigator.pop(context, 'kick_generator'),
            ),
            ListTile(
              leading: const Icon(Icons.album_outlined, color: Color(0xFFF0C14B)),
              title: const Text('Snare Generator'),
              subtitle: const Text('Body + noise · tunable'),
              onTap: () => Navigator.pop(context, 'snare_generator'),
            ),
            ListTile(
              leading: const Icon(Icons.back_hand, color: Color(0xFFE8A0C8)),
              title: const Text('Clap Generator'),
              subtitle: const Text('Multi-hit noise · room clap'),
              onTap: () => Navigator.pop(context, 'clap_generator'),
            ),
            ListTile(
              leading: const Icon(Icons.blur_on, color: Color(0xFF9AD4E8)),
              title: const Text('Cymbal Generator'),
              subtitle: const Text('Hi-hat · filtered noise wash'),
              onTap: () => Navigator.pop(context, 'cymbal_generator'),
            ),
            ListTile(
              leading: const Icon(Icons.water_drop_outlined, color: Color(0xFF7BC8E8)),
              title: const Text('Crash Generator'),
              subtitle: const Text('Long metallic wash · noise shimmer'),
              onTap: () => Navigator.pop(context, 'crash_generator'),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Effects',
                style: TextStyle(
                  color: Color(0xFF9A9AA8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.door_sliding, color: Color(0xFF6EC9A8)),
              title: const Text('Gate'),
              subtitle: const Text('Noise gate · threshold & hold'),
              onTap: () => Navigator.pop(context, 'gate'),
            ),
            ListTile(
              leading: const Icon(Icons.compress, color: Color(0xFFE8A54B)),
              title: const Text('Compressor'),
              subtitle: const Text('Downward · ratio & makeup'),
              onTap: () => Navigator.pop(context, 'compressor'),
            ),
            ListTile(
              leading: const Icon(Icons.unfold_more, color: Color(0xFF9AD4E8)),
              title: const Text('Expander'),
              subtitle: const Text('Downward · below threshold'),
              onTap: () => Navigator.pop(context, 'expander'),
            ),
            ListTile(
              leading: const Icon(Icons.horizontal_rule, color: Color(0xFFE85D4B)),
              title: const Text('Limiter'),
              subtitle: const Text('Brick-wall ceiling · track bus'),
              onTap: () => Navigator.pop(context, 'limiter'),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Frequency Effects',
                style: TextStyle(
                  color: Color(0xFF9A9AA8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.equalizer, color: Color(0xFF5BC0EB)),
              title: const Text('Filter'),
              subtitle: const Text('Multimode · LP/HP/BP/Notch'),
              onTap: () => Navigator.pop(context, 'filter'),
            ),
            ListTile(
              leading: const Icon(Icons.tune, color: Color(0xFF78C091)),
              title: const Text('4-Band EQ'),
              subtitle: const Text('Low shelf · 2 peaks · high shelf'),
              onTap: () => Navigator.pop(context, 'four_band_eq'),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Color(0xFFC77DFF)),
              title: const Text('Ring Mod'),
              subtitle: const Text('Carrier · -2 kHz to +2 kHz'),
              onTap: () => Navigator.pop(context, 'frequency_shifter'),
            ),
            ListTile(
              leading: const Icon(Icons.multiline_chart, color: Color(0xFFFFB454)),
              title: const Text('RESONATE'),
              subtitle: const Text('Six tuned modes · decay & stereo body'),
              onTap: () => Navigator.pop(context, 'resonator_bank'),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text('Routing', style: TextStyle(
                color: Color(0xFF9A9AA8), fontSize: 12,
                fontWeight: FontWeight.w600, letterSpacing: 0.6,
              )),
            ),
            ListTile(
              leading: const Icon(Icons.call_received, color: Color(0xFF66D19E)),
              title: const Text('Audio Receiver'),
              subtitle: const Text('Receive any device audio output'),
              onTap: () => Navigator.pop(context, 'audio_receiver'),
            ),
            ListTile(
              leading: const Icon(Icons.call_received, color: Color(0xFFF08BB4)),
              title: const Text('MIDI Receiver'),
              subtitle: const Text('Receive notes from any track MIDI input'),
              onTap: () => Navigator.pop(context, 'midi_receiver'),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Time‑Based Effects',
                style: TextStyle(
                  color: Color(0xFF9A9AA8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: Color(0xFF6EC9A8)),
              title: const Text('Delay'),
              subtitle: const Text('Echo · feedback & filter'),
              onTap: () => Navigator.pop(context, 'delay'),
            ),
            ListTile(
              leading: const Icon(Icons.waves, color: Color(0xFF7B6CF6)),
              title: const Text('Reverb'),
              subtitle: const Text('Room · hall · shimmer'),
              onTap: () => Navigator.pop(context, 'reverb'),
            ),
            ListTile(
              leading: const Icon(Icons.blur_circular, color: Color(0xFFE8A54B)),
              title: const Text('Chorus'),
              subtitle: const Text('Thicken · spread · modulate'),
              onTap: () => Navigator.pop(context, 'chorus'),
            ),
            ListTile(
              leading: const Icon(Icons.flip_to_back, color: Color(0xFFE8A0C8)),
              title: const Text('Phaser'),
              subtitle: const Text('Sweep · notches · swirl'),
              onTap: () => Navigator.pop(context, 'phaser'),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Mood Effects',
                style: TextStyle(
                  color: Color(0xFF9A9AA8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.blur_on, color: Color(0xFF7B6CF6)),
              title: const Text('Bitcrusher'),
              subtitle: const Text('Lo-fi · SRC decimation · bit crush'),
              onTap: () => Navigator.pop(context, 'bitcrusher'),
            ),
            ListTile(
              leading: const Icon(Icons.waves, color: Color(0xFFE85D4B)),
              title: const Text('Distortion'),
              subtitle: const Text('Tanh waveshape · drive & tone'),
              onTap: () => Navigator.pop(context, 'distortion'),
            ),
            ListTile(
              leading: const Icon(Icons.blur_circular, color: Color(0xFF4ADE80)),
              title: const Text('Tremolo'),
              subtitle: const Text('LFO amplitude mod · sine/square'),
              onTap: () => Navigator.pop(context, 'tremolo'),
            ),
            const SizedBox(height: 8),
          ],
        ),
        ),
      );
    },
  );
}
