import 'dart:ui';

import 'package:ulovenoteslanding/Engine/PhysicsObject.dart';
import 'package:ulovenoteslanding/Objects/Explosive.dart';

class GasObject extends PhysicsObject {
  GasObject({required Offset position}) : super(position: position, size: 20.0, color: Color(0xFF00FF00), gravity: Offset(0, -3000), affectedByGravity: true); // Green for gas
}

class ExplosiveBomb extends ExplosiveObject {
  ExplosiveBomb({
    required Offset position,
    required double explosionRadius,
    required double explosionForce,
    required Color color,
    required double size,
  }) : super(
          color: color,
          size: size,
          explosionRadius: explosionRadius,
          explosionForce: explosionForce,
          position: position,
        ); // Red for explosive
}

class NormalObject extends PhysicsObject {
  NormalObject({required Offset position}) : super(position: position, size: 15.0, color: Color(0xFF0000FF)); // Blue for normal
}
