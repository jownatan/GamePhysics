import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:SandsEngine/Engine/Noise.dart';
import 'package:SandsEngine/Engine/PhysicsObject.dart';
import 'package:SandsEngine/GAME/Objects.dart';

class TerrainGenerator {
  final double blockSize;
  final double maxHeight;
  final PerlinNoise perlin;

  TerrainGenerator({
    this.blockSize = 20,
    this.maxHeight = 500.0,
    required this.perlin,
  });

  /// Generates terrain objects, including mountains, trees, and snow
  void generateTerrain(Size size, List<PhysicsObject> objects) {
    objects.clear();

    for (double x = 0; x < size.width; x += blockSize) {
      double noiseValue = perlin.noise(x / size.width, 0);
      double terrainHeight = ((noiseValue + 1) / 2 * maxHeight);
      int blocksHigh = (terrainHeight / blockSize).floor();

      // Create terrain blocks (mountains and hills)
      for (int y = 0; y <= blocksHigh; y++) {
        bool isCollidable = y == blocksHigh;
        Color terrainColor = _getTerrainColor(terrainHeight, y, blocksHigh);

        // Add the terrain block
        objects.add(TerrainObject(
          position: Offset(x + blockSize / 2, size.height - y * blockSize - blockSize / 2),
          size: blockSize,
          color: terrainColor,
          isStatic: true,
          isCollidable: isCollidable,
        ));

        // Add trees on top of the terrain (only on the surface)
        if (y == blocksHigh && terrainHeight > 100 && (x / blockSize).toInt() % 10 == 0) {
          // Create the tree at the surface of the terrain
          /*
          TreeObject tree = TreeObject(
            position: Offset(x + blockSize / 2, size.height - terrainHeight - 6 - blockSize / 2),
            size: 20, // Scaling tree size
            trunkColor: Colors.brown, // Trunk color
            foliageColor: Colors.green, // Foliage color
            isStatic: true,
          );
          

          // Generate the tree by creating the trunk and foliage
          tree.generateTree(objects);
          */
        }
      }

      // Add snow to the peaks (if terrain is high enough)
      if (terrainHeight > 0.8 * maxHeight) {
        objects.add(SnowObject(
          position: Offset(x + blockSize / 2, size.height - blocksHigh * blockSize - blockSize / 2),
          size: blockSize,
          color: Colors.white,
          isStatic: true,
        ));
      }
    }
  }

  /// Get terrain color based on height
  Color _getTerrainColor(double terrainHeight, int y, int blocksHigh) {
    if (y == blocksHigh) {
      // The topmost block (surface) is green, unless it's a snow peak
      if (terrainHeight > 0.8 * maxHeight) {
        return Colors.white; // Snow on the highest mountains
      }
      return Colors.green; // Surface is green
    }
    // Underground terrain is brown (dirt), while lower levels are darker shades
    return (terrainHeight > 0.6 * maxHeight) ? Colors.green[700]! : Colors.brown;
  }

  /// Marks blocks within a radius as exposed and updates collision
  void exposeTerrain(Offset explosionCenter, double radius, List<PhysicsObject> objects) {
    List<PhysicsObject> toRemove = []; // Temporary list to store objects to remove
    print("Explosion center: $explosionCenter, Radius: $radius");

    for (var block in objects) {
      // Check if the object is within the explosion radius
      double distance = (block.position - explosionCenter).distance;

      if (block.isStatic && distance <= radius) {
        // Add the block to the temporary list for removal after iteration
        toRemove.add(block);
      } else if (distance <= radius) {
        block.color = Colors.brown.shade900;
        block.isCollidable = true;
        block.isStatic = true;
        block.isAwake = true;
      } else {
        block.awake();
      }
    }

    // Remove exposed objects from the main list (after iteration to avoid modification issues)
    objects.removeWhere((block) => toRemove.contains(block));
  }
}

class TreeObject extends PhysicsObject {
  final Color trunkColor;
  final Color foliageColor;

  TreeObject({
    required Offset position,
    required double size,
    required this.trunkColor,
    required this.foliageColor,
    required bool isStatic,
  }) : super(position: position, size: size, isStatic: isStatic, color: Colors.brown);

  /// Generates the trunk and foliage of the tree
  void generateTree(List<PhysicsObject> objects) {
    int trunkHeight = 5; // Height of the trunk
    double trunkSize = size; // Trunk is the same size as the block

    // Generate the trunk
    for (int i = 0; i < trunkHeight; i++) {
      objects.add(PhysicsObject(
        position: Offset(position.dx, position.dy - i * trunkSize),
        size: trunkSize,
        color: trunkColor,
        isStatic: true,
      ));
    }

    // Generate the foliage (around the top of the trunk)
    double foliageSize = size * 2; // Foliage is larger than the trunk

    // Create foliage blocks in a square pattern around the trunk
    for (double dx = -foliageSize; dx <= foliageSize; dx += foliageSize / 2) {
      for (double dy = -foliageSize; dy <= foliageSize; dy += foliageSize / 2) {
        if (dx != 0 || dy != 0) {
          // Avoid placing a block in the trunk
          objects.add(PhysicsObject(
            position: Offset(position.dx + dx, position.dy - trunkHeight * size + dy),
            size: size,
            color: foliageColor,
            isStatic: true,
          ));
        }
      }
    }
  }
}

class SnowObject extends PhysicsObject {
  final Color color;

  SnowObject({
    required Offset position,
    required double size,
    required this.color,
    required bool isStatic,
  }) : super(position: position, size: size, isStatic: isStatic, color: color);
}
