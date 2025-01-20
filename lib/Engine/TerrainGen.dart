import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ulovenoteslanding/Engine/Noise.dart';
import 'package:ulovenoteslanding/Engine/PhysicsObject.dart';

class TerrainGenerator {
  final double blockSize;
  final double maxHeight;
  final PerlinNoise perlin;

  TerrainGenerator({
    this.blockSize = 20.0,
    this.maxHeight = 500.0,
    required this.perlin,
  });

  /// Generates terrain objects
  void generateTerrain(Size size, List<PhysicsObject> objects) {
    objects.clear();
    for (double x = 0; x < size.width; x += blockSize) {
      double noiseValue = perlin.noise(x / size.width, 0);
      double terrainHeight = ((noiseValue + 1) / 2 * maxHeight);
      int blocksHigh = (terrainHeight / blockSize).floor();

      for (int y = 0; y <= blocksHigh; y++) {
        bool isCollidable = y == blocksHigh;
        objects.add(PhysicsObject(
          position: Offset(x + blockSize / 2, size.height - y * blockSize - blockSize / 2),
          size: blockSize,
          color: isCollidable ? Colors.green : Colors.brown,
          isStatic: true,
          isCollidable: isCollidable,
        ));
      }
    }
  }

  /// Marks blocks within a radius as exposed and updates collision
  void exposeTerrain(Offset explosionCenter, double radius, List<PhysicsObject> objects) {
    List<PhysicsObject> toRemove = []; // Temporary list to store objects to remove

    for (var block in objects) {
      // Check if the object is within the explosion radius
      double distance = (block.position - explosionCenter).distance;

      if (block.isStatic && distance <= radius) {
        // Make the block collidable and expose it
        block.isCollidable = true;
        block.color = Colors.green; // Change the color to green to indicate exposure

        // Add the block to the temporary list for removal after iteration
        toRemove.add(block);
      }
    }

    // Remove exposed objects from the main list (after iteration to avoid modification issues)
    objects.removeWhere((block) => toRemove.contains(block));
  }
}
