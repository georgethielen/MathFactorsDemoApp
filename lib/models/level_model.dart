import 'package:flutter/material.dart';
import 'golf_elements.dart';

class LevelModel {
  final String id;
  final String name;
  final int startValue;
  final int targetValue;
  final Offset startPosition;
  final List<Wall> walls;
  final List<DivideBumper> divideBumpers;
  final List<StaticFactor> staticFactors;

  LevelModel({
    required this.id,
    required this.name,
    required this.startValue,
    required this.targetValue,
    required this.startPosition,
    this.walls = const [],
    this.divideBumpers = const [],
    this.staticFactors = const [],
  });
}
