import 'package:flutter/material.dart';

/// How a new-project template is grouped in the picker.
enum ProjectTemplateCategory {
  starter('STARTER', 'Blank slates and minimal setups'),
  genre('GENRE', 'Common styles with tracks and devices ready'),
  advanced('ADVANCED', 'Groups, buses, and mastering chains');

  const ProjectTemplateCategory(this.label, this.description);

  final String label;
  final String description;
}

/// A bundled or procedural starting point for a new project.
class ProjectTemplate {
  const ProjectTemplate({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.detail,
    required this.category,
    required this.icon,
    this.assetPath,
    this.bpm,
    this.trackCount,
  });

  final String id;
  final String name;
  final String subtitle;
  final String detail;
  final ProjectTemplateCategory category;
  final IconData icon;

  /// When null the shell creates a blank project procedurally.
  final String? assetPath;
  final int? bpm;
  final int? trackCount;

  bool get isProceduralEmpty => assetPath == null;
}

const List<ProjectTemplate> kProjectTemplates = [
  ProjectTemplate(
    id: 'template-empty',
    name: 'Empty',
    subtitle: 'One track · start from scratch',
    detail: 'Untitled project at 120 BPM with a single instrument track.',
    category: ProjectTemplateCategory.starter,
    icon: Icons.note_add_outlined,
    bpm: 120,
    trackCount: 1,
  ),
  ProjectTemplate(
    id: 'template-beat-lab',
    name: 'Beat Lab',
    subtitle: 'Hip-hop · 92 BPM · kick, snare, hats, bass',
    detail:
        'Four drum lanes plus a subtractive bass synth — add your own MIDI clips.',
    category: ProjectTemplateCategory.genre,
    icon: Icons.album_outlined,
    assetPath: 'assets/project_templates/beat_lab.json',
    bpm: 92,
    trackCount: 5,
  ),
  ProjectTemplate(
    id: 'template-house-floor',
    name: 'House Floor',
    subtitle: 'House · 124 BPM · kick, clap, hats, chords',
    detail:
        'Club-ready drum trio and a chord stab synth — routing ready, no clips.',
    category: ProjectTemplateCategory.genre,
    icon: Icons.nightlife_outlined,
    assetPath: 'assets/project_templates/house_floor.json',
    bpm: 124,
    trackCount: 4,
  ),
  ProjectTemplate(
    id: 'template-techno-drive',
    name: 'Techno Drive',
    subtitle: 'Techno · 130 BPM · kick, hats, acid bass',
    detail:
        'Driving kick and hats with a resonant acid bass line ready to tweak.',
    category: ProjectTemplateCategory.genre,
    icon: Icons.bolt_outlined,
    assetPath: 'assets/project_templates/techno_drive.json',
    bpm: 130,
    trackCount: 3,
  ),
  ProjectTemplate(
    id: 'template-ambient-wash',
    name: 'Ambient Wash',
    subtitle: 'Ambient · 78 BPM · pad and reverb',
    detail:
        'Slow pad synth through a long reverb tail — ideal for atmospheres.',
    category: ProjectTemplateCategory.genre,
    icon: Icons.cloud_outlined,
    assetPath: 'assets/project_templates/ambient_wash.json',
    bpm: 78,
    trackCount: 1,
  ),
  ProjectTemplate(
    id: 'template-session-mix',
    name: 'Session Mix Bus',
    subtitle: 'Drums & music groups · bus EQ + glue',
    detail:
        'Empty lanes under drum and music buses (EQ/comp) plus master EQ/limiter — drop instruments yourself.',
    category: ProjectTemplateCategory.advanced,
    icon: Icons.layers_outlined,
    assetPath: 'assets/project_templates/session_mix_bus.json',
    bpm: 120,
    trackCount: 10,
  ),
  ProjectTemplate(
    id: 'template-ms-master',
    name: 'MS Mastering Chain',
    subtitle: 'Session groups · master M/S chain',
    detail:
        'Drums and music buses into a master mid/side split (EQ/comp/limit) — empty lanes, no instruments.',
    category: ProjectTemplateCategory.advanced,
    icon: Icons.graphic_eq_outlined,
    assetPath: 'assets/project_templates/ms_mastering.json',
    bpm: 120,
    trackCount: 8,
  ),
  ProjectTemplate(
    id: 'template-stereo-synth-bus',
    name: 'Stereo Synth Bus',
    subtitle: 'Drums + synths · L delay / R reverb',
    detail:
        'Full skeleton: drum bus plus synth bus with L/R split FX and master EQ/limiter — empty lanes only.',
    category: ProjectTemplateCategory.advanced,
    icon: Icons.surround_sound_outlined,
    assetPath: 'assets/project_templates/stereo_synth_bus.json',
    bpm: 110,
    trackCount: 9,
  ),
];

List<ProjectTemplate> templatesForCategory(ProjectTemplateCategory category) {
  return kProjectTemplates
      .where((template) => template.category == category)
      .toList(growable: false);
}
