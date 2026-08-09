import 'dart:convert';

import 'package:audioapp/features/welcome/example_projects.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Festival Boom example ships drum machine + arrangement', () async {
    final example = kExampleProjects.firstWhere(
      (e) => e.id == 'example-festival-boom',
    );
    expect(example.assetPath, 'assets/example_projects/festival_boom.json');

    final raw = await rootBundle.loadString(example.assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    expect(data['name'], 'Festival Boom');
    expect(data['bpm'], 135);
    expect(data['loopRegionEndBeat'], 256.0);

    final tracks = data['tracks'] as List<dynamic>;
    expect(tracks.length, greaterThanOrEqualTo(6));

    final drums = tracks.cast<Map<String, dynamic>>().firstWhere(
      (t) => t['id'] == 'track-drums',
    );
    final devices = drums['devices'] as List<dynamic>;
    final dm = devices.cast<Map<String, dynamic>>().firstWhere(
      (d) => d['type'] == 'drum_machine',
    );
    final pads = dm['pads'] as List<dynamic>;
    expect(pads.length, greaterThanOrEqualTo(7));

    final padNotes = pads
        .cast<Map<String, dynamic>>()
        .map((p) => p['note'] as int)
        .toSet();
    expect(padNotes.containsAll({36, 38, 39, 42, 46, 49, 37}), isTrue);

    // Instrument tracks must not host overlapping automation layout.
    final lead = tracks.cast<Map<String, dynamic>>().firstWhere(
      (t) => t['id'] == 'track-lead',
    );
    expect((lead['midiClips'] as List).isNotEmpty, isTrue);
    expect(
      tracks.any((t) => (t as Map)['id'] == 'track-auto-lead'),
      isTrue,
    );
    for (final auto in data['automationClips'] as List) {
      final home = (auto as Map)['homeTrackId'] as String;
      expect(home.startsWith('track-auto-'), isTrue);
    }

    expect((data['lfos'] as List).length, 2);
    expect((data['modEdges'] as List).length, 3);
    expect((data['automationClips'] as List).length, greaterThan(10));

    final midiTotal = tracks.cast<Map<String, dynamic>>().fold<int>(
      0,
      (n, t) => n + ((t['midiClips'] as List?)?.length ?? 0),
    );
    expect(midiTotal, greaterThan(20));
  });
}
