// player_movement.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:SandsEngine/Engine/Player.dart';

class PlayerController {
  final PlayerObject player;
  bool isJumping = false;
  Timer _move = Timer.periodic(const Duration(milliseconds: 1), (_) {});

  PlayerController(this.player);

  void moveLeft() {
    print("move left");
    _move = Timer.periodic(const Duration(milliseconds: 1), (_) {
      player.velocity = Offset(-200, player.velocity.dy);
      player.updateFrameRun(player.currentFrame + 1, true);
    });
  }

  void moveRight() {
    print("move right");
    _move = Timer.periodic(const Duration(milliseconds: 1), (_) {
      player.velocity = Offset(200, player.velocity.dy);
      player.updateFrameRun(player.currentFrame + 1, false);
    });
  }

  void jump() {
    if (player.isGrounded || isJumping) return; // Prevent double jumping
    isJumping = true;
    player.velocity = Offset(player.velocity.dx, -500);
    Future.delayed(const Duration(milliseconds: 500), () {
      isJumping = false;
    });
  }

  void stopMovement() {
    player.velocity = Offset(0, player.velocity.dy); // Stop horizontal movement
    _stopTimer();
  }

  void _stopTimer() {
    _move.cancel();
  }
}
