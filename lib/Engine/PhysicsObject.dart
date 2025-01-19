import 'dart:ui';
import 'package:flutter/material.dart';

class PhysicsObject {
  final Color color;
  Offset position; // Current position of the object
  Offset velocity; // Velocity vector
  Offset acceleration; // Acceleration vector
  double size; // Size of the square

  double rotation; // Current rotation angle in radians
  double angularVelocity; // Angular velocity in radians/second
  double momentOfInertia; // Moment of inertia

  static const double mass = 1.0; // Mass of the object (constant)
  static const double damping = 0.99; // Damping factor for velocity and rotation
  final Offset gravity; // Gravitational acceleration (pixels/second²)

  final bool affectedByGravity; // Determines if the object is affected by gravity

  bool isAwake; // To track whether the object is active

  static const double frictionCoefficient = 0.1; // Coefficient of friction (adjust as needed)
  bool isStatic; // Add this property
  bool isCollidable; // New property for collision

  PhysicsObject({
    required this.color,
    required this.position,
    this.velocity = Offset.zero,
    this.acceleration = Offset.zero,
    this.size = 100.0,
    this.rotation = 0.0,
    this.angularVelocity = 0.0,
    this.affectedByGravity = true, // Default: objects are affected by gravity
    this.gravity = const Offset(0, 9.8),
    this.isStatic = false, // Default to non-static
    this.isCollidable = true, // Defaults to non-collidable
  })  : momentOfInertia = (1 / 6) * mass * size * size, // Simplified calculation for a square
        isAwake = true; // Set the object as awake by default

  void update(double deltaTime) {
    if (!isAwake) return; // Skip updates if the object is asleep

    // Apply gravity if the object is affected by it
    if (affectedByGravity) {
      acceleration += gravity;
    }

    // Update velocity and position only if the object is affected by any forces
    if (affectedByGravity || acceleration != Offset.zero) {
      velocity += acceleration * deltaTime;
      position += velocity * deltaTime;

      // Apply damping to velocity and angular velocity
      velocity *= damping;
      angularVelocity *= damping;

      // Apply friction: slows down the object based on its current velocity
      applyFriction(deltaTime);

      // Update rotation
      rotation += angularVelocity * deltaTime;
    }

    // Reset acceleration after update
    acceleration = Offset.zero;

    // Stop small movements caused by damping when velocity is close to zero
    if (velocity.distance < 0.01) {
      velocity = Offset.zero;
    }

    if (angularVelocity.abs() < 0.01) {
      angularVelocity = 0.0;
    }
  }

  void applyForce(Offset force) {
    if (!isAwake) return; // Don't apply force if the object is asleep

    acceleration += force / mass;
  }

  void applyFriction(double deltaTime) {
    // If the object is not moving, no friction should be applied
    if (velocity.distance == 0) return;

    // Calculate the direction of friction (opposite to the direction of velocity)
    final frictionDirection = velocity.normalize();

    // Friction force is proportional to the normal force (in this case, it's based on the mass and gravity)
    final frictionForce = frictionDirection * frictionCoefficient * mass * gravity.distance;

    // Apply the friction force to the object's velocity (reduce it over time)
    velocity -= frictionForce * deltaTime;

    // Make sure the object stops moving if friction brings it to zero or below
    if (velocity.distance < 0.01) {
      velocity = Offset.zero;
    }
  }

  bool isCollidingWith(PhysicsObject other) {
    if (!isAwake || !other.isAwake) return false; // Don't check collisions if asleep

    final dx = position.dx - other.position.dx;
    final dy = position.dy - other.position.dy;
    final distanceSquared = dx * dx + dy * dy;
    final minDistance = (size + other.size) / 2;
    return distanceSquared < minDistance * minDistance;
  }

  void render(Canvas canvas) {
    if (!isAwake) return; // Don't render if the object is asleep

    canvas.save();
    canvas.translate(position.dx, position.dy); // Move to object's position
    canvas.rotate(rotation); // Apply rotation
    final rect = Rect.fromCenter(center: Offset.zero, width: size, height: size);
    final paint = Paint()..color = color;
    canvas.drawRect(rect, paint); // Draw the rotated object
    canvas.restore();
  }

  // Method to wake up the physics object
  void awake() {
    isAwake = true;
  }

  // Method to put the physics object to sleep
  void sleep() {
    isAwake = false;
  }
}

extension OffsetExtensions on Offset {
  Offset normalize() {
    final length = distance;
    if (length == 0) return Offset.zero;
    return this / length;
  }
}
