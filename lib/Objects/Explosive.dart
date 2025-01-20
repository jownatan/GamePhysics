import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:SandsEngine/Engine/PhysicsObject.dart';

class ExplosiveObject extends PhysicsObject {
  double explosionRadius; // Radius of the explosion
  double explosionForce; // How powerful the explosion is

  bool isAwake; // To track whether the object is active

  ExplosiveObject({
    required Offset position,
    required this.explosionRadius,
    required this.explosionForce,
    double size = 10.0,
    double velocity = 0.0,
    double angularVelocity = 0.0,
    required Color color,
  })  : isAwake = true, // Set the object as awake by default
        super(
          position: position,
          size: size,
          velocity: Offset.zero,
          angularVelocity: angularVelocity,
          color: color,
        );

  // Apply explosive force to nearby objects
  void explode(List<PhysicsObject> objects) {
    if (!isAwake) return; // No explosion if the object is asleep

    for (var object in objects) {
      if (object != this) {
        final delta = object.position - position;
        final distance = delta.distance;

        if (distance < explosionRadius) {
          // Calculate force based on distance
          double forceMagnitude = (explosionForce * (1 - distance / explosionRadius)).clamp(0.0, explosionForce);
          if (forceMagnitude > 0) {
            final force = delta / distance * forceMagnitude;
            object.applyForce(force); // Apply force to the object
          }
        }
      }
    }

    // Remove the explosive object from the game after explosion
    objects.remove(this);
  }

  @override
  void render(Canvas canvas) {
    if (!isAwake) return; // Don't render if the object is asleep

    super.render(canvas);
    // Draw the explosive object as a red square
    final paint = Paint()
      ..color = color // Red color for the explosive object
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromCircle(center: position, radius: size / 2), paint); // Draw square
  }

  // Method to wake up the explosive object
  void awake() {
    isAwake = true;
  }

  // Method to put the explosive object to sleep
  void sleep() {
    isAwake = false;
  }
}
