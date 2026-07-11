part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateOnitemselectedOperation on LibraryFlyInPanelState {
void _onItemSelected(String? itemId) {
    setState(() {
      _selectedItemId = itemId;
    });
  }
}
