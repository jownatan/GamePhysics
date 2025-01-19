import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ulovenoteslanding/Engine/PhysicsObject.dart';
import 'package:ulovenoteslanding/Engine/Player.dart';

class WorldPainter extends CustomPainter {
  final List<PhysicsObject> objects;
  final Offset lightSource;
  final int shadowResolution;
  final double zoomFactor; // Zoom level
  final bool useCamera; // Whether to use the camera (zoom and center on player)

  WorldPainter(
    this.objects,
    this.lightSource,
    this.shadowResolution, {
    this.zoomFactor = 2.0,
    this.useCamera = true, // Default to true, but you can pass false to disable the camera
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

    // Draw the background
    final backgroundPaint = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Paint shadows for each object
    for (int i = 0; i < shadowResolution; i++) {
      double angle = (i / shadowResolution) * 2 * pi;
      double offsetX = cos(angle);
      double offsetY = sin(angle);
      Offset rayEnd = lightSource + Offset(offsetX * size.width, offsetY * size.height);

      Offset? intersection = _checkRayIntersection(lightSource, rayEnd);

      final shadowPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      if (intersection != null) {
        canvas.drawLine(lightSource, intersection, shadowPaint);
      } else {
        canvas.drawLine(lightSource, rayEnd, shadowPaint);
      }
    }

    // Paint each object (check if it has a sprite)
    for (var object in objects) {
      if (object is PlayerObject) {
        object.render(canvas); // Render the player sprite
      } else {
        final objectPaint = Paint()..color = object.color;
        canvas.drawRect(
          Rect.fromCenter(
            center: object.position,
            width: object.size,
            height: object.size,
          ),
          objectPaint,
        );
      }
    }
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
