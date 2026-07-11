part of 'sample_library_screen.dart';

class SampleLibraryPickerSheet extends StatefulWidget {
  const SampleLibraryPickerSheet({
    super.key,
    required this.initialSamples,
    required this.onPreview,
    required this.onImportSamples,
    required this.onSampleSelected,
  });

  final List<SampleLibraryEntrySnapshot> initialSamples;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreview;
  final Future<List<SampleLibraryEntrySnapshot>> Function() onImportSamples;
  final ValueChanged<SampleLibraryEntrySnapshot> onSampleSelected;

  @override
  State<SampleLibraryPickerSheet> createState() =>
      _SampleLibraryPickerSheetState();
}
