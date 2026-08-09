import 'dart:convert';

import 'package:audioapp/bridge/track_nest_order.dart';
import 'package:audioapp/features/welcome/project_templates.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('project templates include starter, genre, and advanced entries', () {
    expect(
      templatesForCategory(ProjectTemplateCategory.starter),
      isNotEmpty,
    );
    expect(
      templatesForCategory(ProjectTemplateCategory.genre).length,
      greaterThanOrEqualTo(4),
    );
    expect(
      templatesForCategory(ProjectTemplateCategory.advanced).length,
      greaterThanOrEqualTo(3),
    );
    expect(
      kProjectTemplates.any((template) => template.isProceduralEmpty),
      isTrue,
    );
    expect(
      kProjectTemplates.where((template) => template.assetPath != null).length,
      greaterThanOrEqualTo(7),
    );
  });

  test('bundled project templates ship without MIDI clips', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final template in kProjectTemplates) {
      final assetPath = template.assetPath;
      if (assetPath == null) continue;
      final raw = await rootBundle.loadString(assetPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final tracks = data['tracks'] as List<dynamic>? ?? const [];
      for (final track in tracks) {
        final clips =
            (track as Map<String, dynamic>)['midiClips'] as List<dynamic>? ??
                const [];
        expect(clips, isEmpty,
            reason: '${template.id} track ${track['id']} has clips');
      }
    }
  });

  test('nestTracksUnderGroups puts children under parent', () {
    final tracks = [
      {'id': 'g1', 'isGroup': true, 'parentGroupId': ''},
      {'id': 'g2', 'isGroup': true, 'parentGroupId': ''},
      {'id': 'c1', 'isGroup': false, 'parentGroupId': 'g1'},
      {'id': 'c2', 'isGroup': false, 'parentGroupId': 'g2'},
      {'id': 'c3', 'isGroup': false, 'parentGroupId': 'g1'},
    ];
    final nested = nestTracksUnderGroups(
      tracks: tracks,
      idOf: (t) => t['id']! as String,
      isGroupOf: (t) => t['isGroup']! as bool,
      parentGroupIdOf: (t) => t['parentGroupId']! as String,
    );
    expect(nested.map((t) => t['id']).toList(),
        ['g1', 'c1', 'c3', 'g2', 'c2']);
  });

  test('advanced templates are FX skeletons without instruments', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    const instrumentTypes = {
      'kick_generator',
      'snare_generator',
      'clap_generator',
      'hihat_generator',
      'crash_generator',
      'subtractive_synth',
      'bass_synth',
      'wavetable_synth',
      'phase_mod_synth',
      'sampler',
      'granular',
      'oscillator',
      'drum_machine',
    };

    Future<Map<String, dynamic>> load(String path) async {
      final raw = await rootBundle.loadString(path);
      return jsonDecode(raw) as Map<String, dynamic>;
    }

    bool trackHasDeviceType(Map<String, dynamic> track, String type) {
      final devices = track['devices'] as List<dynamic>? ?? const [];
      return devices.any(
        (device) => (device as Map<String, dynamic>)['type'] == type,
      );
    }

    void expectNoInstruments(Map<String, dynamic> project, String label) {
      void walk(List<dynamic> devices) {
        for (final raw in devices) {
          final device = raw as Map<String, dynamic>;
          expect(instrumentTypes.contains(device['type']), isFalse,
              reason: '$label has instrument ${device['type']}');
          final branches = device['branches'] as List<dynamic>? ?? const [];
          for (final branch in branches) {
            walk((branch as Map)['devices'] as List? ?? const []);
          }
        }
      }

      for (final track in project['tracks'] as List) {
        walk((track as Map)['devices'] as List? ?? const []);
      }
      walk((project['master'] as Map)['devices'] as List? ?? const []);
    }

    void expectChildrenFollowGroup(List<dynamic> tracks) {
      final ids = tracks.cast<Map<String, dynamic>>().map((t) => t['id']).toList();
      for (var i = 0; i < tracks.length; i++) {
        final track = tracks[i] as Map<String, dynamic>;
        if (track['isGroup'] != true) continue;
        final groupId = track['id'];
        final childIndexes = <int>[];
        for (var j = 0; j < tracks.length; j++) {
          if ((tracks[j] as Map)['parentGroupId'] == groupId) {
            childIndexes.add(j);
          }
        }
        for (final childIndex in childIndexes) {
          expect(childIndex > i, isTrue,
              reason: 'child ${ids[childIndex]} must follow group $groupId');
        }
        if (childIndexes.isEmpty) continue;
        expect(childIndexes.first, i + 1,
            reason: 'first child of $groupId must sit right under group');
      }
    }

    final sessionMix =
        await load('assets/project_templates/session_mix_bus.json');
    expectNoInstruments(sessionMix, 'session_mix_bus');
    final sessionTracks = sessionMix['tracks'] as List<dynamic>;
    expectChildrenFollowGroup(sessionTracks);
    expect(
      sessionTracks.cast<Map<String, dynamic>>()
          .where((t) => t['isGroup'] == true)
          .length,
      2,
    );
    expect(
      sessionTracks
          .cast<Map<String, dynamic>>()
          .where((t) => t['parentGroupId'] == 'group-drums')
          .length,
      greaterThanOrEqualTo(3),
    );
    expect(
      sessionTracks
          .cast<Map<String, dynamic>>()
          .where((t) => t['parentGroupId'] == 'group-music')
          .length,
      greaterThanOrEqualTo(3),
    );
    expect(
      trackHasDeviceType(sessionMix['master'] as Map<String, dynamic>, 'limiter'),
      isTrue,
    );

    final msMaster = await load('assets/project_templates/ms_mastering.json');
    expectNoInstruments(msMaster, 'ms_mastering');
    expectChildrenFollowGroup(msMaster['tracks'] as List);
    final msMasterDevices =
        (msMaster['master'] as Map<String, dynamic>)['devices'] as List;
    expect(msMasterDevices.any((d) => (d as Map)['type'] == 'ms_split'), isTrue);
    expect(msMasterDevices.any((d) => (d as Map)['type'] == 'limiter'), isTrue);
    expect(
      (msMaster['tracks'] as List)
          .cast<Map<String, dynamic>>()
          .where((t) => t['isGroup'] == true)
          .length,
      2,
    );

    final stereoBus =
        await load('assets/project_templates/stereo_synth_bus.json');
    expectNoInstruments(stereoBus, 'stereo_synth_bus');
    expectChildrenFollowGroup(stereoBus['tracks'] as List);
    final synthGroup = (stereoBus['tracks'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((track) => track['id'] == 'group-synths');
    expect(trackHasDeviceType(synthGroup, 'lr_split'), isTrue);
    expect(
      (stereoBus['tracks'] as List)
          .cast<Map<String, dynamic>>()
          .where((t) => t['parentGroupId'] == 'group-synths')
          .length,
      greaterThanOrEqualTo(3),
    );
    expect(
      (stereoBus['tracks'] as List)
          .cast<Map<String, dynamic>>()
          .where((t) => t['parentGroupId'] == 'group-drums')
          .length,
      greaterThanOrEqualTo(2),
    );
  });
}
