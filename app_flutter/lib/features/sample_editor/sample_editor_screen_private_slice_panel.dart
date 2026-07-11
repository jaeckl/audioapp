part of 'sample_editor_screen.dart';

class _SlicePanel extends StatefulWidget {
  const _SlicePanel({
    required this.sensitivity,
    required this.autoMode,
    required this.minGap,
    required this.replaceExisting,
    required this.evenDivisions,
    required this.gridDivision,
    required this.firstNote,
    required this.status,
    required this.selectedMarkerPosition,
    required this.onSensitivityChanged,
    required this.onAutoModeChanged,
    required this.onMinGapChanged,
    required this.onReplaceExistingChanged,
    required this.onEvenDivisionsChanged,
    required this.onGridDivisionChanged,
    required this.onFirstNoteChanged,
    required this.onAutoSlice,
    required this.onReset,
    required this.onDeleteSelected,
    required this.onNudgeSelected,
    required this.onAuditionSelected,
    required this.onExport,
  });
  final double sensitivity;
  final _SliceAutoMode autoMode;
  final double minGap;
  final bool replaceExisting;
  final int evenDivisions;
  final SampleEditSnap gridDivision;
  final int firstNote;
  final String? status;
  final double? selectedMarkerPosition;
  final ValueChanged<double> onSensitivityChanged;
  final ValueChanged<_SliceAutoMode> onAutoModeChanged;
  final ValueChanged<double> onMinGapChanged;
  final ValueChanged<bool> onReplaceExistingChanged;
  final ValueChanged<int> onEvenDivisionsChanged;
  final ValueChanged<SampleEditSnap> onGridDivisionChanged;
  final ValueChanged<int> onFirstNoteChanged;
  final VoidCallback onAutoSlice, onReset, onDeleteSelected;
  final ValueChanged<int> onNudgeSelected;
  final VoidCallback onAuditionSelected, onExport;

  @override
  State<_SlicePanel> createState() => _SlicePanelState();
}
