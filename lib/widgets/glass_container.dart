import 'dart:ui';
import 'package:flutter/material.dart'; // <<< CORREÇÃO AQUI

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.borderRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}