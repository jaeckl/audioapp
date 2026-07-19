part of 'arrangement_view.dart';

extension ArrangementViewStateShowaddtrackmenuOperation on ArrangementViewState {
Future<void> _showAddTrackMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ArrangementTheme.menuBackground,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add track'),
              onTap: () => Navigator.pop(context, 'track'),
            ),
            if (widget.onAddGroup != null)
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: const Text('Add group'),
                subtitle:
                    const Text('Sum child tracks through one device chain'),
                onTap: () => Navigator.pop(context, 'group'),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'track') {
      widget.onAddTrack();
    } else if (action == 'group') {
      widget.onAddGroup?.call();
    }
  }
}
