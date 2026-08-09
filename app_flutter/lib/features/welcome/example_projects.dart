/// Catalog of bundled example projects shown alongside recent projects on
/// the welcome screen. These ship as read-only Flutter assets, so unlike a
/// user's recent projects they can never be removed from the list.
class ExampleProject {
  const ExampleProject({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.assetPath,
  });

  final String id;
  final String name;
  final String subtitle;

  /// Path to the bundled `project.json` asset (see `pubspec.yaml`).
  final String assetPath;
}

const List<ExampleProject> kExampleProjects = [
  ExampleProject(
    id: 'example-festival-boom',
    name: 'Festival Boom',
    subtitle: 'F minor · 135 BPM · trap/EDM drum machine + supersaw',
    assetPath: 'assets/example_projects/festival_boom.json',
  ),
  ExampleProject(
    id: 'example-midi-take-comp-lab',
    name: 'MIDI Take Comp Lab',
    subtitle: '3 takes · open Comp + flattened pad',
    assetPath: 'assets/example_projects/midi_take_comp_lab.json',
  ),
  ExampleProject(
    id: 'example-neon-break-pressure',
    name: 'Neon Break Pressure',
    subtitle: 'F minor DnB · full 144-bar arrangement',
    assetPath: 'assets/example_projects/simple_riff.json',
  ),
  ExampleProject(
    id: 'example-afterburner-neuro-run',
    name: 'Afterburner Neuro Run',
    subtitle: 'D minor neuro-EDM · second-drop switch',
    assetPath: 'assets/example_projects/warm_pad_progression.json',
  ),
  ExampleProject(
    id: 'example-supersaw-flutter-rush',
    name: 'Supersaw Flutter Rush',
    subtitle: 'G minor EDM · looped gain flutter automation',
    assetPath: 'assets/example_projects/supersaw_flutter_rush.json',
  ),
];
