import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class PerlinNoise {
  final List<int> permutation = List.generate(256, (index) => index)..shuffle(Random());

  double noise(double x, double y) {
    int xi = x.floor() & 255;
    int yi = y.floor() & 255;

    double xf = x - x.floor();
    double yf = y - y.floor();

    int aa = permutation[permutation[xi] + yi];
    int ab = permutation[permutation[xi] + yi + 1];
    int ba = permutation[permutation[xi + 1] + yi];
    int bb = permutation[permutation[xi + 1] + yi + 1];

    double u = fade(xf);
    double v = fade(yf);

    double x1 = lerp(grad(aa, xf, yf), grad(ba, xf - 1, yf), u);
    double x2 = lerp(grad(ab, xf, yf - 1), grad(bb, xf - 1, yf - 1), u);

    return lerp(x1, x2, v);
  }

  double fade(double t) => t * t * t * (t * (t * 6 - 15) + 10);
  double lerp(double a, double b, double t) => a + t * (b - a);
  double grad(int hash, double x, double y) {
    int h = hash & 3;
    double u = h < 2 ? x : y;
    double v = h < 2 ? y : x;
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
  }
}
