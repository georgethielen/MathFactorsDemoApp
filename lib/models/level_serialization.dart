import 'package:flutter/material.dart';
import 'level_model.dart';
import 'golf_elements.dart';

extension RectSerialization on Rect {
  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
      };

  static Rect fromJson(Map<String, dynamic> json) {
    return Rect.fromLTWH(
      (json['left'] as num).toDouble(),
      (json['top'] as num).toDouble(),
      (json['width'] as num).toDouble(),
      (json['height'] as num).toDouble(),
    );
  }
}

extension OffsetSerialization on Offset {
  Map<String, dynamic> toJson() => {
        'dx': dx,
        'dy': dy,
      };

  static Offset fromJson(Map<String, dynamic> json) {
    return Offset((json['dx'] as num).toDouble(), (json['dy'] as num).toDouble());
  }
}

extension LevelModelSerialization on LevelModel {
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startValue': startValue,
        'targetValue': targetValue,
        'startPosition': startPosition.toJson(),
        'walls': walls.map((w) => w.toJson()).toList(),
        'divideBumpers': divideBumpers.map((b) => b.toJson()).toList(),
        'staticFactors': staticFactors.map((f) => f.toJson()).toList(),
      };

  static LevelModel fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] as String,
      name: json['name'] as String,
      startValue: json['startValue'] as int,
      targetValue: json['targetValue'] as int,
      startPosition: OffsetSerialization.fromJson(json['startPosition']),
      walls: (json['walls'] as List?)?.map((w) => WallSerialization.fromJson(w)).toList() ?? [],
      divideBumpers: (json['divideBumpers'] as List?)?.map((b) => DivideBumperSerialization.fromJson(b)).toList() ?? [],
      staticFactors: (json['staticFactors'] as List?)?.map((f) => StaticFactorSerialization.fromJson(f)).toList() ?? [],
    );
  }
}

extension WallSerialization on Wall {
  Map<String, dynamic> toJson() => {
        'rect': rect.toJson(),
        'color': color.value,
      };

  static Wall fromJson(Map<String, dynamic> json) {
    return Wall(
      rect: RectSerialization.fromJson(json['rect']),
      color: Color(json['color'] as int),
    );
  }
}

extension DivideBumperSerialization on DivideBumper {
  Map<String, dynamic> toJson() => {
        'id': id,
        'position': position.toJson(),
        'radius': radius,
        'divideValue': divideValue,
      };

  static DivideBumper fromJson(Map<String, dynamic> json) {
    return DivideBumper(
      id: json['id'] as String,
      position: OffsetSerialization.fromJson(json['position']),
      radius: (json['radius'] as num).toDouble(),
      divideValue: json['divideValue'] as int,
    );
  }
}

extension StaticFactorSerialization on StaticFactor {
  Map<String, dynamic> toJson() => {
        'id': id,
        'position': position.toJson(),
        'radius': radius,
        'value': value,
      };

  static StaticFactor fromJson(Map<String, dynamic> json) {
    return StaticFactor(
      id: json['id'] as String,
      position: OffsetSerialization.fromJson(json['position']),
      radius: (json['radius'] as num).toDouble(),
      value: json['value'] as int,
    );
  }
}
