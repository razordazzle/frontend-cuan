import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final TextStyle? textStyle;
  final double height;
  final double radius;
  final bool shadow;
  final VoidCallback? onPressed;
  final Border? border;

  const GradientButton({
    super.key,
    required this.label,
    required this.gradient,
    this.textStyle,
    this.height = 48,
    this.radius = 24,
    this.shadow = false,
    this.onPressed,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    final child = Container(
      height: height,
      decoration: BoxDecoration(
        gradient: enabled ? gradient : null,
        color: enabled ? null : Theme.of(context).disabledColor.withOpacity(.12),
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: shadow
            ? [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 8))]
            : null,
      ),
      child: Center(child: Text(label, style: textStyle)),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onPressed,
        child: child,
      ),
    );
  }
}
