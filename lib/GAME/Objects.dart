import 'dart:ui';

import 'package:ulovenoteslanding/Engine/PhysicsObject.dart';
import 'package:ulovenoteslanding/Objects/Explosive.dart';

class GasObject extends PhysicsObject {
  GasObject({required Offset position}) : super(position: position, size: 20.0, color: Color(0xFF00FF00), gravity: Offset(0, -3000), affectedByGravity: true); // Green for gas
}

class ExplosiveBomb extends PhysicsObject {
  final double explosionRadius;
  final double explosionForce;

  ExplosiveBomb({
    required Color color,
    required Offset position,
    required this.explosionRadius,
    required this.explosionForce,
    required double size,
  }) : super(position: position, color: color, size: size);

  void explode(List<PhysicsObject> objects) {
    // Loop through all objects and apply force if they are within explosion range
    for (var obj in objects) {
      // Skip if the object is static or shouldn't be affected
      //if (obj.isStatic || !obj.isCollidable) continue;

      // Wake up the object if it's not already awake
      if (!obj.isAwake) {
        obj.isAwake = true;
        obj.isStatic = false; // Make the object dynamic
      }

      final distance = (position - obj.position).distance;

      // Only apply force if the object is within explosion radius
      if (distance < explosionRadius) {
        // Calculate direction of force (away from the explosion center)
        final direction = (obj.position - position).normalize();

        // Calculate force magnitude based on the distance
        final forceMagnitude = (1 - distance / explosionRadius) * explosionForce;

        // Apply the force to move the object
        final force = direction * forceMagnitude;

        // Apply the force to the object's velocity
        obj.velocity += force;

        // Optionally, destroy the object if it is too close (explosion might destroy it)
        if (distance < 10.0) {
          objects.remove(obj); // Remove objects that are too close to the explosion
        }
      }
    }
  }
}

class NormalObject extends PhysicsObject {
  NormalObject({required Offset position}) : super(position: position, size: 15.0, color: Color(0xFF0000FF)); // Blue for normal
}
