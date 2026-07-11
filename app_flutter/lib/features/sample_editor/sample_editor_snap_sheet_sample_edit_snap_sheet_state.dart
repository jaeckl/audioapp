part of 'sample_editor_snap_sheet.dart';

class _SampleEditSnapSheetState extends State<SampleEditSnapSheet> {
  @override
  Widget build(BuildContext context) => _SampleEditSnapSheetBody(
        initialSettings: widget.initialSettings,
        onChanged: (_) {},
      );
}
