import 'dart:ui';

import 'package:ulovenoteslanding/Engine/PhysicsObject.dart';
import 'package:ulovenoteslanding/Engine/TerrainGen.dart';
import 'package:ulovenoteslanding/Objects/Explosive.dart';

class GasObject extends PhysicsObject {
  GasObject({required Offset position}) : super(position: position, size: 20.0, color: Color(0xFF00FF00), gravity: Offset(0, -3000), affectedByGravity: true); // Green for gas
}

class ExplosiveBomb extends PhysicsObject {
  final double explosionRadius;
  final double explosionForce;

  ExplosiveBomb({
    required Offset position,
    required this.explosionRadius,
    required this.explosionForce,
    required Color color,
    required double size,
  }) : super(
          position: position,
          color: color,
          size: size,
          isCollidable: true,
        );

  void explode(List<PhysicsObject> objects, TerrainGenerator terrainGenerator) {
    // Apply force to nearby objects
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
        double distance = (obj.position - position).distance;
        if (distance <= explosionRadius) {
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
          obj.applyForce(direction * forceMagnitude);
        }
      }
      // Expose terrain within the explosion radius
      terrainGenerator.exposeTerrain(position, explosionRadius, objects);
      // Remove the explosive itself from the objects list
      objects.remove(this);
    }
  }
}

class TerrainObject extends PhysicsObject {
  var isCollidable;

  var isStatic;

  TerrainObject({
    required Offset position,
    required Color color,
    required double size,
    required this.isCollidable,
    required this.isStatic,
  }) : super(
          position: position,
          color: color,
          size: size,
          isStatic: true, // Mark terrain as static
          isCollidable: true,
        );
}

class NormalObject extends PhysicsObject {
  NormalObject({required Offset position}) : super(position: position, size: 15.0, color: Color(0xFF0000FF)); // Blue for normal
}
