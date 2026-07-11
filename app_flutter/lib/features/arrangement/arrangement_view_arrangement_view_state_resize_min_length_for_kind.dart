part of 'arrangement_view.dart';

extension ArrangementViewStateResizeminlengthforkindOperation on ArrangementViewState {
double _resizeMinLengthForKind(ClipContentKind kind) {
    return kind == ClipContentKind.automation
        ? _kAutomationMinLengthBeats
        : kMinClipLengthBeats;
  }
}
