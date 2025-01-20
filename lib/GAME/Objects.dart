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
      double distance = (obj.position - position).distance;
      if (distance <= explosionRadius) {
        final direction = (obj.position - position).normalize();
        final forceMagnitude = explosionForce / (distance + 1); // Inverse square falloff
        obj.applyForce(direction * forceMagnitude);
      }
    }

    // Expose terrain within the explosion radius
    terrainGenerator.exposeTerrain(position, explosionRadius, objects);

    // Remove the explosive itself from the objects list
    objects.remove(this);
  }
}

class NormalObject extends PhysicsObject {
  NormalObject({required Offset position}) : super(position: position, size: 15.0, color: Color(0xFF0000FF)); // Blue for normal
}
