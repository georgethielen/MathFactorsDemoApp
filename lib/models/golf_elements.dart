import 'package:flutter/material.dart';

class Wall {
  final Rect rect;
  final Color color;
  
  Wall({required this.rect, this.color = Colors.blueGrey});
}

class DivideBumper {
  final String id;
  final Offset position;
  final double radius;
  final int divideValue;
  bool isUsed = false;
  
  DivideBumper({
    required this.id,
    required this.position,
    required this.radius,
    required this.divideValue,
  });
}

class StaticFactor {
  final String id;
  final Offset position;
  final double radius;
  final int value;
  bool isUsed = false;

  StaticFactor({
    required this.id,
    required this.position,
    required this.radius,
    required this.value,
  });
}
