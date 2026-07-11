part of 'sample_editor_screen.dart';

class _SampleTimeline extends StatefulWidget {
  const _SampleTimeline(
      {required this.clipName,
      required this.peaks,
      required this.clipLengthBeats,
      required this.naturalLengthBeats,
      required this.playbackContentLengthBeats,
      required this.start,
      required this.end,
      required this.fadeIn,
      required this.fadeOut,
      required this.fadeInCurve,
      required this.fadeOutCurve,
      required this.gain,
      required this.reversed,
      required this.playhead,
      required this.pixelsPerBeat,
      required this.gridStepBeats,
      required this.onZoomStart,
      required this.onZoomScale,
      required this.clipInteracting,
      required this.pinchInteracting,
      required this.onPinchInteractionChanged,
      required this.trimToolActive,
      required this.fadeToolActive,
      required this.takeToolActive,
      required this.takes,
      required this.takeRegions,
      required this.selectedTakeMarker,
      required this.samples,
      required this.onTakeAtBeat,
      required this.onTakeMarkerSelect,
      required this.onTakeMarkerMove,
      required this.onTakeMarkerMoveEnd,
      required this.sliceToolActive,
      required this.sliceMarkers,
      required this.onSliceToggle,
      required this.onSliceSelect,
      required this.selectedSlice,
      required this.selectedMarker,
      required this.onSliceMove,
      required this.onSliceMoveEnd,
      required this.onSliceAudition,
      required this.onPlayheadSeek,
      required this.onPlayheadActivate,
      required this.onClipInteractionChanged,
      required this.onTrimChanged,
      required this.onFadesChanged,
      required this.onCurvesChanged,
      required this.onEditEnd});
  final String clipName;
  final List<double> peaks;
  final double clipLengthBeats, naturalLengthBeats, playbackContentLengthBeats;
  final double start,
      end,
      fadeIn,
      fadeOut,
      fadeInCurve,
      fadeOutCurve,
      gain,
      playhead;
  final bool reversed;
  final double pixelsPerBeat;
  final double gridStepBeats;
  final VoidCallback onZoomStart;
  final ValueChanged<double> onZoomScale;
  final bool clipInteracting;
  final bool pinchInteracting;
  final ValueChanged<bool> onPinchInteractionChanged;
  final bool trimToolActive, fadeToolActive;
  final bool takeToolActive;
  final List<SampleClipTakeSnapshot> takes;
  final List<SampleClipTakeRegionSnapshot> takeRegions;
  final int? selectedTakeMarker;
  final List<SampleLibraryEntrySnapshot> samples;
  final void Function(double beat, String takeId) onTakeAtBeat;
  final ValueChanged<int> onTakeMarkerSelect;
  final void Function(int markerIndex, double beat) onTakeMarkerMove;
  final void Function(int markerIndex, double beat) onTakeMarkerMoveEnd;
  final bool sliceToolActive;
  final List<double> sliceMarkers;
  final ValueChanged<double> onSliceToggle;
  final ValueChanged<int> onSliceSelect;
  final int? selectedSlice;
  final int? selectedMarker;
  final void Function(int, double) onSliceMove;
  final VoidCallback onSliceMoveEnd;
  final ValueChanged<double> onSliceAudition;
  final ValueChanged<double> onPlayheadSeek;
  final VoidCallback onPlayheadActivate;
  final ValueChanged<bool> onClipInteractionChanged;
  final void Function(double, double) onTrimChanged,
      onFadesChanged,
      onCurvesChanged;
  final VoidCallback onEditEnd;

  @override
  State<_SampleTimeline> createState() => _SampleTimelineState();
}
