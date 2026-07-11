part of 'sample_library_screen.dart';

class _SampleLibraryPickerSheetState extends State<SampleLibraryPickerSheet> {
  late List<SampleLibraryEntrySnapshot> _samples;

  @override
  void initState() {
    super.initState();
    _samples = widget.initialSamples;
  }

  Future<void> _import() async {
    final updated = await widget.onImportSamples();
    if (!mounted) return;
    setState(() => _samples = updated);
  }

  @override
  Widget build(BuildContext context) {
    return SampleLibraryScreen(
      embedded: true,
      embeddedTitle: 'Insert sample',
      samples: _samples,
      onPreview: widget.onPreview,
      onInsert: widget.onSampleSelected,
      onImport: _import,
    );
  }
}
