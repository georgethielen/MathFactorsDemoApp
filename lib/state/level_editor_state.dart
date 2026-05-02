import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/level_model.dart';
import '../models/golf_elements.dart';
import '../models/level_serialization.dart';

enum EditorTool { player, staticFactor, divideBumper, wall }

class LevelEditorState extends ChangeNotifier {
  EditorTool currentTool = EditorTool.player;

  int targetValue = 10;
  int startValue = 2;
  Offset startPosition = const Offset(400, 700);

  List<Wall> walls = [];
  List<DivideBumper> divideBumpers = [];
  List<StaticFactor> staticFactors = [];

  Offset? dragStart;
  Offset? dragCurrent;

  int elementCounter = 0;

  void setTool(EditorTool tool) {
    currentTool = tool;
    notifyListeners();
  }

  void forceUpdate() {
    notifyListeners();
  }

  void handlePanStart(Offset pos) {
    if (currentTool == EditorTool.wall) {
      dragStart = _snap(pos);
      dragCurrent = dragStart;
      notifyListeners();
    }
  }

  void handlePanUpdate(Offset pos) {
    if (currentTool == EditorTool.wall && dragStart != null) {
      dragCurrent = _snap(pos);
      notifyListeners();
    }
  }

  void handlePanEnd() {
    if (currentTool == EditorTool.wall && dragStart != null && dragCurrent != null) {
      final rect = Rect.fromPoints(dragStart!, dragCurrent!);
      if (rect.width > 0 && rect.height > 0) {
        walls.add(Wall(rect: rect, color: Colors.blueGrey));
      }
      dragStart = null;
      dragCurrent = null;
      notifyListeners();
    }
  }

  void handleTap(Offset pos) {
    pos = _snap(pos);

    if (currentTool == EditorTool.player) {
      startPosition = pos;
      notifyListeners();
    }
  }

  void addStaticFactor(Offset pos, int value) {
    staticFactors.add(StaticFactor(
      id: 'sf_${elementCounter++}',
      position: _snap(pos),
      radius: 40,
      value: value,
    ));
    notifyListeners();
  }

  void addDivideBumper(Offset pos, int value) {
    divideBumpers.add(DivideBumper(
      id: 'db_${elementCounter++}',
      position: _snap(pos),
      radius: 50,
      divideValue: value,
    ));
    notifyListeners();
  }

  Offset _snap(Offset pos) {
    double step = 40.0;
    return Offset(
      (pos.dx / step).round() * step,
      (pos.dy / step).round() * step,
    );
  }

  LevelModel buildLevel() {
    return LevelModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Custom Level',
      startValue: startValue,
      targetValue: targetValue,
      startPosition: startPosition,
      walls: List.from(walls),
      divideBumpers: List.from(divideBumpers),
      staticFactors: List.from(staticFactors),
    );
  }

  String exportJson() {
    final level = buildLevel();
    return jsonEncode(level.toJson());
  }

  Future<void> saveLocal() async {
    try {
      final level = buildLevel();
      final file = File('custom_levels.json');
      List<dynamic> existing = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          existing = jsonDecode(content);
        }
      }
      existing.add(level.toJson());
      await file.writeAsString(jsonEncode(existing));
    } catch (e) {
      debugPrint("Save failed: $e");
    }
  }

  void clear() {
    walls.clear();
    divideBumpers.clear();
    staticFactors.clear();
    notifyListeners();
  }
}
