import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:SandsEngine/Pages/game_logic.dart';

class PhysicsGame extends StatefulWidget {
  @override
  _PhysicsGameState createState() => _PhysicsGameState();
}

class _PhysicsGameState extends State<PhysicsGame> with SingleTickerProviderStateMixin {
  // High-level state and UI initialization here
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameLogic(), // Use a separate widget for the game logic
    );
  }
}
