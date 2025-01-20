import 'dart:ui';

import 'package:SandsEngine/Engine/PhysicsObject.dart';
import 'package:SandsEngine/Engine/TerrainGen.dart';
import 'package:SandsEngine/Objects/Explosive.dart';

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
    List<PhysicsObject> toRemove = []; // Track objects to remove
    final List<PhysicsObject> affectedObjects = []; // Track affected objects

    // Apply force to nearby objects
    for (var obj in objects) {
      if (obj == this) continue; // Skip the explosive object itself

      final distance = (position - obj.position).distance;

      // Wake up objects and apply force if within explosion radius
      if (distance <= explosionRadius) {
        if (obj.isAwake) {
          obj.isAwake = true;
          obj.isStatic = false; // Make the object dynamic
        }

        print("bipbip boom");

        final direction = (obj.position - position).normalize();
        final forceMagnitude = (1 - distance / explosionRadius) * explosionForce;
        final force = direction * forceMagnitude;

        // Apply force to the object
        obj.velocity += force;
        obj.applyForce(force);

        // Mark objects very close to the explosion for removal
        if (distance < explosionRadius / 2) {
          toRemove.add(obj);
          print("Marked object for removal");
        }

        // Keep track of affected objects for terrain exposure
        affectedObjects.add(obj);
      }
    }

    // Expose terrain within the explosion radius
    terrainGenerator.exposeTerrain(position, explosionRadius, affectedObjects);

    // Remove marked objects
    objects.removeWhere((obj) => toRemove.contains(obj));
    print("Removed ${toRemove.length} objects");

    // Remove the explosive itself from the objects list
    objects.remove(this);
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
