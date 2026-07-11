part of 'device_strip_chrome_panels.dart';

class _FxToggleButton extends StatelessWidget {
  const _FxToggleButton({
    required this.label,
    required this.active,
    required this.accentColor,
    required this.onPressed,
  });

  final String label;
  final bool active;
  final Color accentColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 53,
        height: 25,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: 40,
              height: 25,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF222229),
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
                child: Text(label,
                    style: const TextStyle(
                      color: Color(0xFFF2F2F2),
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                    )),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _FxButtonAdornmentPainter(
                    accentColor: accentColor,
                    active: active,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
