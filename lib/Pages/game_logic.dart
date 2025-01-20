import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:show_fps/show_fps.dart';
import 'package:ulovenoteslanding/Engine/Noise.dart';
import 'package:ulovenoteslanding/Engine/PhysicsObject.dart';
import 'package:ulovenoteslanding/Engine/TerrainGen.dart';
import 'package:ulovenoteslanding/Engine/WorldPainter.dart';
import 'package:ulovenoteslanding/Engine/Player.dart';
import 'package:ulovenoteslanding/GAME/Objects.dart';
import 'package:ulovenoteslanding/GAME/PlayerController.dart';
import 'package:ulovenoteslanding/Objects/Explosive.dart';

enum SpawnType { gas, explosive, normal }

class GameLogic extends StatefulWidget {
  @override
  _GameLogicState createState() => _GameLogicState();
}

class _GameLogicState extends State<GameLogic> with SingleTickerProviderStateMixin {
  final List<PhysicsObject> _objects = [];
  final Random _random = Random();
  Timer? _spawnTimer;
  Offset? _spawnPosition;

  Offset lightSource = Offset(1, 1); // Initial light source position
  SpawnType _spawnType = SpawnType.normal; // Default spawn type is normal
  late PlayerController _playerController; // Player controller instance

  final List<PhysicsObject> inventory = []; // Inventory to store physics objects
  late PlayerObject _player; // The player object

  late final Ticker _ticker;
  bool _isJumping = false; // To control jump state
  TerrainGenerator terrainGenerator = TerrainGenerator(perlin: PerlinNoise());
  late FocusNode _focusNode;
  @override
  @override
  void initState() {
    super.initState();
    _player = PlayerObject(position: const Offset(100, 300), size: 50, spritePath: 'lib/GAME/Sprites/Player/DinoSprites_doux.png', spriteWidth: 24, spriteHeight: 20, isGrounded: false);

    _ticker = Ticker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initWorld();
      FocusScope.of(context).requestFocus(_focusNode); // Ensure focus is requested here
    });

    terrainGenerator = TerrainGenerator(perlin: perlin);

    _focusNode = FocusNode();
  }

  final perlin = PerlinNoise();

  void initWorld() {
    final screenSize = MediaQuery.of(context).size;

    terrainGenerator.generateTerrain(screenSize, _objects);

    _objects.add(_player); // Add player to objects list
    _player.loadImage();
    _playerController = PlayerController(_player); // Initialize PlayerController
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
    _focusNode.dispose(); // Dispose focus node when the widget is disposed

    super.dispose();
  }

  void updatePhysics(double deltaTime) {
    for (var obj in _objects) {
      // Skip inactive or static objects (no physics for them), but always update player and explosive
      if ((!obj.isAwake || obj.isStatic) && !(obj is PlayerObject || obj is ExplosiveBomb)) {
        continue; // Skip player and explosive objects from static check
      }

      // Check if object has low speed and set to static if true, but skip for player and explosive
      if (obj.velocity.distance < 5 && !(obj is PlayerObject || obj is ExplosiveBomb)) {
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

  bool _checkObjectCollisions() {
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

    bool collisionDetected = false; // Track if a collision happens

    for (var bucket in grid.values) {
      for (int i = 0; i < bucket.length; i++) {
        for (int j = i + 1; j < bucket.length; j++) {
          final objA = bucket[i];
          final objB = bucket[j];

          if (_areObjectsColliding(objA, objB)) {
            _resolveCollision(objA, objB);
            collisionDetected = true; // Set to true if collision occurs
          }
        }
      }
    }

    return collisionDetected; // Return whether a collision was detected
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
      explosionRadius: 100.0, // Adjust for desired radius
      explosionForce: 1500.0, // Adjust for desired force
      size: 10,
    );

    explosive.isStatic = false; // Ensure it's dynamic
    _objects.add(explosive);

    // Trigger explosion after 3 seconds
    Timer(const Duration(seconds: 3), () {
      explosive.explode(_objects, terrainGenerator);
    });
  }

  void _addGasPhysicsObject(Offset position) {
    final gasObject = GasObject(
      position: position,
    );
    _objects.add(gasObject);
    inventory.add(gasObject); // Add to inventory
  }

  // Handle keyboard events
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode, // Ensure the FocusNode is set
        onKeyEvent: (event) {
          _handleKeyEvent(event); // Handle key events
        },
        child: ShowFPS(
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
                  painter: WorldPainter(_objects, 0, zoomFactor: 1.0, useCamera: false),
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
                  child: Row(
                    children: [
                      // Left Button with Icon
                      MouseRegion(
                        onEnter: (_) => _playerController.moveLeft(),
                        onExit: (_) => _playerController.stopMovement(),
                        child: IconButton(
                          icon: Icon(Icons.arrow_left, color: Colors.white),
                          onPressed: () => _playerController.moveLeft(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Right Button with Icon
                      MouseRegion(
                        onEnter: (_) => _playerController.moveRight(),
                        onExit: (_) => _playerController.stopMovement(),
                        child: IconButton(
                          icon: Icon(Icons.arrow_right, color: Colors.white),
                          onPressed: () => _playerController.moveRight(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Movement buttons2
              Positioned(
                bottom: 50,
                right: 50,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(height: 20),

                      // Jump Button with Icon
                      MouseRegion(
                        onEnter: (_) => _playerController.jump(),
                        onExit: (_) => _playerController.stopMovement(),
                        child: IconButton(
                          icon: Icon(Icons.arrow_upward, color: Colors.white),
                          onPressed: () => _playerController.jump(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stop Movement Button with Icon
                      MouseRegion(
                        onEnter: (_) => _playerController.stopMovement(),
                        child: IconButton(
                          icon: Icon(Icons.pause, color: Colors.white),
                          onPressed: () => _playerController.stopMovement(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Handle keyboard events
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey.keyLabel) {
        case 'Arrow Left':
        case 'a':
          _playerController.moveLeft();
          break;
        case 'Arrow Right':
        case 'd':
          _playerController.moveRight();
          break;
        case 'Space':
        case 'Arrow Up':
          _playerController.jump();
          break;
      }
    } else if (event is KeyUpEvent) {
      // When key is released
      switch (event.logicalKey.keyLabel) {
        case 'Arrow Left':
        case 'a':
        case 'Arrow Right':
        case 'd':
          _playerController.stopMovement(); // Stop movement on key release
          break;
      }
    }
  }
}
