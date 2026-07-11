part of 'arrangement_view.dart';

extension ArrangementViewStateEndprogrammaticscrollOperation on ArrangementViewState {
void _endProgrammaticScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _programmaticScroll = false;
      }
    });
  }
}
