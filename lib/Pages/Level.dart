import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:show_fps/show_fps.dart';
import 'package:ulovenoteslanding/Engine/Noise.dart';
import 'package:ulovenoteslanding/Engine/PhysicsObject.dart';
import 'package:ulovenoteslanding/Engine/WorldPainter.dart';
import 'package:ulovenoteslanding/Engine/Player.dart';
import 'package:ulovenoteslanding/GAME/Objects.dart';
import 'package:ulovenoteslanding/Objects/Explosive.dart';

enum SpawnType { gas, explosive, normal }

class PhysicsGame extends StatefulWidget {
  @override
  _PhysicsGameState createState() => _PhysicsGameState();
}

class _PhysicsGameState extends State<PhysicsGame> with SingleTickerProviderStateMixin {
  final List<PhysicsObject> _objects = [];
  final Random _random = Random();
  Timer? _spawnTimer;
  Offset? _spawnPosition;
  bool _isExplosive = false;
  Offset lightSource = Offset(1, 1); // Initial light source position
  SpawnType _spawnType = SpawnType.normal; // Default spawn type is normal

  final List<PhysicsObject> inventory = []; // Inventory to store physics objects
  late PlayerObject _player; // The player object

  late final Ticker _ticker;
  bool _isJumping = false; // To control jump state

  @override
  void initState() {
    super.initState();
    _player = PlayerObject(position: const Offset(100, 300), size: 50, spritePath: 'lib/GAME/Sprites/Player/DinoSprites_doux.png', spriteWidth: 24, spriteHeight: 24, isGrounded: false); // Initialize the player at a starting position

    _ticker = Ticker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initWorld();
    });
  }

  void initWorld() {
    final screenSize = MediaQuery.of(context).size;
    _generateTerrain(screenSize);
    _objects.add(_player); // Add player to objects list
    _player.loadImage();
  }

  void _onTick(Duration elapsed) {
    final deltaTime = 1 / 60; // Fixed timestep
    setState(() {
      updatePhysics(deltaTime);
      _updateLightSourcePosition();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void updatePhysics(double deltaTime) {
    for (var obj in _objects) {
      // Skip inactive or static objects (no physics for them), but always update player and explosive
      if ((!obj.isAwake || obj.isStatic) && !(obj is PlayerObject || obj is ExplosiveBomb)) {
        continue; // Skip player and explosive objects from static check
      }

      // Check if object has low speed and set to static if true, but skip for player and explosive
      if (obj.velocity.distance < 1.0 && !(obj is PlayerObject || obj is ExplosiveBomb)) {
        obj.isAwake = false;
        obj.isStatic = true;
        continue; // Skip the update for this object as it's now static
      }

      obj.applyForce(const Offset(0, 1500)); // Gravity
      obj.update(deltaTime);
      _checkBoundsCollision(obj);

      if (obj == _player) {
        _player.isGrounded = _checkGrounded(_player);
      }
    }
    _checkObjectCollisions();
  }

  bool _checkGrounded(PlayerObject player) {
    for (var terrainObj in _objects) {
      if (!terrainObj.isCollidable || !terrainObj.isStatic) continue;

      final distance = (player.position - terrainObj.position).distance;
      final minDistance = (player.size / 2 + terrainObj.size / 2) * 0.95; // Add a buffer to prevent sliding
      if (distance < minDistance) {
        return true;
      }
    }
    return false;
  }

  void _checkBoundsCollision(PhysicsObject obj) {
    if (obj.isStatic || !obj.affectedByGravity) return; // Skip non-moving objects

    for (var terrainObj in _objects) {
      if (!terrainObj.isCollidable || !terrainObj.isStatic) continue; // Skip non-collidable terrain

      // Calculate collision overlap
      final dx = (obj.position.dx - terrainObj.position.dx).abs();
      final dy = (obj.position.dy - terrainObj.position.dy).abs();
      final overlapX = obj.size / 2 + terrainObj.size / 2 - dx;
      final overlapY = obj.size / 2 + terrainObj.size / 2 - dy;

      if (overlapY > 0 && overlapX > 0) {
        if (overlapY < overlapX) {
          // Resolve vertical collision (apply a buffer for better precision)
          if (obj.position.dy > terrainObj.position.dy) {
            // Collision from below
            obj.position = Offset(obj.position.dx, terrainObj.position.dy + terrainObj.size / 2 + obj.size / 2);
            obj.velocity = Offset(obj.velocity.dx, 0); // Stop vertical velocity
          } else {
            // Collision from above
            obj.position = Offset(obj.position.dx, terrainObj.position.dy - terrainObj.size / 2 - obj.size / 2);
            obj.velocity = Offset(obj.velocity.dx, 0); // Stop vertical velocity
          }
        } else {
          // Resolve horizontal collision
          if (obj.position.dx > terrainObj.position.dx) {
            // Collision from the right
            obj.position = Offset(terrainObj.position.dx + terrainObj.size / 2 + obj.size / 2, obj.position.dy);
          } else {
            // Collision from the left
            obj.position = Offset(terrainObj.position.dx - terrainObj.size / 2 - obj.size / 2, obj.position.dy);
          }
          obj.velocity = Offset(0, obj.velocity.dy); // Stop horizontal velocity
        }
      }
    }
  }

  void _checkObjectCollisions() {
    // Broad-phase optimization: Partition objects into a grid to reduce collision checks
    final grid = <Offset, List<PhysicsObject>>{};
    const gridSize = 80.0; // Partition size

    for (var obj in _objects) {
      final key = Offset(
        (obj.position.dx / gridSize).floorToDouble(),
        (obj.position.dy / gridSize).floorToDouble(),
      );
      grid.putIfAbsent(key, () => []).add(obj);
    }

    for (var bucket in grid.values) {
      for (int i = 0; i < bucket.length; i++) {
        for (int j = i + 1; j < bucket.length; j++) {
          final objA = bucket[i];
          final objB = bucket[j];

          if (_areObjectsColliding(objA, objB)) {
            _resolveCollision(objA, objB);
          }
        }
      }
    }
  }

  bool _areObjectsColliding(PhysicsObject a, PhysicsObject b) {
    final distance = (a.position - b.position).distance;
    return distance < (a.size / 2 + b.size / 2);
  }

  void _resolveCollision(PhysicsObject a, PhysicsObject b) {
    final normal = (b.position - a.position).normalize();
    final relativeVelocity = b.velocity - a.velocity;
    final velocityAlongNormal = (relativeVelocity.dx * normal.dx) + (relativeVelocity.dy * normal.dy);

    if (velocityAlongNormal > 0) return;

    const restitution = 0.0; // Adjust for desired bounciness
    final impulseMagnitude = -(1 + restitution) * velocityAlongNormal * 0.8;

    final impulse = Offset(
      impulseMagnitude * normal.dx,
      impulseMagnitude * normal.dy,
    );

    const maxImpulse = 100.0;
    final clampedImpulse = Offset(
      impulse.dx.clamp(-maxImpulse, maxImpulse),
      impulse.dy.clamp(-maxImpulse, maxImpulse),
    );

    a.velocity -= clampedImpulse;
    b.velocity += clampedImpulse;
  }

  Timer _move = Timer.periodic(const Duration(milliseconds: 1), (_) {});

  void _stopPlayerTimer() {
    _move.cancel();
  }

  void _movePlayerLeft() {
    print("move left");
    _move = Timer.periodic(const Duration(milliseconds: 1), (_) {
      _player.velocity = Offset(-200, _player.velocity.dy);
      _player.updateFrameRun(
        _player.currentFrame + 1,
        true,
      );
    });
  }

  void _movePlayerRight() {
    print("move right");
    _move = Timer.periodic(const Duration(milliseconds: 1), (_) {
      _player.velocity = Offset(200, _player.velocity.dy);
      _player.updateFrameRun(
        _player.currentFrame + 1,
        false,
      );
    });
  }

  void _jumpPlayer() {
    if (_player.isGrounded || _isJumping) return; // Prevent double jumping
    _isJumping = true;
    _player.velocity = Offset(_player.velocity.dx, -500);
    Future.delayed(const Duration(milliseconds: 500), () {
      _isJumping = false;
    });
  }

  void _stopPlayerMovement() {
    _player.velocity = Offset(0, _player.velocity.dy); // Stop horizontal movement
  }

  void _updateLightSourcePosition() {
    final screenSize = MediaQuery.of(context).size;
    setState(() {
      lightSource = Offset(screenSize.width / 2, screenSize.height / 2); // Static light source
    });
  }

  void _toggleObjectType() {
    setState(() {
      // Toggle between spawn types
      _spawnType = _spawnType == SpawnType.normal
          ? SpawnType.explosive
          : _spawnType == SpawnType.explosive
              ? SpawnType.gas
              : SpawnType.normal;
    });
  }

  void _startSpawningObjects() {
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1), (_) {
      if (_spawnPosition != null) {
        _addPhysicsObject(_spawnPosition!);
      }
    });
  }

  void _stopSpawningObjects() {
    _spawnTimer?.cancel();
    _spawnPosition = null;
  }

  bool _isTooCloseToOthers(Offset position, double size) {
    for (var obj in _objects) {
      if ((obj.position - position).distance < (obj.size / 2 + size / 2)) {
        return true;
      }
    }
    return false;
  }

  void _addPhysicsObject(Offset position) {
    if (_isTooCloseToOthers(position, 20)) return; // Avoid spawning too close

    switch (_spawnType) {
      case SpawnType.gas:
        _addGasPhysicsObject(position);
        break;
      case SpawnType.explosive:
        _addExplosivePhysicsObject(position);
        break;
      case SpawnType.normal:
        _addNormalPhysicsObject(position);
        break;
    }
  }

  void _addNormalPhysicsObject(Offset position) {
    final normalObject = PhysicsObject(
      affectedByGravity: true,
      isCollidable: true,
      position: position,
      color: Colors.green,
      size: 20.0,
      velocity: Offset(
        _random.nextDouble() * 200 - 100,
        _random.nextDouble() * 200 - 100,
      ),
    );
    _objects.add(normalObject);
    inventory.add(normalObject); // Add to inventory
  }

  void _addExplosivePhysicsObject(Offset position) {
    final explosive = ExplosiveBomb(
      color: Colors.red,

      position: position,
      explosionRadius: 200.0, // Define explosion radius
      explosionForce: 15000.0, // Define explosion force
      size: 10,
    );
    _objects.add(explosive);
    inventory.add(explosive); // Add to inventory

    // Trigger explosion after 3 seconds
    Timer(const Duration(seconds: 3), () => explosive.explode(_objects));
  }

  void _addGasPhysicsObject(Offset position) {
    final gasObject = GasObject(position: position);
    _objects.add(gasObject);
    inventory.add(gasObject); // Add to inventory
  }

  final perlin = PerlinNoise();

  void _generateTerrain(Size size) {
    _objects.clear(); // Clear old objects

    const double blockSize = 20.0; // Each block is 20x20
    const double maxHeight = 250.0; // Maximum height of the terrain
    final terrainObjects = <PhysicsObject>[];

    // Generate terrain using Perlin noise
    for (double x = 0; x < size.width; x += blockSize) {
      // Generate Perlin noise for the height
      double noiseValue = perlin.noise(x / size.width, 0);
      double terrainHeight = ((noiseValue + 1) / 2 * maxHeight); // Normalize to [0, maxHeight]
      int blocksHigh = (terrainHeight / blockSize).floor();

      // Create vertical column of blocks
      for (int y = 0; y <= blocksHigh; y++) {
        bool isCollidable = y == blocksHigh; // Only the top block is collidable
        terrainObjects.add(PhysicsObject(
          // awake
          position: Offset(x + blockSize / 2, size.height - y * blockSize - blockSize / 2),
          size: blockSize,
          color: isCollidable ? Colors.green : Colors.brown, // Grass on top, dirt below
          isStatic: true,
          isCollidable: isCollidable, // New property for collision checks
        ));
      }
    }

    _objects.addAll(terrainObjects); // Add terrain to the world
  }

  void _addWalls(Size screenSize) {
    const double wallThickness = 50.0; // Set wall thickness to control size of boundaries

    // Create walls for all four boundaries
    final walls = <PhysicsObject>[
      // Left Wall
      PhysicsObject(
        position: Offset(-wallThickness / 2, screenSize.height / 2),
        size: wallThickness,
        isStatic: true,
        isCollidable: true,
        color: Colors.transparent, // Invisible wall
      ),

      // Right Wall
      PhysicsObject(
        position: Offset(screenSize.width + wallThickness / 2, screenSize.height / 2),
        size: wallThickness,
        isStatic: true,
        isCollidable: true,
        color: Colors.transparent, // Invisible wall
      ),

      // Top Wall
      PhysicsObject(
        position: Offset(screenSize.width / 2, -wallThickness / 2),
        size: wallThickness,
        isStatic: true,
        isCollidable: true,
        color: Colors.transparent, // Invisible wall
      ),

      // Bottom Wall
      PhysicsObject(
        position: Offset(screenSize.width / 2, screenSize.height + wallThickness / 2),
        size: wallThickness,
        isStatic: true,
        isCollidable: true,
        color: Colors.transparent, // Invisible wall
      ),
    ];

    // Add walls to the world objects list
    _objects.addAll(walls);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ShowFPS(
        alignment: Alignment.topRight,
        visible: true,
        showChart: false,
        child: Stack(
          children: [
            GestureDetector(
              onPanDown: (details) {
                _spawnPosition = details.localPosition;
                _addPhysicsObject(details.localPosition);
                _startSpawningObjects();
              },
              onPanUpdate: (details) {
                _spawnPosition = details.localPosition;
              },
              onPanEnd: (_) {
                _stopSpawningObjects();
              },
              child: CustomPaint(
                painter: WorldPainter(_objects, lightSource, 0, zoomFactor: 1.0, useCamera: false),
                child: Container(),
              ),
            ),

            Positioned(child: Center(child: Text("${_objects.length} objects"))),
            Positioned(
              top: 50,
              right: 50,
              child: ShadButton.secondary(
                onPressed: _toggleObjectType,
                child: const Text("Toggle Object Type"),
              ),
            ),
            // Movement buttons
            Positioned(
              bottom: 50,
              left: 50,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Left Button with Icon
                    MouseRegion(
                      onEnter: (_) => _movePlayerLeft(),
                      onExit: (_) => _stopPlayerTimer(),
                      child: IconButton(
                        icon: Icon(Icons.arrow_left, color: Colors.white),
                        onPressed: _movePlayerLeft,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Right Button with Icon
                    MouseRegion(
                      onEnter: (_) => _movePlayerRight(),
                      onExit: (_) => _stopPlayerTimer(),
                      child: IconButton(
                        icon: Icon(Icons.arrow_right, color: Colors.white),
                        onPressed: _movePlayerRight,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Jump Button with Icon
                    MouseRegion(
                      onEnter: (_) => _jumpPlayer(),
                      onExit: (_) => _stopPlayerTimer(),
                      child: IconButton(
                        icon: Icon(Icons.arrow_upward, color: Colors.white),
                        onPressed: _jumpPlayer,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stop Movement Button with Icon
                    MouseRegion(
                      onEnter: (_) => _stopPlayerMovement(),
                      onExit: (_) => _stopPlayerTimer(),
                      child: IconButton(
                        icon: Icon(Icons.pause, color: Colors.white),
                        onPressed: _stopPlayerMovement,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
