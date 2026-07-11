part of 'mixer_view.dart';

class _MixToggle extends StatelessWidget {
  const _MixToggle(
      {required this.label,
      required this.active,
      required this.color,
      required this.onTap});
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          width: 20,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: .25) : Colors.white10,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: active ? color : Colors.white54,
                  fontWeight: FontWeight.w700)),
        ),
      );
}
