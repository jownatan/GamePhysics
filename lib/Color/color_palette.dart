import 'package:flutter/material.dart';

class ColorPaletteLocal {
  static const Color text = Color(0xFF0C0B10); // --texto: #0c0b10
  static const Color background = Color(0xFFF4F4F7); // --fundo: #f4f4f7
  static const Color primary = Color(0xFF7E769F); // --primário: #7e769f
  static const Color secondary = Color(0xFFC1B2A6); // --secundário: #c1b2a6
  static const Color accent = Color(0xFFA6AF8C); // --acento: #a6af8c
  static const Color red = Color(0xFFfc6a96); //
}

class ColorPaletteLocalListColor {
  static const List<Color> colors = [
    Color(0xFF0C0B10), // --texto: #0c0b10
    Color(0xFFF4F4F7), // --fundo: #f4f4f7
    Color(0xFF7E769F), // --primário: #7e769f
    Color(0xFFfc6a96),
  ];

  // Optionally, you can create getters for easy access
  static Color get text => colors[0];
  static Color get background => colors[1];
  static Color get primary => colors[2];
  static Color get secondary => colors[3];
  static Color get accent => colors[4];
}
