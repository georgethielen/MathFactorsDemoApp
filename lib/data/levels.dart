import 'package:flutter/material.dart';
import '../models/level_model.dart';
import '../models/golf_elements.dart';

class Levels {
  static List<LevelModel> getAllLevels() {
    double cx = 400;
    double cy = 400;

    return [
      LevelModel(
        id: '1',
        name: 'Level 1: The Multiplier',
        startValue: 5,
        targetValue: 15,
        startPosition: Offset(cx, cy + 200),
        staticFactors: [
          StaticFactor(id: 'sf_1', position: Offset(cx, cy - 200), radius: 40, value: 3), // correct
          StaticFactor(id: 'sf_1b', position: Offset(cx - 120, cy - 50), radius: 40, value: 2), // trap
          StaticFactor(id: 'sf_1c', position: Offset(cx + 120, cy - 50), radius: 40, value: 4), // trap
        ],
      ),
      LevelModel(
        id: '2',
        name: 'Level 2: The Divider',
        startValue: 30,
        targetValue: 6,
        startPosition: Offset(cx, cy + 250),
        divideBumpers: [
          DivideBumper(id: 'db_1', position: Offset(cx, cy - 100), radius: 50, divideValue: 5), // correct
          DivideBumper(id: 'db_2', position: Offset(cx - 120, cy + 50), radius: 40, divideValue: 2), // alternate route part 1
          DivideBumper(id: 'db_3', position: Offset(cx + 120, cy - 200), radius: 40, divideValue: 3), // alternate route part 2
          DivideBumper(id: 'db_4', position: Offset(cx - 120, cy - 200), radius: 40, divideValue: 10), // trap
        ],
      ),
      LevelModel(
        id: '3',
        name: 'Level 3: Around the Corner',
        startValue: 7,
        targetValue: 14,
        startPosition: Offset(cx - 150, cy + 200),
        walls: [
          Wall(rect: Rect.fromCenter(center: Offset(cx, cy), width: 300, height: 40), color: Colors.blueGrey)
        ],
        staticFactors: [
          StaticFactor(id: 'sf_3a', position: Offset(cx + 150, cy - 200), radius: 40, value: 2), // correct
          StaticFactor(id: 'sf_3b', position: Offset(cx - 150, cy - 200), radius: 40, value: 3), // trap
        ],
        divideBumpers: [
          DivideBumper(id: 'db_3a', position: Offset(cx + 150, cy + 100), radius: 40, divideValue: 7), // trap
        ]
      ),
    ];
  }
}
