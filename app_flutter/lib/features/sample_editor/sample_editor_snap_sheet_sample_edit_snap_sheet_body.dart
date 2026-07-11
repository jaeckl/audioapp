part of 'sample_editor_snap_sheet.dart';

class _SampleEditSnapSheetBody extends StatefulWidget {
  const _SampleEditSnapSheetBody({
    required this.initialSettings,
    required this.onChanged,
  });

  final SampleEditSnapSettings initialSettings;
  final ValueChanged<SampleEditSnapSettings> onChanged;

  @override
  State<_SampleEditSnapSheetBody> createState() =>
      _SampleEditSnapSheetBodyState();
}
