part of 'curve_editor_screen.dart';

class _ShapeInsertSheetState extends State<_ShapeInsertSheet> {
  String _selectedShape = 'sine';
  late double _floor;
  late double _peak;
  double _cycles = 1.0;

  @override
  void initState() {
    super.initState();
    _floor = math.min(widget.startVal, widget.endVal);
    _peak = math.max(widget.startVal, widget.endVal);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Insert shape',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip('Sin', 'sine'),
                _chip('Tri', 'tri'),
                _chip('Saw', 'saw'),
                _chip('Sqr', 'square'),
                _chip('Rmp', 'ramp'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _slider(
              'Floor', _floor, widget.polarity == 0 ? -1.0 : 0.0, _peak - 0.01,
              (v) {
            setState(() => _floor = v);
          }),
          _slider('Peak', _peak, _floor + 0.01, 1.0, (v) {
            setState(() => _peak = v);
          }),
          _slider('Cycles', _cycles, 0.25, 8.0, (v) {
            setState(() => _cycles = v);
          }, decimals: 1),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              widget.onApply(_selectedShape, _floor, _peak, _cycles);
              Navigator.of(context).pop();
            },
            child: const Text('Apply',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String name) {
    final selected = _selectedShape == name;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected
            ? widget.accent.withValues(alpha: 0.22)
            : const Color(0xFF2A2A36),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _selectedShape = name),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? widget.accent
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    color: selected ? widget.accent : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max,
      ValueChanged<double> onChanged,
      {int decimals = 2}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: widget.accent,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                thumbColor: widget.accent,
                overlayColor: widget.accent.withValues(alpha: 0.15),
                trackHeight: 3,
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              value.toStringAsFixed(decimals),
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
