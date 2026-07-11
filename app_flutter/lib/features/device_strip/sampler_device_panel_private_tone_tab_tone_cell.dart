part of 'sampler_device_panel.dart';

extension _ToneTabTonecell on _ToneTab {
  Widget _toneCell(
      {required Widget child, EdgeInsets padding = const EdgeInsets.all(4)}) {
    return DecoratedBox(
      decoration: _ToneTab._toneCellDecoration,
      child: Padding(padding: padding, child: child),
    );
  }
}
