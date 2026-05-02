import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/math_utils.dart';

class CircleModel {
  final String id;
  int value;
  Offset position;
  Offset velocity;
  double radius;
  bool isPrime;
  
  // Track currently displayed factors to allow fading/cycling
  List<int> currentDisplayFactors = [];
  Map<int, double> factorOpacities = {};
  
  CircleModel({
    required this.id,
    required this.value,
    required this.position,
    required this.velocity,
  })  : radius = calculateRadius(value),
        isPrime = MathUtils.isPrime(value);

  void updateValue(int newValue) {
    value = newValue;
    radius = calculateRadius(value);
    isPrime = MathUtils.isPrime(value);
  }

  static double calculateRadius(int val) {
    return max(40.0, 30.0 + sqrt(val) * 3.0); 
  }
}
