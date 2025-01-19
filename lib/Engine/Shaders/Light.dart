import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:ulovenoteslanding/Engine/PhysicsObject.dart';

class PhysicsLightShader extends CustomPainter {
  final List<PhysicsObject> objects;

  PhysicsLightShader(this.objects);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Load the shader from a source (for now we use a simple radial gradient as a placeholder)
    final ui.Gradient gradient = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      [Colors.yellow.withOpacity(0.8), Colors.transparent],
      [0.0, 1.0],
    );

    paint.shader = gradient;

    // Draw the background with the gradient (simulating the light spread)
    canvas.drawRect(Offset.zero & size, paint);

    for (var object in objects) {
      final objectPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromCenter(center: object.position, width: object.size, height: object.size),
        objectPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
