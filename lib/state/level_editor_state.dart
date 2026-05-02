import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/level_model.dart';
import '../models/golf_elements.dart';
import '../models/level_serialization.dart';

enum EditorTool { select, staticFactor, divideBumper, wall }

/// Represents any selectable element in the editor.
/// We track the type and index so we can modify/delete it.
enum SelectedType { player, wall, staticFactor, divideBumper }

class SelectedElement {
  final SelectedType type;
  final int index; // -1 for player
  SelectedElement(this.type, [this.index = -1]);
}

/// Which part of the element is being dragged
enum DragMode { move, resizeTL, resizeTR, resizeBL, resizeBR }

class LevelEditorState extends ChangeNotifier {
  EditorTool currentTool = EditorTool.select;

  String levelName = 'Custom Level';
  int targetValue = 10;
  int startValue = 2;
  double playerRadius = 20;
  Offset startPosition = const Offset(400, 700);

  List<Wall> walls = [];
  List<DivideBumper> divideBumpers = [];
  List<StaticFactor> staticFactors = [];

  // Wall drawing state (only when wall tool active)
  Offset? wallDragStart;
  Offset? wallDragCurrent;

  // Selection state
  SelectedElement? selection;
  DragMode? dragMode;
  Offset? dragAnchor; // for moves: offset from element center to tap point
  Offset? resizeAnchor; // for resizes: the opposite corner stays fixed

  int elementCounter = 0;

  void setTool(EditorTool tool) {
    if (tool != EditorTool.select) {
      selection = null;
    }
    currentTool = tool;
    notifyListeners();
  }

  void forceUpdate() {
    notifyListeners();
  }

  void loadFromLevel(LevelModel level) {
    levelName = level.name;
    startValue = level.startValue;
    targetValue = level.targetValue;
    startPosition = level.startPosition;
    playerRadius = level.playerRadius ?? 20;
    walls = level.walls.map((w) => Wall(rect: w.rect, color: w.color)).toList();
    divideBumpers = level.divideBumpers.map((b) => DivideBumper(
      id: b.id, position: b.position, radius: b.radius, divideValue: b.divideValue,
    )).toList();
    staticFactors = level.staticFactors.map((f) => StaticFactor(
      id: f.id, position: f.position, radius: f.radius, value: f.value,
    )).toList();
    selection = null;
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────
  // Hit detection helpers
  // ──────────────────────────────────────────────────────────────

  static const double handleSize = 14.0;
  static const double handleHitRadius = 24.0;

  Rect _boundsForSelection(SelectedElement sel) {
    switch (sel.type) {
      case SelectedType.player:
        return Rect.fromCenter(center: startPosition, width: playerRadius * 2, height: playerRadius * 2);
      case SelectedType.wall:
        return walls[sel.index].rect;
      case SelectedType.staticFactor:
        final f = staticFactors[sel.index];
        return Rect.fromCenter(center: f.position, width: f.radius * 2, height: f.radius * 2);
      case SelectedType.divideBumper:
        final b = divideBumpers[sel.index];
        return Rect.fromCenter(center: b.position, width: b.radius * 2, height: b.radius * 2);
    }
  }

  /// Check if pos hits a resize handle of the current selection.
  /// Returns the DragMode if hit, null otherwise.
  DragMode? _hitHandle(Offset pos) {
    if (selection == null) return null;
    final bounds = _boundsForSelection(selection!);
    final corners = {
      DragMode.resizeTL: bounds.topLeft,
      DragMode.resizeTR: bounds.topRight,
      DragMode.resizeBL: bounds.bottomLeft,
      DragMode.resizeBR: bounds.bottomRight,
    };
    for (final entry in corners.entries) {
      if ((pos - entry.value).distance <= handleHitRadius) {
        return entry.key;
      }
    }
    return null;
  }

  /// Find which element (if any) is under pos. Returns SelectedElement or null.
  SelectedElement? _hitTest(Offset pos) {
    // Player
    double pR = playerRadius;
    if ((pos - startPosition).distance <= pR) {
      return SelectedElement(SelectedType.player);
    }
    // Static factors (reverse so topmost wins)
    for (int i = staticFactors.length - 1; i >= 0; i--) {
      if ((pos - staticFactors[i].position).distance <= staticFactors[i].radius) {
        return SelectedElement(SelectedType.staticFactor, i);
      }
    }
    // Divide bumpers
    for (int i = divideBumpers.length - 1; i >= 0; i--) {
      if ((pos - divideBumpers[i].position).distance <= divideBumpers[i].radius) {
        return SelectedElement(SelectedType.divideBumper, i);
      }
    }
    // Walls
    for (int i = walls.length - 1; i >= 0; i--) {
      if (walls[i].rect.contains(pos)) {
        return SelectedElement(SelectedType.wall, i);
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────
  // Pan gestures (unified handler for all tools)
  // ──────────────────────────────────────────────────────────────

  void handlePanStart(Offset pos) {
    if (currentTool == EditorTool.wall) {
      // Don't snap during drag — use raw coordinates for smooth preview
      wallDragStart = pos;
      wallDragCurrent = pos;
      notifyListeners();
      return;
    }

    if (currentTool == EditorTool.select) {
      // First check if we're hitting a resize handle on current selection
      final handle = _hitHandle(pos);
      if (handle != null) {
        dragMode = handle;
        final bounds = _boundsForSelection(selection!);
        // The opposite corner is the anchor
        switch (handle) {
          case DragMode.resizeTL: resizeAnchor = bounds.bottomRight;
          case DragMode.resizeTR: resizeAnchor = bounds.bottomLeft;
          case DragMode.resizeBL: resizeAnchor = bounds.topRight;
          case DragMode.resizeBR: resizeAnchor = bounds.topLeft;
          default: break;
        }
        notifyListeners();
        return;
      }

      // Then check if we're clicking on an element to start a move
      final hit = _hitTest(pos);
      if (hit != null) {
        selection = hit;
        dragMode = DragMode.move;
        // Store offset so element doesn't jump to cursor
        final bounds = _boundsForSelection(hit);
        dragAnchor = pos - bounds.center;
        notifyListeners();
        return;
      }

      // Clicked on nothing — deselect
      selection = null;
      dragMode = null;
      notifyListeners();
    }
  }

  void handlePanUpdate(Offset pos) {
    if (currentTool == EditorTool.wall && wallDragStart != null) {
      wallDragCurrent = pos;
      notifyListeners();
      return;
    }

    if (currentTool == EditorTool.select && selection != null && dragMode != null) {
      if (dragMode == DragMode.move) {
        final newCenter = _snap(pos - (dragAnchor ?? Offset.zero));
        _moveElement(selection!, newCenter);
        notifyListeners();
      } else {
        // Resize
        final snappedPos = _snap(pos);
        _resizeElement(selection!, resizeAnchor!, snappedPos);
        notifyListeners();
      }
    }
  }

  void handlePanEnd() {
    if (currentTool == EditorTool.wall && wallDragStart != null && wallDragCurrent != null) {
      // Snap both corners to grid on commit
      final snappedStart = _snap(wallDragStart!);
      final snappedEnd = _snap(wallDragCurrent!);
      var rect = Rect.fromPoints(snappedStart, snappedEnd);
      // Enforce minimum wall thickness of one grid cell
      if (rect.width < 40) {
        rect = Rect.fromLTRB(rect.left, rect.top, rect.left + 40, rect.bottom);
      }
      if (rect.height < 40) {
        rect = Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + 40);
      }
      walls.add(Wall(rect: rect, color: Colors.blueGrey));
      wallDragStart = null;
      wallDragCurrent = null;
      notifyListeners();
      return;
    }

    dragMode = null;
    dragAnchor = null;
    resizeAnchor = null;
    notifyListeners();
  }

  void handleTap(Offset pos) {
    if (currentTool == EditorTool.select) {
      final hit = _hitTest(pos);
      selection = hit; // null if tapped empty space
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Move & Resize element
  // ──────────────────────────────────────────────────────────────

  void _moveElement(SelectedElement sel, Offset newCenter) {
    switch (sel.type) {
      case SelectedType.player:
        startPosition = newCenter;
      case SelectedType.wall:
        final old = walls[sel.index].rect;
        // Snap the top-left corner to the grid, preserving width/height
        final snappedTopLeft = _snap(Offset(
          newCenter.dx - old.width / 2,
          newCenter.dy - old.height / 2,
        ));
        walls[sel.index] = Wall(
          rect: Rect.fromLTWH(snappedTopLeft.dx, snappedTopLeft.dy, old.width, old.height),
          color: walls[sel.index].color,
        );
      case SelectedType.staticFactor:
        final f = staticFactors[sel.index];
        staticFactors[sel.index] = StaticFactor(id: f.id, position: newCenter, radius: f.radius, value: f.value);
      case SelectedType.divideBumper:
        final b = divideBumpers[sel.index];
        divideBumpers[sel.index] = DivideBumper(id: b.id, position: newCenter, radius: b.radius, divideValue: b.divideValue);
    }
  }

  void _resizeElement(SelectedElement sel, Offset anchor, Offset dragPos) {
    switch (sel.type) {
      case SelectedType.player:
        // Resize player = change radius based on distance from center to drag point
        double dist = (dragPos - startPosition).distance;
        playerRadius = max(15, dist);
      case SelectedType.wall:
        // Snap both points to grid and enforce minimum of one grid cell
        var snappedAnchor = _snap(anchor);
        var snappedDrag = _snap(dragPos);
        var rect = Rect.fromPoints(snappedAnchor, snappedDrag);
        if (rect.width < 40) {
          rect = Rect.fromLTRB(rect.left, rect.top, rect.left + 40, rect.bottom);
        }
        if (rect.height < 40) {
          rect = Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + 40);
        }
        walls[sel.index] = Wall(rect: rect, color: walls[sel.index].color);
      case SelectedType.staticFactor:
        final f = staticFactors[sel.index];
        double dist = (dragPos - f.position).distance;
        staticFactors[sel.index] = StaticFactor(id: f.id, position: f.position, radius: max(15, dist), value: f.value);
      case SelectedType.divideBumper:
        final b = divideBumpers[sel.index];
        double dist = (dragPos - b.position).distance;
        divideBumpers[sel.index] = DivideBumper(id: b.id, position: b.position, radius: max(15, dist), divideValue: b.divideValue);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Delete
  // ──────────────────────────────────────────────────────────────

  void deleteSelected() {
    if (selection == null) return;
    switch (selection!.type) {
      case SelectedType.player:
        // Can't delete the player, just ignore
        return;
      case SelectedType.wall:
        walls.removeAt(selection!.index);
      case SelectedType.staticFactor:
        staticFactors.removeAt(selection!.index);
      case SelectedType.divideBumper:
        divideBumpers.removeAt(selection!.index);
    }
    selection = null;
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────
  // Add elements
  // ──────────────────────────────────────────────────────────────

  void addStaticFactor(Offset pos, int value, double radius) {
    staticFactors.add(StaticFactor(
      id: 'sf_${elementCounter++}',
      position: _snap(pos),
      radius: radius,
      value: value,
    ));
    notifyListeners();
  }

  void addDivideBumper(Offset pos, int value, double radius) {
    divideBumpers.add(DivideBumper(
      id: 'db_${elementCounter++}',
      position: _snap(pos),
      radius: radius,
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

  // ──────────────────────────────────────────────────────────────
  // Build / Export / Save
  // ──────────────────────────────────────────────────────────────

  LevelModel buildLevel() {
    return LevelModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: levelName,
      startValue: startValue,
      targetValue: targetValue,
      startPosition: startPosition,
      playerRadius: playerRadius,
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
    selection = null;
    notifyListeners();
  }
}
