import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ulovenoteslanding/Engine/PhysicsObject.dart';
import 'package:ulovenoteslanding/Engine/Player.dart';

class WorldPainter extends CustomPainter {
  final List<PhysicsObject> objects;
  final int shadowResolution;
  final double zoomFactor; // Zoom level
  final bool useCamera; // Whether to use the camera (zoom and center on player)

  // Toggle flags for each effect
  final bool useLighting;
  final bool useBloom;
  final bool useRefraction;
  final bool useAmbientOcclusion;
  final bool useWaterEffect;
  final bool useCelShading;
  final bool useOutlineEffect;
  final bool useHeatDistortion;

  // The sun (light source) position
  final Offset sunPosition = Offset(800, 150); // Fixed position for sun

  WorldPainter(
    this.objects,
    this.shadowResolution, {
    this.zoomFactor = 2.0,
    this.useCamera = true, // Default to true, but you can pass false to disable the camera
    this.useLighting = true,
    this.useBloom = false,
    this.useRefraction = false,
    this.useAmbientOcclusion = false,
    this.useWaterEffect = false,
    this.useCelShading = false,
    this.useOutlineEffect = false,
    this.useHeatDistortion = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Find the player object to center the camera
    PlayerObject? player = objects.whereType<PlayerObject>().firstOrNull;

    // Apply camera transformation if the player is found and useCamera is true
    if (useCamera && player != null) {
      // Center the player on the screen
      final Offset playerPosition = player.position;
      final Offset screenCenter = Offset(size.width / 2, size.height / 2);

      // Translate the canvas to center the player and apply zoom
      canvas.translate(screenCenter.dx, screenCenter.dy);
      canvas.scale(zoomFactor); // Zoom in
      canvas.translate(-playerPosition.dx, -playerPosition.dy);
    }

    // Draw the background sky (gradient effect)
    final skyPaint = Paint();
    final skyGradient = RadialGradient(
      colors: [Color(0xFF87CEEB), Color.fromARGB(255, 185, 209, 233)], // Sky colors (light blue to deep blue)
      center: Alignment.topCenter,
      radius: 1.0,
    );
    skyPaint.shader = skyGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, skyPaint);

    // Draw the glowing sun at a fixed location

    // Apply all effects
    if (useBloom) _applyBloomEffect(canvas, size);
    if (useAmbientOcclusion) _applyAmbientOcclusion(canvas, size);
    if (useWaterEffect) _applyWaterEffect(canvas, size);

    // Paint shadows for each object with dynamic light interaction
    for (int i = 0; i < shadowResolution; i++) {
      double angle = (i / shadowResolution) * 2 * pi;
      double offsetX = cos(angle);
      double offsetY = sin(angle);
      Offset rayEnd = sunPosition + Offset(offsetX * size.width, offsetY * size.height);

      Offset? intersection = _checkRayIntersection(sunPosition, rayEnd);

      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      if (intersection != null) {
        // Draw shadows with gradient effects based on distance from light
        double distance = (intersection - sunPosition).distance;
        shadowPaint.color = Colors.black.withOpacity(0.3 + (distance / size.width) * 0.7);
        canvas.drawLine(sunPosition, intersection, shadowPaint);
      } else {
        canvas.drawLine(sunPosition, rayEnd, shadowPaint);
      }
    }

    // Paint each object with lighting effect
    for (var object in objects) {
      if (object is PlayerObject) {
        if (useLighting) _renderPlayerWithLighting(canvas, object); // Render the player sprite with lighting
      } else {
        if (useLighting) _renderObjectWithLighting(canvas, object); // Render other objects with lighting
        //  if (useCelShading) _applyCelShading(canvas, object); // Apply cel-shading to objects
        //  if (useOutlineEffect) _applyOutline(canvas, object); // Apply outline effect to objects
      }
    }
  }

  // Function to apply bloom effect
  void _applyBloomEffect(Canvas canvas, Size size) {
    final bloomPaint = Paint()..color = Colors.white.withOpacity(0.5);
    canvas.saveLayer(Offset.zero & size, bloomPaint);
    canvas.restore();
  }

  // Function to apply ambient occlusion
  void _applyAmbientOcclusion(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.2);
    for (var object in objects) {
      double shadowStrength = (object.position - sunPosition).distance * 0.05;

      // Ensure opacity is within the valid range
      double shadowOpacity = (shadowStrength).clamp(0.0, 1.0);
      paint.color = paint.color.withOpacity(shadowOpacity);

      canvas.drawRect(
        Rect.fromCenter(center: object.position, width: object.size, height: object.size),
        paint,
      );
    }
  }

  // Function to apply water effect
  void _applyWaterEffect(Canvas canvas, Size size) {
    Paint waterPaint = Paint()..color = Colors.blue.withOpacity(0.3);
    double waveFrequency = 0.05;
    double waveAmplitude = 10.0;

    for (var y = 0.0; y < size.height; y += 10.0) {
      double waveOffset = sin(y * waveFrequency) * waveAmplitude;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + waveOffset),
        waterPaint,
      );
    }
  }

  // Function to render the player with lighting effect
  void _renderPlayerWithLighting(Canvas canvas, PlayerObject object) {
    double distance = (object.position - sunPosition).distance;
    double lightIntensity = 1.0 / (1 + distance * 0.1); // Inverse square law for light falloff

    Paint paint = Paint()..color = object.color.withOpacity(lightIntensity);

    object.render(canvas); // Assuming render method modifies player appearance with paint
  }

  // Function to render generic objects with lighting effect
  void _renderObjectWithLighting(Canvas canvas, PhysicsObject object) {
    final paint = Paint()
      ..color = object.color
      ..style = PaintingStyle.fill;

    double distance = (object.position - sunPosition).distance;
    double lightIntensity = 40 / (1 + distance * 0.1); // Inverse square law for light falloff
    paint.color = paint.color.withOpacity(lightIntensity);

    canvas.drawRect(
      Rect.fromCenter(center: object.position, width: object.size, height: object.size),
      paint,
    );
  }

  // Function to check if a ray intersects any object
  Offset? _checkRayIntersection(Offset start, Offset end) {
    for (var object in objects) {
      final rect = Rect.fromCenter(center: object.position, width: object.size, height: object.size);
      List<Offset?> intersections = [];

      intersections.add(_getLineIntersection(start, end, rect.topLeft, rect.topRight));
      intersections.add(_getLineIntersection(start, end, rect.topRight, rect.bottomRight));
      intersections.add(_getLineIntersection(start, end, rect.bottomRight, rect.bottomLeft));
      intersections.add(_getLineIntersection(start, end, rect.bottomLeft, rect.topLeft));

      intersections.removeWhere((intersection) => intersection == null);
      intersections.sort((a, b) => (start - a!).distanceSquared.compareTo((start - b!).distanceSquared));

      if (intersections.isNotEmpty) {
        return intersections.first;
      }
    }
    return null; // No intersection found
  }

  // Function to find the intersection of two lines
  Offset? _getLineIntersection(Offset start1, Offset end1, Offset start2, Offset end2) {
    final dx1 = end1.dx - start1.dx;
    final dy1 = end1.dy - start1.dy;
    final dx2 = end2.dx - start2.dx;
    final dy2 = end2.dy - start2.dy;

    final denominator = dx1 * dy2 - dy1 * dx2;
    if (denominator == 0) return null;

    final dx3 = start2.dx - start1.dx;
    final dy3 = start2.dy - start1.dy;

    final t1 = (dx3 * dy2 - dy3 * dx2) / denominator;
    final t2 = (dx3 * dy1 - dy3 * dx1) / denominator;

    if (t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1) {
      return Offset(start1.dx + t1 * dx1, start1.dy + t1 * dy1);
    }

    return null;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
