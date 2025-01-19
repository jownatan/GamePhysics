import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ulovenoteslanding/Engine/PhysicsObject.dart';

class PlayerObject extends PhysicsObject {
  final String spritePath; // Path to the sprite sheet
  final int spriteWidth; // Width of each sprite in the sprite sheet
  final int spriteHeight; // Height of each sprite
  int currentFrame = 0; // The current frame of the animation
  bool isLeft = false;

  bool isGrounded; // Direction flag (left or right)

  PlayerObject({
    required Offset position,
    required double size,
    required this.spritePath,
    required this.spriteWidth,
    required this.spriteHeight,
    required this.isGrounded,
  }) : super(position: position, size: size, color: Colors.transparent);

  @override
  void render(Canvas canvas) {
    // Load the image
    final image = AssetImage(spritePath);
    final imageStream = image.resolve(ImageConfiguration());

    imageStream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      final img = info.image;

      // Calculate the horizontal position of the current frame in the sprite sheet
      int frameX = currentFrame * spriteWidth;

      // Define the source rectangle for the current frame
      final sourceRect = Rect.fromLTWH(frameX.toDouble(), 0, spriteWidth.toDouble(), spriteHeight.toDouble());

      // Define the destination rectangle for drawing the image
      final rect = Rect.fromCenter(center: position, width: size, height: size);

      // Create a Paint object for drawing
      final paint = Paint();

      // If the direction is left, apply a horizontal flip using scale
      if (isLeft) {
        canvas.save(); // Save the current canvas state
        canvas.scale(-1, 1); // Flip horizontally
        // Offset by the width to ensure correct placement after flipping
        canvas.translate(-rect.center.dx * 2, 0);
        canvas.drawImageRect(img, sourceRect, rect, paint);
        canvas.restore(); // Restore the canvas to its original state
      } else {
        canvas.drawImageRect(img, sourceRect, rect, paint);
      }
    }));
  }

  // Method to update the current frame (you can add logic to change frames for animation)
  void updateFrameRun(int newFrame, bool isLeft) {
    currentFrame = newFrame % 10; // Ensure the frame is within bounds (0-9)
    this.isLeft = isLeft; // Update the direction based on the input
  }

  void updateFrame(int newFrame) {
    currentFrame = newFrame % 10; // Ensure the frame is within bounds (0-9)
  }
}
