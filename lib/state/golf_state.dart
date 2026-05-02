import 'dart:math';
import 'package:flutter/material.dart';
import '../models/circle_model.dart';
import '../models/level_model.dart';


class GolfState extends ChangeNotifier {
  LevelModel? currentLevel;
  CircleModel? playerBall;
  
  int strokes = 0;
  bool isCompleted = false;
  bool isFailed = false;
  bool showRetryPrompt = false;

  Size screenSize = const Size(800, 800);

  DateTime? stoppedTime;

  void initialize() {
    screenSize = const Size(800, 800);
  }

  void loadLevel(LevelModel level) {
    currentLevel = level;
    strokes = 0;
    isCompleted = false;
    isFailed = false;
    showRetryPrompt = false;
    stoppedTime = null;

    for (var b in level.divideBumpers) b.isUsed = false;
    for (var f in level.staticFactors) f.isUsed = false;

    playerBall = CircleModel(
      id: 'player_ball',
      value: level.startValue,
      position: level.startPosition,
      velocity: Offset.zero,
    );
    // Use custom radius from editor if set, otherwise keep the formula default
    if (level.playerRadius != null) {
      playerBall!.radius = level.playerRadius!;
    }
    notifyListeners();
  }

  void launchBall(Offset dragDelta) {
    if (isCompleted || playerBall == null) return;
    
    // Drag down to shoot up
    Offset vel = -dragDelta * 12.0; 
    
    if (vel.distance > 2500) {
      vel = (vel / vel.distance) * 2500;
    }
    
    playerBall!.velocity = vel;
    strokes++;
    stoppedTime = null;
    showRetryPrompt = false;
    notifyListeners();
  }

  void tick(double dt) {
    if (playerBall == null || currentLevel == null || isCompleted) return;

    bool changed = false;
    var ball = playerBall!;

    if (ball.velocity.distance > 0.5) {
      ball.position += ball.velocity * dt;
      ball.velocity *= pow(0.95, dt * 60.0).toDouble();
      changed = true;
      stoppedTime = null;
    } else if (ball.velocity.distance > 0) {
      ball.velocity = Offset.zero;
      changed = true;
      stoppedTime = DateTime.now();
    }

    // Screen bounds
    if (ball.position.dx - ball.radius < 0) {
      ball.position = Offset(ball.radius, ball.position.dy);
      ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
    } else if (ball.position.dx + ball.radius > screenSize.width) {
      ball.position = Offset(screenSize.width - ball.radius, ball.position.dy);
      ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
    }
    if (ball.position.dy - ball.radius < 0) {
      ball.position = Offset(ball.position.dx, ball.radius);
      ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy);
    } else if (ball.position.dy + ball.radius > screenSize.height) {
      ball.position = Offset(ball.position.dx, screenSize.height - ball.radius);
      ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy);
    }

    // Walls
    for (var wall in currentLevel!.walls) {
      _handleWallCollision(ball, wall.rect);
    }

    // Divide Bumpers
    for (var bumper in currentLevel!.divideBumpers) {
      if (bumper.isUsed) continue;
      double dist = (ball.position - bumper.position).distance;
      if (dist < ball.radius + bumper.radius) {
        _resolveCircleCollision(ball, bumper.position, bumper.radius);

        if (ball.value % bumper.divideValue == 0) {
          ball.updateValue(ball.value ~/ bumper.divideValue);
          bumper.isUsed = true;
          changed = true;
        }
      }
    }

    // Static Factors
    for (var factor in currentLevel!.staticFactors) {
      if (factor.isUsed) continue;
      double dist = (ball.position - factor.position).distance;
      if (dist < ball.radius + factor.radius) {
        _resolveCircleCollision(ball, factor.position, factor.radius);

        ball.updateValue(ball.value * factor.value);
        factor.isUsed = true;
        changed = true;
      }
    }

    // Completion / Failure
    if (ball.value == currentLevel!.targetValue) {
      isCompleted = true;
      changed = true;
    } else if (ball.velocity.distance == 0) {
      // Only compute impossibility once when ball first stops
      if (_impossibleCached == null) {
        _impossibleCached = _isImpossible();
      }
      if (_impossibleCached == true) {
        if (stoppedTime != null && DateTime.now().difference(stoppedTime!).inSeconds >= 10) {
          if (!showRetryPrompt) {
            showRetryPrompt = true;
            changed = true;
          }
        }
      }
    }

    if (changed) notifyListeners();
  }

  // Cached impossibility result — cleared when ball moves again
  bool? _impossibleCached;

  void _handleWallCollision(CircleModel ball, Rect rect) {
    double testX = ball.position.dx;
    double testY = ball.position.dy;

    if (ball.position.dx < rect.left) testX = rect.left;
    else if (ball.position.dx > rect.right) testX = rect.right;
    if (ball.position.dy < rect.top) testY = rect.top;
    else if (ball.position.dy > rect.bottom) testY = rect.bottom;

    double distX = ball.position.dx - testX;
    double distY = ball.position.dy - testY;
    double distance = sqrt((distX * distX) + (distY * distY));

    if (distance <= ball.radius) {
      double overlap = ball.radius - distance;
      if (distance > 0) {
        ball.position += Offset(distX / distance, distY / distance) * overlap;
      }

      if (testX == rect.left || testX == rect.right) {
        ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
      }
      if (testY == rect.top || testY == rect.bottom) {
        ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy);
      }
    }
  }

  void _resolveCircleCollision(CircleModel ball, Offset otherPos, double otherRadius) {
    Offset diff = ball.position - otherPos;
    double dist = diff.distance;
    if (dist == 0) return;
    
    double overlap = (ball.radius + otherRadius) - dist;
    ball.position += (diff / dist) * overlap;
    
    Offset normal = diff / dist;
    double dot = ball.velocity.dx * normal.dx + ball.velocity.dy * normal.dy;
    ball.velocity -= normal * (2 * dot);
  }

  bool _isImpossible() {
    if (playerBall == null || currentLevel == null) return false;
    List<int> rFactors = currentLevel!.staticFactors.where((f) => !f.isUsed).map((e) => e.value).toList();
    List<int> rDivisors = currentLevel!.divideBumpers.where((f) => !f.isUsed).map((e) => e.divideValue).toList();

    // With too many remaining elements, skip the check — assume still possible
    if (rFactors.length + rDivisors.length > 12) return false;
    
    Set<String> visited = {};
    return !_checkReachable(playerBall!.value, rFactors, rDivisors, currentLevel!.targetValue, visited);
  }

  bool _checkReachable(int currentVal, List<int> remainingFactors, List<int> remainingDivisors, int target, Set<String> visited) {
    if (currentVal == target) return true;
    if (remainingFactors.isEmpty && remainingDivisors.isEmpty) return false;

    // Memoize to avoid recomputing the same state
    String key = '$currentVal|${remainingFactors.join(',')}|${remainingDivisors.join(',')}';
    if (visited.contains(key)) return false;
    visited.add(key);

    for (int i = 0; i < remainingFactors.length; i++) {
      var nextFactors = List<int>.from(remainingFactors)..removeAt(i);
      if (_checkReachable(currentVal * remainingFactors[i], nextFactors, remainingDivisors, target, visited)) return true;
    }
    for (int i = 0; i < remainingDivisors.length; i++) {
      if (currentVal % remainingDivisors[i] == 0) {
        var nextDivisors = List<int>.from(remainingDivisors)..removeAt(i);
        if (_checkReachable(currentVal ~/ remainingDivisors[i], remainingFactors, nextDivisors, target, visited)) return true;
      }
    }
    return false;
  }
}
